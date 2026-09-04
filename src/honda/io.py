"""Text loaders for the beamline formats handled by the Igor procedures."""

from __future__ import annotations

import re
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from types import MappingProxyType
from typing import Any, Literal

import numpy as np
from numpy.typing import ArrayLike

from ._arrays import FloatArray
from .corrections import binding_energy
from .magnetism import DichroismResult, HysteresisResult, hysteresis, xmcd


@dataclass(frozen=True, slots=True)
class TableData:
    """Named numeric columns loaded from one text file."""

    source: Path
    columns: Mapping[str, FloatArray]
    metadata: Mapping[str, Any] = field(default_factory=dict)

    def __getitem__(self, name: str) -> FloatArray:
        return self.columns[name]


@dataclass(frozen=True, slots=True)
class APEDichroismData:
    source: Path
    energy: FloatArray
    result: DichroismResult


@dataclass(frozen=True, slots=True)
class APEHysteresisData:
    source: Path
    field: FloatArray
    helicity: Literal["L", "R"]
    result: HysteresisResult


def _immutable_mapping(values: dict[str, Any]) -> Mapping[str, Any]:
    return MappingProxyType(values)


def _detect_header_lines(
    source: Path,
    *,
    delimiter: str | None,
    comments: str | None,
    usecols: Sequence[int] | None,
) -> int:
    """Return the number of lines before the first fully numeric data row."""
    lines = source.read_text(encoding="latin-1", errors="replace").splitlines()
    for line_number, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or (comments is not None and stripped.startswith(comments)):
            continue
        tokens = stripped.split() if delimiter is None else stripped.split(delimiter)
        tokens = [token.strip() for token in tokens if token.strip()]
        selected = (
            tokens
            if usecols is None
            else [tokens[index] for index in usecols if index < len(tokens)]
        )
        if usecols is not None and len(selected) != len(usecols):
            continue
        try:
            for token in selected:
                float(token)
        except ValueError:
            continue
        if selected:
            return line_number
    raise ValueError(f"no numeric data rows found in {source}")


def load_text_table(
    path: str | Path,
    *,
    names: Sequence[str] | None = None,
    usecols: Sequence[int] | None = None,
    delimiter: str | None = None,
    skip_header: int | None = None,
    comments: str | None = "#",
) -> TableData:
    """Load numeric columns from a whitespace- or delimiter-separated file.

    Non-numeric values become ``NaN``, mirroring ``CheckWaveValidity`` in the
    BEAR loader.  Header rows with inconsistent column counts are ignored by
    NumPy's text reader.
    """
    source = Path(path).expanduser().resolve()
    if not source.is_file():
        raise FileNotFoundError(source)
    if skip_header is None:
        skip_header = _detect_header_lines(
            source,
            delimiter=delimiter,
            comments=comments,
            usecols=usecols,
        )
    if skip_header < 0:
        raise ValueError("skip_header must be non-negative")
    data = np.genfromtxt(
        source,
        delimiter=delimiter,
        comments=comments,
        skip_header=skip_header,
        usecols=usecols,
        dtype=float,
        invalid_raise=False,
        ndmin=2,
        autostrip=True,
    )
    if data.size == 0 or data.shape[1] == 0:
        raise ValueError(f"no numeric columns found in {source}")
    if names is None:
        column_names = tuple(f"column_{index}" for index in range(data.shape[1]))
    else:
        column_names = tuple(names)
        if len(column_names) != data.shape[1]:
            raise ValueError(
                f"received {len(column_names)} names for {data.shape[1]} loaded columns"
            )
        if len(set(column_names)) != len(column_names):
            raise ValueError("column names must be unique")
    columns = {
        name: np.asarray(data[:, index], dtype=float) for index, name in enumerate(column_names)
    }
    return TableData(source, _immutable_mapping(columns))


_SCAN_TIME_PATTERN = re.compile(
    r"Scan (?P<position>beginning|end):\s*"
    r"(?P<day>\d{1,2})/(?P<month>\d{1,2})/(?P<year>\d{2,4})\s+"
    r"(?P<hour>\d{1,2})[.:](?P<minute>\d{1,2})[.:](?P<second>\d{1,2})",
    re.IGNORECASE,
)
_RING_CURRENT_PATTERN = re.compile(r"Ring current \(mA\):\s*([-+\d.eE]+)", re.IGNORECASE)


def _bear_metadata(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="latin-1", errors="replace")
    metadata: dict[str, Any] = {}
    for match in _SCAN_TIME_PATTERN.finditer(text):
        year = int(match["year"])
        if year < 100:
            year += 2000
        metadata[f"scan_{match['position']}"] = datetime(
            year,
            int(match["month"]),
            int(match["day"]),
            int(match["hour"]),
            int(match["minute"]),
            int(match["second"]),
        )
    currents = [float(value) for value in _RING_CURRENT_PATTERN.findall(text)]
    if currents:
        metadata["ring_current_ma"] = float(np.mean(currents[:2]))
    if "scan_beginning" in metadata and "scan_end" in metadata:
        metadata["scan_duration_seconds"] = (
            metadata["scan_end"] - metadata["scan_beginning"]
        ).total_seconds()
    return metadata


def load_bear(
    path: str | Path,
    *,
    names: Sequence[str] | None = None,
    delimiter: str | None = None,
    skip_header: int | None = None,
) -> TableData:
    """Load up to seven BEAR columns and parse ring-current metadata."""
    source = Path(path).expanduser().resolve()
    table = load_text_table(
        source,
        names=names,
        delimiter=delimiter,
        skip_header=skip_header,
    )
    if len(table.columns) > 7:
        raise ValueError("BEAR files are expected to contain at most seven columns")
    return TableData(table.source, table.columns, _immutable_mapping(_bear_metadata(source)))


def dark_statistics(data: TableData) -> Mapping[str, tuple[float, float]]:
    """Return each column's NaN-aware mean and sample standard deviation."""
    return _immutable_mapping(
        {
            name: (float(np.nanmean(values)), float(np.nanstd(values, ddof=1)))
            for name, values in data.columns.items()
        }
    )


def resample_columns(
    data: TableData,
    *,
    reference: str,
    columns: Sequence[str] | None = None,
) -> TableData:
    """Interpolate selected columns onto a uniform grid spanning a reference column."""
    x = data[reference]
    if not np.all(np.isfinite(x)):
        raise ValueError("the reference column must contain only finite values")
    selected = (
        tuple(columns)
        if columns is not None
        else tuple(name for name in data.columns if name != reference)
    )
    grid = np.linspace(float(x[0]), float(x[-1]), x.size)
    output = dict(data.columns)
    output[reference] = grid
    for name in selected:
        values = data[name]
        valid = np.isfinite(x) & np.isfinite(values)
        if np.count_nonzero(valid) < 2:
            raise ValueError(f"column {name!r} has fewer than two finite samples")
        order = np.argsort(x[valid])
        output[name] = np.interp(grid, x[valid][order], values[valid][order])
    return TableData(data.source, _immutable_mapping(output), data.metadata)


def load_xps_g6(
    path: str | Path,
    *,
    kinetic_name: str = "kinetic_energy",
    intensity_name: str = "intensity",
    photon_energy: float | None = None,
    work_function: float = 0.0,
    sample_bias: float = 0.0,
) -> TableData:
    """Load a two-column G6 XPS file, optionally adding binding energy."""
    table = load_text_table(path, names=(kinetic_name, intensity_name), usecols=(0, 1))
    columns = dict(table.columns)
    if photon_energy is not None:
        columns["binding_energy"] = binding_energy(
            columns[kinetic_name],
            photon_energy=photon_energy,
            work_function=work_function,
            sample_bias=sample_bias,
        )
    return TableData(table.source, _immutable_mapping(columns), table.metadata)


def _load_matrix(path: str | Path) -> tuple[Path, FloatArray]:
    source = Path(path).expanduser().resolve()
    if not source.is_file():
        raise FileNotFoundError(source)
    skip_header = _detect_header_lines(
        source,
        delimiter=None,
        comments="#",
        usecols=None,
    )
    matrix = np.genfromtxt(
        source,
        dtype=float,
        invalid_raise=False,
        ndmin=2,
        skip_header=skip_header,
    )
    if matrix.size == 0:
        raise ValueError(f"no numeric data found in {source}")
    return source, np.asarray(matrix, dtype=float)


def load_ape_dichroism(path: str | Path) -> APEDichroismData:
    """Load repeated 12-column APE every-point XMCD scan blocks."""
    source, matrix = _load_matrix(path)
    if matrix.shape[1] % 12:
        raise ValueError("APE dichroism data must contain one or more 12-column scan blocks")
    blocks = matrix.reshape(matrix.shape[0], -1, 12).transpose(1, 0, 2)
    energies = blocks[:, :, 0]
    if not np.allclose(energies, energies[0], equal_nan=True):
        raise ValueError("APE dichroism scans have different energy axes")
    return APEDichroismData(source, energies[0], xmcd(blocks[:, :, 10], blocks[:, :, 11]))


def load_ape_hysteresis(
    path: str | Path,
    *,
    helicity: Literal["L", "R"],
) -> APEHysteresisData:
    """Load repeated 9-column APE hysteresis scan blocks."""
    if helicity not in {"L", "R"}:
        raise ValueError("helicity must be 'L' or 'R'")
    source, matrix = _load_matrix(path)
    if matrix.shape[1] % 9:
        raise ValueError("APE hysteresis data must contain one or more 9-column scan blocks")
    blocks = matrix.reshape(matrix.shape[0], -1, 9).transpose(1, 0, 2)
    fields = blocks[:, :, 0]
    if not np.allclose(fields, fields[0], equal_nan=True):
        raise ValueError("APE hysteresis scans have different field axes")
    result = hysteresis(
        blocks[:, :, 1],
        blocks[:, :, 2],
        blocks[:, :, 3],
        blocks[:, :, 4],
    )
    return APEHysteresisData(source, fields[0], helicity, result)


def load_bl7_hysteresis(
    pre_edge_path: str | Path,
    edge_path: str | Path,
) -> tuple[FloatArray, HysteresisResult]:
    """Load paired BL7A files and calculate pointwise hysteresis.

    Each file uses ``field, monitor, signal`` as its first three columns.
    Field-cycle splitting is available separately through
    :func:`honda.magnetism.average_field_cycles`.
    """
    pre = load_text_table(
        pre_edge_path,
        names=("field", "monitor", "signal"),
        usecols=(0, 1, 2),
    )
    edge = load_text_table(
        edge_path,
        names=("field", "monitor", "signal"),
        usecols=(0, 1, 2),
    )
    if not np.allclose(pre["field"], edge["field"], equal_nan=True):
        raise ValueError("pre-edge and edge field axes do not match")
    result = hysteresis(
        edge["signal"],
        edge["monitor"],
        pre["signal"],
        pre["monitor"],
    )
    return edge["field"], result


def table_from_arrays(
    columns: Mapping[str, ArrayLike],
    *,
    source: str | Path = ".",
) -> TableData:
    """Build a :class:`TableData` object from existing arrays."""
    converted = {name: np.asarray(values, dtype=float) for name, values in columns.items()}
    lengths = {value.size for value in converted.values() if value.ndim == 1}
    if not converted or len(lengths) != 1 or any(value.ndim != 1 for value in converted.values()):
        raise ValueError("columns must be non-empty, one-dimensional, and equally sized")
    return TableData(Path(source).expanduser().resolve(), _immutable_mapping(converted))

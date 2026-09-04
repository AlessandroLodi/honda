"""XMCD and hysteresis calculations for the APE and BL7A loaders."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

import numpy as np
from numpy.typing import ArrayLike

from ._arrays import FloatArray, as_float_array


@dataclass(frozen=True, slots=True)
class DichroismResult:
    """Averaged signals and the resulting dichroism curves."""

    plus: FloatArray
    minus: FloatArray
    difference: FloatArray
    asymmetry: FloatArray


@dataclass(frozen=True, slots=True)
class HysteresisResult:
    """Normalized edge/pre-edge signals and a hysteresis curve."""

    edge_normalized: FloatArray
    pre_edge_normalized: FloatArray
    hysteresis: FloatArray


def _average_scans(scans: ArrayLike | Sequence[ArrayLike], *, name: str) -> FloatArray:
    values = np.asarray(scans, dtype=float)
    if values.ndim == 1:
        values = values[None, :]
    if values.ndim != 2 or values.shape[1] == 0:
        raise ValueError(f"{name} must be one scan or a rectangular collection of scans")
    if not np.all(np.isfinite(values)):
        raise ValueError(f"{name} must contain only finite values")
    return np.mean(values, axis=0)


def xmcd(
    plus: ArrayLike | Sequence[ArrayLike],
    minus: ArrayLike | Sequence[ArrayLike],
) -> DichroismResult:
    """Average repeated helicity scans and calculate XMCD difference/asymmetry."""
    plus_average = _average_scans(plus, name="plus")
    minus_average = _average_scans(minus, name="minus")
    if plus_average.shape != minus_average.shape:
        raise ValueError("plus and minus scans must have matching lengths")
    difference = plus_average - minus_average
    with np.errstate(divide="ignore", invalid="ignore"):
        asymmetry = difference / (plus_average + minus_average)
    return DichroismResult(plus_average, minus_average, difference, asymmetry)


def hysteresis(
    edge_signal: ArrayLike | Sequence[ArrayLike],
    edge_monitor: ArrayLike | Sequence[ArrayLike],
    pre_edge_signal: ArrayLike | Sequence[ArrayLike],
    pre_edge_monitor: ArrayLike | Sequence[ArrayLike],
) -> HysteresisResult:
    """Calculate ``((Is/Im)_edge - (Is/Im)_pre) / (Is/Im)_pre``."""
    edge_signal_average = _average_scans(edge_signal, name="edge_signal")
    edge_monitor_average = _average_scans(edge_monitor, name="edge_monitor")
    pre_signal_average = _average_scans(pre_edge_signal, name="pre_edge_signal")
    pre_monitor_average = _average_scans(pre_edge_monitor, name="pre_edge_monitor")
    shapes = {
        array.shape
        for array in (
            edge_signal_average,
            edge_monitor_average,
            pre_signal_average,
            pre_monitor_average,
        )
    }
    if len(shapes) != 1:
        raise ValueError("all signal and monitor scans must have matching lengths")
    with np.errstate(divide="ignore", invalid="ignore"):
        edge_normalized = edge_signal_average / edge_monitor_average
        pre_normalized = pre_signal_average / pre_monitor_average
        result = (edge_normalized - pre_normalized) / pre_normalized
    return HysteresisResult(edge_normalized, pre_normalized, result)


def split_field_cycles(
    field: ArrayLike,
    *signals: ArrayLike,
    tolerance: float | None = None,
) -> tuple[tuple[FloatArray, ...], ...]:
    """Split repeated field sweeps at successive occurrences of maximum field.

    Each returned cycle contains the field followed by the corresponding signal
    slices.  A final incomplete cycle is ignored, matching the BL7A procedure.
    """
    field_values = as_float_array(field, name="field", min_size=3)
    signal_values = tuple(as_float_array(value, name="signal", min_size=3) for value in signals)
    if any(value.shape != field_values.shape for value in signal_values):
        raise ValueError("all signals must have the same shape as field")
    maximum = np.max(field_values)
    absolute_tolerance = (
        max(np.finfo(float).eps * max(1.0, abs(maximum)) * 8.0, 0.0)
        if tolerance is None
        else tolerance
    )
    if absolute_tolerance < 0:
        raise ValueError("tolerance must be non-negative")
    boundaries = np.flatnonzero(
        np.isclose(field_values, maximum, atol=absolute_tolerance, rtol=0.0)
    )
    if boundaries.size < 2:
        raise ValueError("field must reach its maximum at least twice")
    cycles: list[tuple[FloatArray, ...]] = []
    for first, end in zip(boundaries[:-1], boundaries[1:], strict=True):
        if end > first:
            cycles.append(
                (field_values[first:end],) + tuple(values[first:end] for values in signal_values)
            )
    if not cycles:
        raise ValueError("no complete field cycle was found")
    lengths = {cycle[0].size for cycle in cycles}
    if len(lengths) != 1:
        raise ValueError("field cycles have unequal lengths and cannot be averaged")
    return tuple(cycles)


def average_field_cycles(
    field: ArrayLike,
    *signals: ArrayLike,
    tolerance: float | None = None,
) -> tuple[FloatArray, ...]:
    """Split and average repeated field cycles."""
    cycles = split_field_cycles(field, *signals, tolerance=tolerance)
    stacked = tuple(np.stack([cycle[index] for cycle in cycles]) for index in range(len(cycles[0])))
    return tuple(np.mean(values, axis=0) for values in stacked)

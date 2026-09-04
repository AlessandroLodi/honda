from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from honda.io import (
    dark_statistics,
    load_ape_dichroism,
    load_ape_hysteresis,
    load_bear,
    load_xps_g6,
)


def test_load_xps_adds_binding_energy(tmp_path: Path) -> None:
    path = tmp_path / "xps.txt"
    path.write_text("energy intensity\n10 100\n11 120\n", encoding="utf-8")
    data = load_xps_g6(path, photon_energy=21.2, work_function=4.5)
    np.testing.assert_allclose(data["kinetic_energy"], [10.0, 11.0])
    np.testing.assert_allclose(data["binding_energy"], [6.7, 5.7])


def test_load_bear_parses_ring_current_and_dark_statistics(tmp_path: Path) -> None:
    path = tmp_path / "bear.txt"
    path.write_text(
        "BEAR scan\n"
        "Scan beginning: 04/09/2026\t10.00.00\n"
        "Ring current (mA): 300\n"
        "Scan end: 04/09/2026\t10.01.30\n"
        "Ring current (mA): 280\n"
        "1 2\n3 4\n",
        encoding="utf-8",
    )
    data = load_bear(path, names=("energy", "signal"))
    assert data.metadata["ring_current_ma"] == pytest.approx(290.0)
    assert data.metadata["scan_duration_seconds"] == 90.0
    assert dark_statistics(data)["signal"] == pytest.approx((3.0, np.sqrt(2.0)))


def test_load_ape_dichroism_reads_repeated_blocks(tmp_path: Path) -> None:
    block_one = np.zeros((2, 12))
    block_two = np.zeros((2, 12))
    block_one[:, 0] = block_two[:, 0] = [1.0, 2.0]
    block_one[:, 10:12] = [[6.0, 2.0], [8.0, 4.0]]
    block_two[:, 10:12] = [[4.0, 2.0], [6.0, 4.0]]
    path = tmp_path / "ape-dich.txt"
    np.savetxt(path, np.hstack((block_one, block_two)))
    loaded = load_ape_dichroism(path)
    np.testing.assert_allclose(loaded.result.plus, [5.0, 7.0])
    np.testing.assert_allclose(loaded.result.minus, [2.0, 4.0])


def test_load_ape_hysteresis_reads_repeated_blocks(tmp_path: Path) -> None:
    block = np.zeros((2, 9))
    block[:, 0] = [-1.0, 1.0]
    block[:, 1] = [6.0, 8.0]
    block[:, 2] = 2.0
    block[:, 3] = 4.0
    block[:, 4] = 2.0
    path = tmp_path / "ape-hyst.txt"
    np.savetxt(path, block)
    loaded = load_ape_hysteresis(path, helicity="L")
    np.testing.assert_allclose(loaded.result.hysteresis, [0.5, 1.0])

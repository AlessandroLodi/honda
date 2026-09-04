from __future__ import annotations

import numpy as np

from honda.magnetism import average_field_cycles, hysteresis, xmcd


def test_xmcd_averages_scans() -> None:
    result = xmcd([[4.0, 6.0], [6.0, 8.0]], [[2.0, 4.0], [4.0, 6.0]])
    np.testing.assert_allclose(result.plus, [5.0, 7.0])
    np.testing.assert_allclose(result.minus, [3.0, 5.0])
    np.testing.assert_allclose(result.difference, [2.0, 2.0])
    np.testing.assert_allclose(result.asymmetry, [0.25, 1.0 / 6.0])


def test_hysteresis_formula() -> None:
    result = hysteresis([6.0, 8.0], [2.0, 2.0], [4.0, 4.0], [2.0, 2.0])
    np.testing.assert_allclose(result.hysteresis, [0.5, 1.0])


def test_average_field_cycles_splits_at_maximum() -> None:
    field = np.array([2.0, 1.0, 0.0, 1.0, 2.0, 1.0, 0.0, 1.0, 2.0])
    signal = np.arange(field.size, dtype=float)
    averaged_field, averaged_signal = average_field_cycles(field, signal)
    np.testing.assert_array_equal(averaged_field, [2.0, 1.0, 0.0, 1.0])
    np.testing.assert_array_equal(averaged_signal, [2.0, 3.0, 4.0, 5.0])

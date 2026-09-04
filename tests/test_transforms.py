from __future__ import annotations

import numpy as np

from honda.transforms import (
    extend_parity,
    hilbert_transform,
    kramers_kronig_imag_to_real,
)


def test_extend_parity_avoids_duplicate_zero() -> None:
    x, y = extend_parity([0.0, 1.0, 2.0], [0.0, 3.0, 4.0], parity="odd")
    np.testing.assert_array_equal(x, [-2.0, -1.0, 0.0, 1.0, 2.0])
    np.testing.assert_array_equal(y, [-4.0, -3.0, 0.0, 3.0, 4.0])


def test_hilbert_transform_of_cosine_is_sine() -> None:
    x = np.linspace(-np.pi, np.pi, 1_000, endpoint=False)
    y = np.cos(3.0 * x)
    transformed = hilbert_transform(x, y, interpolation_step=x[1] - x[0])
    np.testing.assert_allclose(transformed[20:-20], np.sin(3.0 * x[20:-20]), atol=4e-2)


def test_kramers_kronig_matches_direct_discrete_sum() -> None:
    omega = np.linspace(0.2, 3.0, 40)
    imaginary = omega / (1.0 + omega**2)
    expected = np.empty_like(omega)
    for index, frequency in enumerate(omega):
        denominator = omega**2 - frequency**2
        denominator[index] = np.inf
        expected[index] = (
            2.0 / np.pi * (omega[1] - omega[0]) * np.sum(imaginary * omega / denominator)
        )
    result = kramers_kronig_imag_to_real(omega, imaginary, block_size=7)
    np.testing.assert_allclose(result, expected)

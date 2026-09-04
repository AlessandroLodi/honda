"""Hilbert and Kramers-Kronig transforms."""

from __future__ import annotations

from typing import Literal

import numpy as np
from numpy.typing import ArrayLike
from scipy.interpolate import CubicSpline
from scipy.signal import hilbert

from ._arrays import FloatArray, as_matching_arrays


def extend_parity(
    x: ArrayLike,
    y: ArrayLike,
    *,
    parity: Literal["odd", "even"],
) -> tuple[FloatArray, FloatArray]:
    """Mirror one-sided data into an odd or even function."""
    x_values, y_values = as_matching_arrays(x, y)
    if not (np.all(x_values >= 0) or np.all(x_values <= 0)):
        raise ValueError("x must lie entirely on one side of zero")
    if parity not in {"odd", "even"}:
        raise ValueError("parity must be 'odd' or 'even'")

    mirrored_x = -x_values
    mirrored_y = -y_values if parity == "odd" else y_values.copy()
    if np.any(x_values == 0):
        mirrored_x = mirrored_x[x_values != 0]
        mirrored_y = mirrored_y[x_values != 0]
    combined_x = np.concatenate((mirrored_x, x_values))
    combined_y = np.concatenate((mirrored_y, y_values))
    order = np.argsort(combined_x)
    return combined_x[order], combined_y[order]


def hilbert_transform(
    x: ArrayLike,
    y: ArrayLike,
    *,
    interpolation_step: float | None = None,
) -> FloatArray:
    """Hilbert-transform sampled data after interpolation to a uniform grid."""
    x_values, y_values = as_matching_arrays(x, y, min_size=4)
    order = np.argsort(x_values)
    sorted_x = x_values[order]
    sorted_y = y_values[order]
    if np.any(np.diff(sorted_x) <= 0):
        raise ValueError("x values must be unique")

    if interpolation_step is None:
        interpolation_step = float(np.min(np.diff(sorted_x)))
    if interpolation_step <= 0:
        raise ValueError("interpolation_step must be positive")
    span = sorted_x[-1] - sorted_x[0]
    point_count = max(4, int(2 * np.ceil(span / interpolation_step / 2)))
    uniform_x = np.linspace(sorted_x[0], sorted_x[-1], point_count)
    uniform_y = np.interp(uniform_x, sorted_x, sorted_y)
    transformed = np.imag(hilbert(uniform_y))
    sampled = CubicSpline(uniform_x, transformed)(sorted_x)
    result = np.empty_like(sampled)
    result[order] = sampled
    return result


def parity_hilbert_transform(
    x: ArrayLike,
    y: ArrayLike,
    *,
    parity: Literal["odd", "even"],
    interpolation_step: float | None = None,
    multiplier: float = 1.0,
) -> FloatArray:
    """Extend one-sided data by parity and return its transform at the input x."""
    x_values, y_values = as_matching_arrays(x, y, min_size=4)
    extended_x, extended_y = extend_parity(x_values, y_values, parity=parity)
    transformed = hilbert_transform(extended_x, extended_y, interpolation_step=interpolation_step)
    return np.asarray(multiplier * np.interp(x_values, extended_x, transformed))


def kramers_kronig_imag_to_real(
    omega: ArrayLike,
    imaginary: ArrayLike,
    *,
    alpha: int = 0,
    block_size: int = 256,
) -> FloatArray:
    """Estimate the real susceptibility from its imaginary part.

    This is the principal-value discrete relation implemented in
    ``kkimg2real.ipf``.  Unlike that procedure, the requested ``alpha`` is not
    overwritten with zero and every non-singular sample is included.
    """
    frequencies, values = as_matching_arrays(omega, imaginary, min_size=3)
    if alpha < 0 or int(alpha) != alpha:
        raise ValueError("alpha must be a non-negative integer")
    if block_size < 1:
        raise ValueError("block_size must be positive")
    spacing = np.diff(frequencies)
    if spacing[0] <= 0 or not np.allclose(spacing, spacing[0], rtol=1e-7, atol=1e-12):
        raise ValueError("omega must be strictly increasing and equally spaced")
    if np.any(frequencies < 0):
        raise ValueError("omega must be non-negative")
    if alpha and np.any(frequencies == 0):
        raise ValueError("omega must be nonzero when alpha is positive")

    numerator = values * frequencies ** (2 * alpha + 1)
    squared = frequencies**2
    result = np.empty_like(frequencies)
    for first in range(0, frequencies.size, block_size):
        end = min(first + block_size, frequencies.size)
        denominator = squared[None, :] - squared[first:end, None]
        local_rows = np.arange(end - first)
        denominator[local_rows, np.arange(first, end)] = np.inf
        principal_value = np.sum(numerator[None, :] / denominator, axis=1)
        scale = np.ones(end - first) if alpha == 0 else frequencies[first:end] ** (-2 * alpha)
        result[first:end] = 2.0 / np.pi * spacing[0] * principal_value * scale
    return result

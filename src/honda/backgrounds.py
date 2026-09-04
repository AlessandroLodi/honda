"""Background estimators for photoemission and absorption spectra."""

from __future__ import annotations

import warnings
from collections.abc import Sequence

import numpy as np
from numpy.typing import ArrayLike
from scipy.integrate import cumulative_trapezoid
from scipy.optimize import OptimizeWarning, curve_fit

from ._arrays import FloatArray, as_matching_arrays, normalize_indices
from .models import hill_equation


def _region(size: int, start: int, stop: int | None) -> tuple[int, int]:
    end = size if stop is None else stop
    if start < 0 or end > size or start >= end:
        raise ValueError("the selected region must satisfy 0 <= start < stop <= len(x)")
    return start, end


def linear_background(
    x: ArrayLike,
    intensity: ArrayLike,
    *,
    start: int = 0,
    stop: int | None = None,
) -> FloatArray:
    """Return a line through the endpoint intensities of a selected region.

    ``stop`` follows normal Python slicing and is therefore exclusive.  The
    returned line is evaluated over the complete x array.
    """
    x_values, y_values = as_matching_arrays(x, intensity)
    first, end = _region(x_values.size, start, stop)
    last = end - 1
    if x_values[first] == x_values[last]:
        raise ValueError("background endpoints must have different x values")
    slope = (y_values[last] - y_values[first]) / (x_values[last] - x_values[first])
    return np.asarray(y_values[first] + slope * (x_values - x_values[first]))


def shirley_background(
    x: ArrayLike,
    intensity: ArrayLike,
    *,
    start: int = 0,
    stop: int | None = None,
    tolerance: float = 1e-8,
    max_iterations: int = 200,
) -> FloatArray:
    """Calculate an iterative Shirley background on a selected region.

    Values outside the region are held at the nearest endpoint background.
    The method supports ascending or descending monotonic energy axes.
    """
    x_values, y_values = as_matching_arrays(x, intensity, min_size=3)
    first, end = _region(x_values.size, start, stop)
    region_x = x_values[first:end]
    region_y = y_values[first:end]
    differences = np.diff(region_x)
    if not (np.all(differences > 0) or np.all(differences < 0)):
        raise ValueError("x must be strictly monotonic within the selected region")
    if tolerance <= 0 or max_iterations < 1:
        raise ValueError("tolerance and max_iterations must be positive")

    if differences[0] < 0:
        work_x = region_x[::-1]
        work_y = region_y[::-1]
        reversed_axis = True
    else:
        work_x = region_x
        work_y = region_y
        reversed_axis = False

    left, right = float(work_y[0]), float(work_y[-1])
    background = np.linspace(left, right, work_y.size)
    for _ in range(max_iterations):
        signal = work_y - background
        integral_from_right = -cumulative_trapezoid(signal[::-1], work_x[::-1], initial=0.0)[::-1]
        total = integral_from_right[0]
        if np.isclose(total, 0.0):
            updated = np.linspace(left, right, work_y.size)
        else:
            updated = right + (left - right) * integral_from_right / total
        if np.max(np.abs(updated - background)) <= tolerance * max(1.0, np.max(np.abs(background))):
            background = updated
            break
        background = updated
    else:
        raise RuntimeError("Shirley background did not converge")

    if reversed_axis:
        background = background[::-1]
    result = np.empty_like(y_values)
    result[:first] = background[0]
    result[first:end] = background
    result[end:] = background[-1]
    return result


def tougaard_background(
    intensity: ArrayLike,
    *,
    start: int = 0,
    stop: int | None = None,
    kernel_scale: float = 1643.0,
) -> FloatArray:
    """Reproduce the discrete Tougaard-like background in the Igor source.

    The legacy routine uses point separation, rather than physical energy, in
    ``d / (kernel_scale + d**2)**2`` and normalizes the curve to the selected
    endpoint intensities.  This implementation preserves that convention.
    """
    values = np.asarray(intensity, dtype=float)
    if values.ndim != 1 or values.size < 2 or not np.all(np.isfinite(values)):
        raise ValueError("intensity must be a finite one-dimensional array")
    if kernel_scale <= 0:
        raise ValueError("kernel_scale must be positive")
    first, end = _region(values.size, start, stop)
    selected = values[first:end]
    offset = selected[-1]
    signal = selected - offset
    integrated = np.zeros_like(selected)
    for index in range(selected.size):
        distance = np.arange(selected.size - index, dtype=float)
        kernel = distance / (kernel_scale + distance**2) ** 2
        integrated[index] = signal[index:] @ kernel
    if np.isclose(integrated[0], 0.0):
        background = np.linspace(selected[0], selected[-1], selected.size)
    else:
        background = offset + integrated / integrated[0] * (selected[0] - offset)

    result = np.empty_like(values)
    result[:first] = background[0]
    result[first:end] = background
    result[end:] = background[-1]
    return result


def exponential_background(
    x: ArrayLike,
    intensity: ArrayLike,
    anchors: Sequence[int],
) -> FloatArray:
    """Fit ``offset + amplitude * exp(rate * x)`` through three or more anchors."""
    x_values, y_values = as_matching_arrays(x, intensity, min_size=3)
    selected = normalize_indices(anchors, size=x_values.size, name="anchors")
    if len(selected) < 3:
        raise ValueError("at least three anchor indices are required")

    anchor_x = x_values[list(selected)]
    anchor_y = y_values[list(selected)]

    def equation(values: FloatArray, offset: float, amplitude: float, rate: float) -> FloatArray:
        return np.asarray(offset + amplitude * np.exp(rate * values))

    amplitude_guess = float(anchor_y[-1] - anchor_y[0]) or 1.0
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", OptimizeWarning)
        coefficients, _ = curve_fit(
            equation,
            anchor_x,
            anchor_y,
            p0=(float(np.min(anchor_y)), amplitude_guess, -1.0),
            maxfev=20_000,
        )
    return equation(x_values, *coefficients)


def hill_background(
    x: ArrayLike,
    intensity: ArrayLike,
    anchors: Sequence[int],
) -> FloatArray:
    """Fit Igor's Hill equation to four or more background anchors."""
    x_values, y_values = as_matching_arrays(x, intensity, min_size=4)
    if np.any(x_values < 0):
        raise ValueError("hill_background requires non-negative x values")
    selected = normalize_indices(anchors, size=x_values.size, name="anchors")
    if len(selected) < 4:
        raise ValueError("at least four anchor indices are required")
    anchor_x = x_values[list(selected)]
    anchor_y = y_values[list(selected)]
    nonzero_x = anchor_x[anchor_x > 0]
    half_guess = float(np.median(nonzero_x)) if nonzero_x.size else 1.0
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", OptimizeWarning)
        coefficients, _ = curve_fit(
            hill_equation,
            anchor_x,
            anchor_y,
            p0=(float(anchor_y[0]), float(anchor_y[-1]), 1.0, half_guess),
            bounds=([-np.inf, -np.inf, np.finfo(float).eps, np.finfo(float).eps], np.inf),
            maxfev=20_000,
        )
    return hill_equation(x_values, *coefficients)

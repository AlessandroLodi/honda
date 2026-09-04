"""Small, shared array-validation helpers."""

from __future__ import annotations

from collections.abc import Iterable

import numpy as np
from numpy.typing import ArrayLike, NDArray

FloatArray = NDArray[np.float64]


def as_float_array(values: ArrayLike, *, name: str, min_size: int = 1) -> FloatArray:
    """Return *values* as a finite, one-dimensional float array."""
    array = np.asarray(values, dtype=float)
    if array.ndim != 1:
        raise ValueError(f"{name} must be one-dimensional")
    if array.size < min_size:
        raise ValueError(f"{name} must contain at least {min_size} value(s)")
    if not np.all(np.isfinite(array)):
        raise ValueError(f"{name} must contain only finite values")
    return array


def as_matching_arrays(
    x: ArrayLike,
    y: ArrayLike,
    *,
    min_size: int = 2,
) -> tuple[FloatArray, FloatArray]:
    """Validate and return matching one-dimensional x and y arrays."""
    x_array = as_float_array(x, name="x", min_size=min_size)
    y_array = as_float_array(y, name="y", min_size=min_size)
    if x_array.shape != y_array.shape:
        raise ValueError("x and y must have the same shape")
    return x_array, y_array


def require_parameter_groups(
    parameters: ArrayLike,
    *,
    group_size: int,
    name: str,
) -> tuple[float, FloatArray]:
    """Split an offset followed by equally sized parameter groups."""
    values = as_float_array(parameters, name="parameters")
    count = values.size - 1
    if count < group_size or count % group_size:
        raise ValueError(
            f"{name} expects an offset followed by one or more groups of {group_size} parameters"
        )
    return float(values[0]), values[1:].reshape((-1, group_size))


def normalize_indices(indices: Iterable[int], *, size: int, name: str) -> tuple[int, ...]:
    """Validate a collection of unique array indices."""
    normalized = tuple(int(index) for index in indices)
    if len(set(normalized)) != len(normalized):
        raise ValueError(f"{name} must not contain duplicate indices")
    if any(index < 0 or index >= size for index in normalized):
        raise IndexError(f"{name} contains an out-of-range index")
    return normalized

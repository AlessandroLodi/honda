"""A small, explicit replacement for the legacy Igor fitting panels."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass

import numpy as np
from numpy.typing import ArrayLike
from scipy.optimize import least_squares

from ._arrays import FloatArray, as_float_array
from .models import Model


@dataclass(frozen=True, slots=True)
class FitResult:
    """Result of a non-linear least-squares spectrum fit."""

    parameters: FloatArray
    standard_errors: FloatArray
    covariance: FloatArray
    predicted: FloatArray
    residuals: FloatArray
    weighted_sum_squares: float
    degrees_of_freedom: int
    success: bool
    message: str
    evaluations: int


def fit_spectrum(
    model: Model,
    x: ArrayLike,
    y: ArrayLike,
    initial: ArrayLike,
    *,
    bounds: tuple[ArrayLike, ArrayLike] | None = None,
    fixed: Mapping[int, float] | None = None,
    sigma: ArrayLike | None = None,
    max_evaluations: int | None = None,
) -> FitResult:
    """Fit a spectral model while supporting bounds, weights, and held values.

    ``model`` must accept ``(x, parameters)``.  ``fixed`` maps parameter indices
    to held values; this replaces Igor's hold-string UI.
    """
    x_values = as_float_array(x, name="x", min_size=2)
    y_values = as_float_array(y, name="y", min_size=2)
    parameters = as_float_array(initial, name="initial").copy()
    if x_values.shape != y_values.shape:
        raise ValueError("x and y must have the same shape")

    if sigma is None:
        weights = np.ones_like(y_values)
    else:
        sigma_values = as_float_array(sigma, name="sigma", min_size=2)
        if sigma_values.shape != y_values.shape:
            raise ValueError("sigma and y must have the same shape")
        if np.any(sigma_values <= 0):
            raise ValueError("sigma values must be positive")
        weights = 1.0 / sigma_values

    fixed_values = dict(fixed or {})
    for index, value in fixed_values.items():
        if index < 0 or index >= parameters.size:
            raise IndexError(f"fixed parameter index {index} is out of range")
        if not np.isfinite(value):
            raise ValueError("fixed parameter values must be finite")
        parameters[index] = value

    free_mask = np.ones(parameters.size, dtype=bool)
    if fixed_values:
        free_mask[list(fixed_values)] = False

    if bounds is None:
        lower = np.full(parameters.size, -np.inf)
        upper = np.full(parameters.size, np.inf)
    else:
        lower = np.broadcast_to(np.asarray(bounds[0], dtype=float), parameters.shape).copy()
        upper = np.broadcast_to(np.asarray(bounds[1], dtype=float), parameters.shape).copy()
        if np.any(lower > upper):
            raise ValueError("every lower bound must be <= its upper bound")
    if np.any(parameters[free_mask] < lower[free_mask]) or np.any(
        parameters[free_mask] > upper[free_mask]
    ):
        raise ValueError("initial free parameters must lie within bounds")

    def assemble(free_parameters: FloatArray) -> FloatArray:
        full = parameters.copy()
        full[free_mask] = free_parameters
        return full

    def residual_function(free_parameters: FloatArray) -> FloatArray:
        predicted = np.asarray(model(x_values, assemble(free_parameters)), dtype=float)
        if predicted.shape != y_values.shape:
            raise ValueError("model output must have the same shape as y")
        return (predicted - y_values) * weights

    if np.any(free_mask):
        optimized = least_squares(
            residual_function,
            parameters[free_mask],
            bounds=(lower[free_mask], upper[free_mask]),
            max_nfev=max_evaluations,
        )
        fitted = assemble(optimized.x)
        weighted_sum_squares = float(2.0 * optimized.cost)
        evaluations = optimized.nfev
        success = optimized.success
        message = optimized.message
        degrees_of_freedom = y_values.size - int(np.count_nonzero(free_mask))

        covariance = np.zeros((parameters.size, parameters.size), dtype=float)
        if optimized.jac.size and degrees_of_freedom > 0:
            free_covariance = np.linalg.pinv(optimized.jac.T @ optimized.jac)
            free_covariance *= weighted_sum_squares / degrees_of_freedom
            covariance[np.ix_(free_mask, free_mask)] = free_covariance
        standard_errors = np.sqrt(np.maximum(np.diag(covariance), 0.0))
    else:
        fitted = parameters
        weighted_residuals = residual_function(np.empty(0, dtype=float))
        weighted_sum_squares = float(weighted_residuals @ weighted_residuals)
        evaluations = 1
        success = True
        message = "all parameters were fixed"
        degrees_of_freedom = y_values.size
        covariance = np.zeros((parameters.size, parameters.size), dtype=float)
        standard_errors = np.zeros(parameters.size, dtype=float)

    predicted = np.asarray(model(x_values, fitted), dtype=float)
    return FitResult(
        parameters=fitted,
        standard_errors=standard_errors,
        covariance=covariance,
        predicted=predicted,
        residuals=y_values - predicted,
        weighted_sum_squares=weighted_sum_squares,
        degrees_of_freedom=degrees_of_freedom,
        success=success,
        message=str(message),
        evaluations=evaluations,
    )

"""Vectorized line-shape models used by the original Igor Pro procedures.

Every composite model accepts a flat parameter vector.  The first value is a
constant offset; the remaining values are repeated component groups.  This
keeps the models directly usable by optimizers without restoring Igor's global
coefficient waves.
"""

from __future__ import annotations

from collections.abc import Callable

import numpy as np
from numpy.typing import ArrayLike
from scipy.special import erf, gamma, wofz

from ._arrays import FloatArray, as_float_array, require_parameter_groups

Model = Callable[[ArrayLike, ArrayLike], FloatArray]

_SQRT_LN_2 = np.sqrt(np.log(2.0))
_SQRT_PI = np.sqrt(np.pi)


def voigt_profile(
    x: ArrayLike,
    area: float,
    gaussian_fwhm: float,
    center: float,
    lorentzian_fwhm: float,
) -> FloatArray:
    """Return an area-normalized Voigt profile.

    Widths are full widths at half maximum.  The implementation is algebraically
    equivalent to the ``VoigtFunc`` scaling in ``VoigtFit_*.ipf``.
    """
    x_array = np.asarray(x, dtype=float)
    if gaussian_fwhm <= 0:
        raise ValueError("gaussian_fwhm must be positive")
    if lorentzian_fwhm < 0:
        raise ValueError("lorentzian_fwhm must be non-negative")

    scale = 2.0 * _SQRT_LN_2 / gaussian_fwhm
    shape = lorentzian_fwhm * _SQRT_LN_2 / gaussian_fwhm
    amplitude = area * scale / _SQRT_PI
    return np.asarray(amplitude * wofz(scale * (x_array - center) + 1j * shape).real)


def voigt_singlets(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
    """Evaluate Voigt singlets.

    ``parameters`` is ``[offset, area, gaussian_fwhm, center,
    lorentzian_fwhm, ...]``.
    """
    offset, peaks = require_parameter_groups(parameters, group_size=4, name="voigt_singlets")
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for area, gaussian_fwhm, center, lorentzian_fwhm in peaks:
        result += voigt_profile(x, area, gaussian_fwhm, center, lorentzian_fwhm)
    return result


def voigt_doublets(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
    """Evaluate spin-orbit Voigt doublets.

    Each group is ``[area, gaussian_fwhm, center, lorentzian_fwhm,
    branching_ratio, splitting]``.  The second peak is centered at
    ``center - splitting`` and has ``branching_ratio * area``.
    """
    offset, doublets = require_parameter_groups(parameters, group_size=6, name="voigt_doublets")
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for area, gaussian_fwhm, center, lorentzian_fwhm, ratio, splitting in doublets:
        result += voigt_profile(x, area, gaussian_fwhm, center, lorentzian_fwhm)
        result += voigt_profile(
            x,
            ratio * area,
            gaussian_fwhm,
            center - splitting,
            lorentzian_fwhm,
        )
    return result


def doniach_sunjic_profile(
    x: ArrayLike,
    amplitude: float,
    asymmetry: float,
    center: float,
    fwhm: float,
) -> FloatArray:
    """Return the Doniach-Sunjic line shape used by the legacy procedures.

    The formula deliberately preserves the original Igor implementation,
    including its width convention.  In typical fits ``0 <= asymmetry < 1``
    and ``fwhm > 0`` should be enforced with optimizer bounds.
    """
    x_array = np.asarray(x, dtype=float)
    if not 0 <= asymmetry < 1:
        raise ValueError("asymmetry must satisfy 0 <= asymmetry < 1")
    if fwhm <= 0:
        raise ValueError("fwhm must be positive")

    epsilon = center - x_array
    exponent = (1.0 - asymmetry) / 2.0
    magnitude = amplitude * gamma(1.0 - asymmetry)
    magnitude /= (epsilon**2 + fwhm**2 / 4.0) ** exponent
    phase = np.pi * asymmetry / 2.0 + (1.0 - asymmetry) * np.arctan(epsilon / fwhm)
    return np.asarray(magnitude * np.cos(phase))


def doniach_sunjic_singlets(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
    """Evaluate Doniach-Sunjic singlets.

    ``parameters`` is ``[offset, amplitude, asymmetry, center, fwhm, ...]``.
    """
    offset, peaks = require_parameter_groups(
        parameters, group_size=4, name="doniach_sunjic_singlets"
    )
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for amplitude, asymmetry, center, fwhm in peaks:
        result += doniach_sunjic_profile(x, amplitude, asymmetry, center, fwhm)
    return result


def doniach_sunjic_doublets(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
    """Evaluate spin-orbit Doniach-Sunjic doublets.

    Each group is ``[amplitude, asymmetry, center, fwhm, branching_ratio,
    splitting]``.
    """
    offset, doublets = require_parameter_groups(
        parameters, group_size=6, name="doniach_sunjic_doublets"
    )
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for amplitude, asymmetry, center, fwhm, ratio, splitting in doublets:
        result += doniach_sunjic_profile(x, amplitude, asymmetry, center, fwhm)
        result += doniach_sunjic_profile(x, ratio * amplitude, asymmetry, center - splitting, fwhm)
    return result


def asymmetric_gaussian_profile(
    x: ArrayLike,
    amplitude: float,
    center: float,
    width_slope: float,
    width_intercept: float,
) -> FloatArray:
    """Return the Stohr asymmetric Gaussian used for NEXAFS spectra."""
    x_array = np.asarray(x, dtype=float)
    width = x_array * width_slope + width_intercept
    if np.any(np.isclose(width, 0.0)):
        raise ValueError("the asymmetric Gaussian width is zero within x")
    denominator = width / np.sqrt(2.0 * np.log(4.0))
    return np.asarray(amplitude * np.exp(-(((x_array - center) / denominator) ** 2)))


def asymmetric_gaussians(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
    """Evaluate asymmetric Gaussians from offset-plus-four parameter groups."""
    offset, peaks = require_parameter_groups(parameters, group_size=4, name="asymmetric_gaussians")
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for peak in peaks:
        result += asymmetric_gaussian_profile(x, *peak)
    return result


def broadened_step_profile(
    x: ArrayLike,
    amplitude: float,
    center: float,
    gaussian_fwhm: float,
    decay: float,
) -> FloatArray:
    """Return a Gaussian-broadened step with optional exponential decay."""
    x_array = np.asarray(x, dtype=float)
    if gaussian_fwhm <= 0:
        raise ValueError("gaussian_fwhm must be positive")
    if decay < 0:
        raise ValueError("decay must be non-negative")
    step = amplitude * (0.5 + 0.5 * erf((x_array - center) / (gaussian_fwhm / 1.665)))
    tail_start = center + gaussian_fwhm
    decay_factor = np.where(
        x_array <= tail_start,
        1.0,
        np.exp(-decay * (x_array - tail_start)),
    )
    return np.asarray(step * decay_factor)


def broadened_steps(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
    """Evaluate broadened steps from offset-plus-four parameter groups."""
    offset, steps = require_parameter_groups(parameters, group_size=4, name="broadened_steps")
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for step in steps:
        result += broadened_step_profile(x, *step)
    return result


def nexafs_spectrum(
    x: ArrayLike,
    parameters: ArrayLike,
    *,
    n_gaussians: int,
) -> FloatArray:
    """Evaluate a mixed asymmetric-Gaussian and step NEXAFS model.

    The flat vector starts with an offset.  The first ``n_gaussians`` groups
    are asymmetric Gaussians; all remaining groups are broadened steps.
    """
    offset, groups = require_parameter_groups(parameters, group_size=4, name="nexafs_spectrum")
    if not 0 <= n_gaussians <= len(groups):
        raise ValueError("n_gaussians must be between zero and the number of groups")
    result = np.full_like(np.asarray(x, dtype=float), offset, dtype=float)
    for component in nexafs_components(x, parameters, n_gaussians=n_gaussians):
        result += component
    return result


def nexafs_components(
    x: ArrayLike,
    parameters: ArrayLike,
    *,
    n_gaussians: int,
) -> tuple[FloatArray, ...]:
    """Return the offset-free components of a mixed NEXAFS model."""
    _, groups = require_parameter_groups(parameters, group_size=4, name="nexafs_components")
    if not 0 <= n_gaussians <= len(groups):
        raise ValueError("n_gaussians must be between zero and the number of groups")
    gaussians = tuple(asymmetric_gaussian_profile(x, *group) for group in groups[:n_gaussians])
    steps = tuple(broadened_step_profile(x, *group) for group in groups[n_gaussians:])
    return gaussians + steps


def make_nexafs_model(n_gaussians: int) -> Model:
    """Create a two-argument NEXAFS model suitable for :func:`fit_spectrum`."""
    if n_gaussians < 0:
        raise ValueError("n_gaussians must be non-negative")

    def model(x: ArrayLike, parameters: ArrayLike) -> FloatArray:
        return nexafs_spectrum(x, parameters, n_gaussians=n_gaussians)

    model.__name__ = f"nexafs_{n_gaussians}_gaussians"
    return model


def hill_equation(
    x: ArrayLike,
    lower: float,
    upper: float,
    hill_coefficient: float,
    half_saturation: float,
) -> FloatArray:
    """Evaluate Igor Pro's four-parameter Hill equation."""
    x_array = np.asarray(x, dtype=float)
    numerator = np.power(x_array, hill_coefficient)
    denominator = numerator + np.power(half_saturation, hill_coefficient)
    return np.asarray(lower + (upper - lower) * numerator / denominator)


def model_components(
    model: Model,
    x: ArrayLike,
    parameters: ArrayLike,
) -> tuple[FloatArray, ...]:
    """Return individual offset-free components for a supported composite model."""
    values = as_float_array(parameters, name="parameters")
    dispatch: dict[Model, tuple[int, Callable[..., FloatArray]]] = {
        voigt_singlets: (4, voigt_profile),
        doniach_sunjic_singlets: (4, doniach_sunjic_profile),
        asymmetric_gaussians: (4, asymmetric_gaussian_profile),
        broadened_steps: (4, broadened_step_profile),
    }
    if model in dispatch:
        group_size, evaluator = dispatch[model]
        _, groups = require_parameter_groups(values, group_size=group_size, name=model.__name__)
        return tuple(evaluator(x, *group) for group in groups)

    if model is voigt_doublets:
        _, groups = require_parameter_groups(values, group_size=6, name=model.__name__)
        return tuple(voigt_doublets(x, np.concatenate(([0.0], group))) for group in groups)
    if model is doniach_sunjic_doublets:
        _, groups = require_parameter_groups(values, group_size=6, name=model.__name__)
        return tuple(doniach_sunjic_doublets(x, np.concatenate(([0.0], group))) for group in groups)
    raise ValueError(f"components are not implemented for model {model.__name__!r}")

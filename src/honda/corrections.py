"""Small spectrum corrections from the Igor macros."""

from __future__ import annotations

from typing import Literal

import numpy as np
from numpy.typing import ArrayLike

from ._arrays import FloatArray, as_float_array, as_matching_arrays

PhotonSource = Literal["HeII", "MgKa"]
SatelliteMethod = Literal["direct", "iterative"]


def binding_energy(
    kinetic_energy: ArrayLike,
    *,
    photon_energy: float,
    work_function: float = 0.0,
    sample_bias: float = 0.0,
) -> FloatArray:
    """Convert kinetic energy to binding energy."""
    kinetic = as_float_array(kinetic_energy, name="kinetic_energy")
    return np.asarray(photon_energy - kinetic - work_function - sample_bias)


def _shifted(values: FloatArray, points: int) -> FloatArray:
    shifted = np.zeros_like(values)
    if points < values.size:
        shifted[points:] = values[:-points]
    return shifted


def subtract_photon_satellites(
    intensity: ArrayLike,
    energy: ArrayLike,
    *,
    source: PhotonSource,
    method: SatelliteMethod = "direct",
) -> FloatArray:
    """Subtract He II or Mg K-alpha source satellites.

    Shifts and weights reproduce the two ``subtract satellites*.ipf`` macros.
    Data must be equally spaced.  Missing shifted samples at the beginning are
    treated as zero instead of using invalid negative indices.
    """
    energies, values = as_matching_arrays(energy, intensity, min_size=2)
    spacing = np.abs(np.diff(energies))
    if not np.allclose(spacing, spacing[0], rtol=1e-7, atol=1e-12):
        raise ValueError("energy must be equally spaced")
    if source not in {"HeII", "MgKa"}:
        raise ValueError("source must be 'HeII' or 'MgKa'")
    if method not in {"direct", "iterative"}:
        raise ValueError("method must be 'direct' or 'iterative'")

    if method == "direct":
        satellites = ((7.56, 0.10),) if source == "HeII" else ((8.4, 0.08), (10.1, 0.041))
        corrected = values.copy()
        for shift, fraction in satellites:
            points = max(1, int(np.rint(shift / spacing[0])))
            corrected -= fraction * _shifted(values, points)
        return corrected

    satellites = (
        ((7.56, 10.0 / 100.0),) if source == "HeII" else ((8.4, 9.2 / 114.3), (10.0, 5.1 / 114.3))
    )
    normalization = 100.0 / (110.0 if source == "HeII" else 114.3)
    corrected = np.empty_like(values)
    for index, measured in enumerate(values):
        if index == 0:
            corrected[index] = normalization * measured
            continue
        correction = 0.0
        for shift, fraction in satellites:
            previous = index - max(1, int(np.rint(shift / spacing[0])))
            if previous >= 0:
                correction += fraction * corrected[previous]
        corrected[index] = measured - correction
    return corrected

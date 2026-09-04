from __future__ import annotations

import numpy as np
import pytest
from scipy.integrate import trapezoid

from honda.models import (
    doniach_sunjic_doublets,
    make_nexafs_model,
    model_components,
    nexafs_components,
    voigt_doublets,
    voigt_profile,
    voigt_singlets,
)


def test_voigt_profile_is_area_normalized() -> None:
    x = np.linspace(-100.0, 100.0, 200_001)
    profile = voigt_profile(x, 7.0, 1.2, 0.4, 0.3)
    assert trapezoid(profile, x) == pytest.approx(7.0, rel=2e-3)


def test_voigt_doublet_matches_two_profiles() -> None:
    x = np.linspace(-5.0, 5.0, 501)
    parameters = np.array([0.2, 3.0, 0.8, 1.0, 0.25, 0.5, 1.3])
    expected = 0.2 + voigt_profile(x, 3.0, 0.8, 1.0, 0.25)
    expected += voigt_profile(x, 1.5, 0.8, -0.3, 0.25)
    np.testing.assert_allclose(voigt_doublets(x, parameters), expected)


def test_model_components_reconstruct_composite() -> None:
    x = np.linspace(-4.0, 4.0, 301)
    parameters = np.array([0.3, 2.0, 0.6, -1.0, 0.1, 1.0, 0.9, 1.2, 0.2])
    components = model_components(voigt_singlets, x, parameters)
    np.testing.assert_allclose(voigt_singlets(x, parameters), 0.3 + sum(components))


def test_nexafs_factory_handles_mixed_components() -> None:
    x = np.linspace(1.0, 5.0, 101)
    model = make_nexafs_model(1)
    parameters = [0.1, 2.0, 2.0, 0.0, 0.8, 1.0, 3.0, 0.5, 0.2]
    result = model(x, parameters)
    assert result.shape == x.shape
    assert np.all(np.isfinite(result))
    components = nexafs_components(x, parameters, n_gaussians=1)
    np.testing.assert_allclose(result, parameters[0] + sum(components))


def test_models_reject_incomplete_parameter_groups() -> None:
    with pytest.raises(ValueError, match="groups of 6"):
        doniach_sunjic_doublets([0.0, 1.0], [0.0, 1.0, 0.1])

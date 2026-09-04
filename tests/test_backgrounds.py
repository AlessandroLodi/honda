from __future__ import annotations

import numpy as np
import pytest

from honda.backgrounds import (
    exponential_background,
    hill_background,
    linear_background,
    shirley_background,
    tougaard_background,
)
from honda.models import hill_equation


def test_linear_background_uses_selected_endpoints() -> None:
    x = np.arange(6.0)
    y = np.array([20.0, 3.0, 9.0, 8.0, 7.0, 30.0])
    background = linear_background(x, y, start=1, stop=5)
    assert background[1] == pytest.approx(3.0)
    assert background[4] == pytest.approx(7.0)


def test_shirley_background_has_region_endpoint_values() -> None:
    x = np.linspace(0.0, 10.0, 401)
    baseline = 4.0 - 0.2 * x
    y = baseline + 8.0 * np.exp(-(((x - 4.0) / 0.5) ** 2))
    background = shirley_background(x, y)
    assert np.all(np.isfinite(background))
    assert background[0] == pytest.approx(y[0])
    assert background[-1] == pytest.approx(y[-1])


def test_tougaard_background_is_normalized_to_endpoints() -> None:
    y = np.array([10.0, 9.0, 8.0, 6.0, 4.0])
    background = tougaard_background(y)
    assert background[0] == pytest.approx(y[0])
    assert background[-1] == pytest.approx(y[-1])


def test_exponential_background_follows_anchors() -> None:
    x = np.linspace(0.0, 2.0, 21)
    y = 1.5 + 2.0 * np.exp(-0.7 * x)
    background = exponential_background(x, y, [0, 10, 20])
    np.testing.assert_allclose(background, y, rtol=1e-5, atol=1e-5)


def test_hill_background_follows_anchor_curve() -> None:
    x = np.linspace(0.1, 8.0, 81)
    y = hill_equation(x, 1.0, 5.0, 2.0, 2.5)
    background = hill_background(x, y, [0, 20, 50, 80])
    np.testing.assert_allclose(background, y, rtol=2e-5, atol=2e-5)

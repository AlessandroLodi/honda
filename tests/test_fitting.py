from __future__ import annotations

import numpy as np

from honda import fit_spectrum, voigt_singlets


def test_fit_spectrum_recovers_synthetic_peak_and_fixed_offset() -> None:
    x = np.linspace(-3.0, 3.0, 301)
    expected = np.array([0.2, 4.0, 0.75, 0.35, 0.2])
    y = voigt_singlets(x, expected)

    result = fit_spectrum(
        voigt_singlets,
        x,
        y,
        [0.0, 3.5, 0.9, 0.2, 0.3],
        fixed={0: 0.2},
        bounds=(
            [-np.inf, 0.0, 0.05, -2.0, 0.0],
            [np.inf, 10.0, 2.0, 2.0, 2.0],
        ),
    )

    assert result.success
    np.testing.assert_allclose(result.parameters, expected, rtol=2e-4, atol=2e-4)
    np.testing.assert_allclose(result.predicted, y, rtol=1e-6, atol=1e-6)
    assert result.standard_errors[0] == 0.0


def test_fit_spectrum_supports_all_fixed_parameters() -> None:
    x = np.linspace(-2.0, 2.0, 101)
    parameters = np.array([0.1, 2.0, 0.5, 0.0, 0.2])
    y = voigt_singlets(x, parameters)
    result = fit_spectrum(
        voigt_singlets,
        x,
        y,
        parameters,
        fixed=dict(enumerate(parameters)),
    )
    assert result.success
    assert result.weighted_sum_squares < 1e-20

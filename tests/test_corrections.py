from __future__ import annotations

import numpy as np

from honda.corrections import binding_energy, subtract_photon_satellites


def test_binding_energy_conversion() -> None:
    result = binding_energy([10.0, 11.0], photon_energy=21.2, work_function=4.5, sample_bias=0.2)
    np.testing.assert_allclose(result, [6.5, 5.5])


def test_direct_helium_satellite_subtraction_uses_shifted_signal() -> None:
    energy = np.arange(20.0)
    intensity = np.zeros(20)
    intensity[0] = 10.0
    result = subtract_photon_satellites(intensity, energy, source="HeII")
    assert result[0] == 10.0
    assert result[8] == -1.0
    assert np.count_nonzero(result) == 2

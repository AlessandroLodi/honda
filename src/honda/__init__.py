"""Honda spectroscopy analysis toolkit."""

from .backgrounds import (
    exponential_background,
    hill_background,
    linear_background,
    shirley_background,
    tougaard_background,
)
from .corrections import binding_energy, subtract_photon_satellites
from .fitting import FitResult, fit_spectrum
from .magnetism import (
    DichroismResult,
    HysteresisResult,
    average_field_cycles,
    hysteresis,
    split_field_cycles,
    xmcd,
)
from .models import (
    asymmetric_gaussian_profile,
    asymmetric_gaussians,
    broadened_step_profile,
    broadened_steps,
    doniach_sunjic_doublets,
    doniach_sunjic_profile,
    doniach_sunjic_singlets,
    make_nexafs_model,
    model_components,
    nexafs_components,
    nexafs_spectrum,
    voigt_doublets,
    voigt_profile,
    voigt_singlets,
)
from .transforms import (
    extend_parity,
    hilbert_transform,
    kramers_kronig_imag_to_real,
    parity_hilbert_transform,
)

__all__ = [
    "DichroismResult",
    "FitResult",
    "HysteresisResult",
    "asymmetric_gaussian_profile",
    "asymmetric_gaussians",
    "average_field_cycles",
    "binding_energy",
    "broadened_step_profile",
    "broadened_steps",
    "doniach_sunjic_doublets",
    "doniach_sunjic_profile",
    "doniach_sunjic_singlets",
    "exponential_background",
    "extend_parity",
    "fit_spectrum",
    "hill_background",
    "hilbert_transform",
    "hysteresis",
    "kramers_kronig_imag_to_real",
    "linear_background",
    "make_nexafs_model",
    "model_components",
    "nexafs_components",
    "nexafs_spectrum",
    "parity_hilbert_transform",
    "shirley_background",
    "split_field_cycles",
    "subtract_photon_satellites",
    "tougaard_background",
    "voigt_doublets",
    "voigt_profile",
    "voigt_singlets",
    "xmcd",
]

__version__ = "0.1.0"

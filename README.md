# Honda spectroscopy toolkit

Honda is a small Python library for fitting and processing photoemission,
NEXAFS, XMCD, and hysteresis data. It is a tested translation of the Igor Pro
procedures retained at the repository root. The Python API uses explicit NumPy
arrays and return values; it does not depend on Igor waves, global data folders,
graph cursors, or GUI panels.

## Install

Python 3.10 or newer is required.

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -e .
```

For development, install the test and lint tools too:

```bash
python -m pip install -e '.[dev]'
python -m pytest
```

## Fit an XPS spectrum

```python
import numpy as np

from honda import fit_spectrum, shirley_background, voigt_singlets
from honda.io import load_xps_g6

data = load_xps_g6(
    "spectrum.txt",
    photon_energy=1486.6,
    work_function=4.3,
)
x = data["binding_energy"]
y = data["intensity"]

background = shirley_background(x, y, start=10, stop=len(x) - 10)
signal = y - background

# offset, then one [area, Gaussian FWHM, center, Lorentzian FWHM] group
initial = np.array([0.0, 1000.0, 1.0, 285.0, 0.3])
lower = np.array([-np.inf, 0.0, 0.01, 280.0, 0.0])
upper = np.array([np.inf, np.inf, 5.0, 290.0, 5.0])

fit = fit_spectrum(
    voigt_singlets,
    x,
    signal,
    initial,
    bounds=(lower, upper),
)
if not fit.success:
    raise RuntimeError(fit.message)

print(fit.parameters)
print(fit.standard_errors)
```

`start` is inclusive and `stop` is exclusive, like a Python slice. Omit them to
use the full spectrum. Choose the region so its endpoints represent the
background on either side of the peaks.

## Model parameter layouts

All composite models use a flat vector beginning with a constant offset.
Append one group per peak or doublet:

| Model | Repeated parameter group |
| --- | --- |
| `voigt_singlets` | `area, gaussian_fwhm, center, lorentzian_fwhm` |
| `voigt_doublets` | the four above, `branching_ratio, splitting` |
| `doniach_sunjic_singlets` | `amplitude, asymmetry, center, fwhm` |
| `doniach_sunjic_doublets` | the four above, `branching_ratio, splitting` |
| `asymmetric_gaussians` | `amplitude, center, width_slope, width_intercept` |
| `broadened_steps` | `amplitude, center, gaussian_fwhm, decay` |

For mixed NEXAFS models, create a normal two-argument model first:

```python
from honda import fit_spectrum, make_nexafs_model

model = make_nexafs_model(n_gaussians=2)
fit = fit_spectrum(model, energy, intensity, initial_parameters, bounds=bounds)
```

The first two four-value groups are asymmetric Gaussians; subsequent groups are
broadened steps. Use `fixed={parameter_index: value}` in `fit_spectrum` to hold
parameters and `sigma=` for measurement standard deviations. Use
`model_components(...)` for individual Voigt or Doniach-Sunjic peaks and
`nexafs_components(...)` for mixed NEXAFS components.

## Processing and loaders

The public modules are intentionally narrow:

- `honda.backgrounds`: linear, iterative Shirley, discrete legacy Tougaard,
  exponential, and Hill-equation backgrounds.
- `honda.corrections`: binding-energy conversion and He II/Mg K-alpha satellite
  subtraction.
- `honda.transforms`: parity extension, Hilbert transforms, and the discrete
  Kramers-Kronig transform.
- `honda.magnetism`: XMCD, APE/BL7A hysteresis, and repeated field-cycle
  averaging.
- `honda.io`: generic text tables plus BEAR, G6 XPS, APE, and BL7A loaders.

Loaders return typed objects containing ordinary NumPy arrays. For example:

```python
from honda.io import load_ape_dichroism, load_bear

ape = load_ape_dichroism("ape-scan.txt")
energy = ape.energy
asymmetry = ape.result.asymmetry

bear = load_bear(
    "bear-scan.txt",
    names=("energy", "signal", "monitor"),
)
ring_current_ma = bear.metadata.get("ring_current_ma")
```

The library is NumPy/SciPy-only. Their compiled kernels cover the numerical hot
paths, so this version intentionally has no custom C++ extension. See
[`docs/legacy-map.md`](docs/legacy-map.md) for the source-to-module mapping and
the few deliberate corrections made during translation.

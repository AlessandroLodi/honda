# Igor Pro to Python map

The original repository contained one 2006-era Igor Pro toolkit: 27 procedure
files, one Igor packed experiment (`dicrosimo 5576_bis.pxp`), and an FTP log.
The packed experiment and every procedure are retained unchanged as historical
inputs. Runtime code now lives under `src/honda`.

| Legacy source | Python replacement |
| --- | --- |
| `AsymGauss.ipf`, `StepGauss.ipf` | `honda.models` asymmetric Gaussian and broadened-step profiles |
| `VoigtFit_singlets.ipf`, `VoigtFit_doublets.ipf` | `honda.models.voigt_*` |
| `DoniachSunjic.ipf`, `DoniachSunjicDoublet.ipf` | `honda.models.doniach_sunjic_*` |
| Four `Photoemission*_LP.ipf` GUI panels | `honda.fitting.fit_spectrum` with model functions, bounds, fixed values, and weights |
| `doublets from fit.ipf` | `honda.models.model_components` |
| `NEXAFS_fits_LP_tab.ipf` | `honda.models.make_nexafs_model` plus `fit_spectrum` |
| Linear, Shirley, Tougaard, and exponential background procedures | `honda.backgrounds` |
| `smooth part of spectrum.ipf` | `honda.backgrounds.hill_background` |
| Two satellite-subtraction procedures | `honda.corrections.subtract_photon_satellites` (`direct` and `iterative`) |
| `betterhilbert.ipf` | `honda.transforms.extend_parity`, `hilbert_transform`, and `parity_hilbert_transform` |
| `kkimg2real.ipf` | `honda.transforms.kramers_kronig_imag_to_real` |
| `APE dichr every point load.ipf` | `honda.io.load_ape_dichroism` and `honda.magnetism.xmcd` |
| `APE hyst load.ipf` | `honda.io.load_ape_hysteresis` and `honda.magnetism.hysteresis` |
| `BL7A hyst load.ipf` | `honda.io.load_bl7_hysteresis` and field-cycle helpers in `honda.magnetism` |
| `BearDataNew.ipf` | `load_bear`, `dark_statistics`, and `resample_columns` in `honda.io` |
| Two `XPS_G6_Data*.ipf` procedures | `honda.io.load_xps_g6` and `honda.corrections.binding_energy` |

## Deliberate changes

- Igor graph cursors and global waves became function arguments and return
  values. The fitting panels became one optimizer interface.
- The Kramers-Kronig routine honors its `alpha` argument. The original assigns
  `alpha=0` inside the function and cannot calculate the documented higher
  moments.
- Kramers-Kronig summation includes every non-singular sample. The original
  interior loop accidentally omits the final sample.
- Doniach-Sunjic singlets advance by complete four-parameter groups. The source
  function advances one coefficient at a time for multi-peak fits, while its
  own fitting panel and component plot clearly use groups of four.
- Satellite shifts use zero contribution outside the sampled domain instead of
  requesting negative wave indices.
- The iterative Shirley implementation converges the background rather than
  performing only the source macro's single update.
- Invalid shapes, nonuniform axes, incomplete parameter groups, and physically
  invalid widths fail with descriptive exceptions instead of relying on Igor's
  implicit wave behavior.

No C++ layer was added. The line shapes, interpolation, FFT, linear algebra, and
least-squares operations already execute in NumPy/SciPy compiled code. The only
quadratic routines are block-vectorized or call compiled kernels per row, which
keeps the code inspectable and avoids an unprofiled native extension.

`LoadMacroPhEnTime` at the end of `BearDataNew.ipf` only creates empty output
waves and stops; the menu calls a separate `DividePhEnTime` function that is not
present in the repository. No behavior could be translated from that incomplete
stub. The `.pxp` file is experimental data, not source code, and remains
available for use from Igor Pro.

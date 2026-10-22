# Planetary gear model: assumptions, parameters, and results status

## Summary

The MATLAB model now carries a consistent three-planet, equal-load-sharing data path: vehicle demand is converted to carrier torque and speed; planetary kinematics and torque balance produce per-planet mesh forces; VDI 2736 Method C calculations evaluate both sun–planet and planet–ring meshes; and mesh losses feed the thermal calculation. Shared pitch geometry is centralized in `geometry_calc.m`, and the stress results distinguish a single planet path from the three-mesh system total.

The design case reported for this project is 30.4 MPa maximum tooth-root stress, 40.4 MPa maximum flank pressure, and approximately 49°C maximum gear temperature at 25% duty. Those values have not been reproduced from the current source snapshot: `main.m` presently specifies 50% engagement duty, 20° pressure angle, and zero profile shifts. The model snapshot therefore needs the proposed geometry and 25% duty entered and run before those three values can be treated as verified outputs. The previous available run was from an earlier friction setting and is not a reproduction of the current source.

The current implementation is a useful engineering model, but its VDI equations and PA12 life allowables still need a focused manual audit before the safety factors can be described as standard-validated. In particular, the bending geometry factors are not yet derived from the actual shifted tooth geometry, and the temperature/life-dependent PA12 allowable model is not connected to the main calculation.

## Results and design statements

| Quantity | Value | Status |
|---|---:|---|
| Highest tooth-root stress, maximum wheel-open condition | 30.4 MPa | User-reported case result; not reproduced from the current source snapshot |
| Highest flank pressure, maximum wheel-open condition | 40.4 MPa | User-reported case result; not reproduced from the current source snapshot |
| Maximum gear temperature at 25% duty | ~49°C | User-reported case result; current `main.m` uses `ED = 0.5` |
| Safety-factor basis | Temperature- and life-dependent PA12 properties | Intended evaluation basis; current main script does not call `gear_safety.m` or calculate life-adjusted PA12 allowables |
| Planet load distribution | Equal sharing among three planets | Explicit model assumption, implemented as total mesh force divided by three for each planet path |
| Tooth-count / profile-shift design | Sun 16 teeth, planet 11 teeth, internal ring 38 teeth; proposed shifts +0.40, +0.15, +0.70 and pressure angle 24.5° | Tooth counts are in current code; proposed shifts and angle are user design proposal and are not yet in current code |

The current main script has `N_s=16`, `N_p=11`, and `N_r1_i=38` in `main.m` lines 47–49. It has `gear.alpha=20°` at line 105 and zero shifts at lines 117, 126, and 135. It sets `ED=0.5` at line 93. The proposed shift sums are geometrically consistent for the two meshes under the current standard planetary center-distance closure: `x_s+x_p=0.55` for sun–planet and `x_r−x_p=0.55` for planet–ring. This is only a closure check; it does not establish adequate tip thickness, clearance, contact ratio, interference margin, strength, or manufacturability.

## Calculation flow

1. **Vehicle demand (`main.m`)** — the script estimates rolling resistance, grade force, and aerodynamic drag in closed- and open-wheel states, then derives wheel and planetary carrier speed/torque.
2. **Planetary kinematics and force (`planetary_gear.m`)** — the fixed-ring Willis relation and torque balance determine member speeds and torque. The sun–planet and planet–ring total tangential forces are converted to force per planet using the configured planet count.
3. **Shared geometry (`geometry_calc.m`)** — pitch diameters, radii, center distances, and planetary closure/phasing checks are computed once and passed into the mechanics and VDI functions.
4. **Strength calculation (`vdi2736.m`)** — Method C is the intended approach. Both meshes and each member in those meshes receive bending-root and flank-contact calculations. Stress uses the per-planet force; loss power is aggregated across the three parallel mesh paths for system thermal use.
5. **Thermal calculation (`gear_temperature.m`)** — mesh friction and the thermal factors estimate mesh-pair temperature for the selected duty/engagement fraction.
6. **Safety evaluation (`gear_safety.m`)** — this function accepts member-level stress results, but the current `main.m` does not invoke it. `pa12_temperature_factor.m` provides a project-defined temperature multiplier, not a validated PA12 fatigue/life curve.

The intended standard is [VDI 2736 Part 2](https://www.vdi.de/en/home/vdi-standards/details/vdi-2736-blatt-2-thermoplastic-gear-wheels-cylindrical-gears-calculation-of-the-load-carrying-capacity), which addresses load capacity calculations for cylindrical thermoplastic gears. The local reference used for the equation check is [the supplied VDI 2736 PDF](C:/Users/nico5/OneDrive/Documents/Textbooks/Engineering%20Resources/Vdi2736-Blatt%20-%20PLASTIC%20GEAR%20CRITERIA.pdf); page references below are the printed page numbers visible in that document.

## Assumptions and parameter register

VDI-prescribed factors and equations are identified as such and are not repeated as assumed project parameters. Project-selected values and modeling assumptions are listed below. “File / location” gives the code location where the value is currently set or consumed. Items explicitly identified as proposed or user-reported are not yet present as active model inputs.

### Architecture, geometry, and load assumptions

| Assumption or parameter | Current value / treatment | File / location | Basis or resource |
|---|---|---|---|
| Number of planets | 3 | `main.m:59,108`; `planetary_gear.m:12–14,59`; `geometry_calc.m:78–85`; `vdi2736.m:71,125–135,707` | Project architecture assumption; no external citation recorded in source |
| Equal load sharing | Each planet carries one third of the total mesh tangential force; no planet-to-planet load factor is modeled | `vdi2736.m:133–134`; `planetary_gear.m` force-result fields | Project assumption. Requires adequate carrier/pin stiffness, tolerances, and alignment in hardware; validate experimentally or with a compliance/load-distribution model |
| Gear tooth counts | Sun 16, planet 11, inner ring 38 | `main.m:47–49` | Design/packaging inputs; no source recorded in code |
| Module | 1 mm | `main.m:45` | Design input; no source recorded in code |
| Face widths | 10 mm for sun, planet, and ring meshes | `main.m:115,123,132` | Design input; no source recorded in code |
| Baseline pressure angle | 20° currently | `main.m:105` | Current code input. User-proposed revised angle is 24.5°; not yet coded. No external source recorded |
| Baseline profile shifts | `x_s=x_p=x_r=0` currently | `main.m:117,126,135` | Current code inputs. User-proposed values are `x_s=+0.40`, `x_p=+0.15`, `x_r=+0.70`; these are design proposals, not active inputs |
| Proposed shift closure | External sum 0.55 and internal difference 0.55 | User-provided design proposal; related fields in `main.m:117,126,135` | Kinematic/geometric consistency check only. Must still verify tooth thickness, tip/root clearance, contact ratio and interference using actual generated geometry |
| Spur gear assumption | Helix angle β=0 | `main.m:106`; `vdi2736.m` uses spur-case factor branches | Project geometry choice; no source recorded |
| Application factor | `K_A=1` | `main.m:152` | Project assumption of steady/unshocked loading; VDI printed p.11 explains application/load factors, but a value of 1 still requires load-spectrum justification |
| Quality and deviations | Quality grade `Q=9`; listed manufacturing/alignment deviations are set to zero | `main.m:153,158–162` | Project inputs. Zero deviations idealize the build and should be replaced by drawing/tolerance or measurement values |
| Geometry source | One shared `geometry_calc.m` provides canonical pitch geometry | `geometry_calc.m:1–85`; called by `main.m:169`, `planetary_gear.m`, `vdi2736.m` | Implementation decision to avoid conflicting duplicate geometry |
| Model scope | Two load-carrying meshes: sun–planet and planet–ring; ring treated as fixed for planetary kinematics | `planetary_gear.m`; `vdi2736.m` | Architecture assumption; verify against the physical gearbox and power-flow boundary conditions |

### Vehicle, operating, and thermal inputs

| Assumption or parameter | Current value | File / location | Basis or resource |
|---|---:|---|---|
| Vehicle mass | 8 kg | `main.m:10` | Project estimate; no scale measurement or source is cited in code |
| Rolling-resistance coefficient | 0.10 | `main.m:11` | Project assumption; should be replaced by measured tire/surface data |
| Road grade | 0° | `main.m:12` | Level-ground case assumption |
| Air density | 1.225 kg/m³ | `main.m:13` | Standard near sea-level value; actual site altitude/temperature not recorded |
| Frontal area estimate | Built from the dimensions/formula at `main.m:15–17` (calculated area 0.0364 m²) | `main.m:15–17` | Geometry estimate; no wind-tunnel or coast-down source recorded |
| Drivetrain efficiency | 0.94 | `main.m:19` | Project assumption; should be backed by test or component data |
| Motor torque/speed inputs | Stall torque 7.65 Nm and no-load speed 170 rpm | `main.m:21–22` | Motor model inputs; no datasheet citation recorded in source |
| Wheel radii | 0.060 m and 0.1029 m for modeled closed/open states | `main.m:31,35` | Project geometry inputs; verify against tire loaded radius |
| Ambient temperature | 25°C | `main.m:66` | Nominal test/environment assumption |
| Friction coefficient, PA12/PA12 | 0.50 in current source | `main.m:89` | Project input. VDI printed p.10 Table 2 lists friction coefficients by material pair and lubrication condition; check the exact dry/sliding condition and material pair before selecting a value. The earlier 0.40 value noted in a prior run is not the present source value |
| Thermal root coefficient | 2148 in the code’s documented units | `main.m:91` | Selected from the plastic-gear thermal guidance around VDI printed p.10 Table 3; confirm the exact material/contact and unit convention during equation audit |
| Engagement duty `ED` | 0.50 currently | `main.m:93` | Project assumption; VDI printed p.9 defines the engagement-time ratio over a 10-minute interval. The requested 25% case must use 0.25 only if the user’s duty means that same tooth-engagement fraction |
| Housing/air-entry factor | `R_lambda_G=0` | `main.m:95` | Represents unrestricted/open air entry per VDI printed p.11 Table 4; verify the real enclosure and airflow |
| Effective heat-transfer area factor | `A_G=1` | `main.m:97` | Project simplification; geometry/exposure basis not recorded |
| Temperature reported by thermal model | One temperature estimate per mesh pair; tooth-count term currently uses the sum of both members’ counts | `gear_temperature.m:15,32` | Implementation choice. VDI printed p.9 defines `z` for the plastic gear; use member-specific gear tooth count and temperatures if the standard equation is being applied to each member literally |
| System mesh losses | Per-mesh-path loss is multiplied by 3 for system total | `vdi2736.m` loss aggregation around lines 650–680; consumed by `gear_temperature.m` | Consequence of three parallel planets and equal sharing; ensure each input loss is one-planet path loss before multiplication |

### Material, fatigue, and allowable assumptions

| Assumption or parameter | Current value / treatment | File / location | Basis or resource |
|---|---|---|---|
| Polymer grade | PA12; exact manufacturer/process grade is not fully identified in all material inputs | `main.m:68–82`; `pa12_temperature_factor.m` | Must identify exact PA12 grade, print process, build direction, conditioning, and test method before treating strength values as allowables |
| Tensile strength, XY / Z | 48 MPa / 48 MPa | `main.m:68–69` | Compare with the exact HP PA12 grade datasheet; HP’s PA12 material page reports nominal tensile properties, but grade and process must match the printed part ([HP PA12 reference](https://reinvent.hp.com/it-it-3d-digital-parts-manufacturing)) |
| Flexural strength, XY / Z | 65 MPa / 70 MPa | `main.m:71–72` | No matching-grade source is cited in code; obtain the manufacturer datasheet or project coupon test report |
| Elastic modulus, XY / Z | 1700 MPa / 1800 MPa | `main.m:74–75` | Compare to manufacturer values for the exact PA12 process/direction; HP source above is a cross-check, not proof of this exact build/material |
| Fatigue reference life | Provisional PA12 root screen: 25 MPa runout at 10^7 cycles | `main.m:80–83`; `gear_safety.m` | TA EF037 SLS PA12 tensile-coupon data, projected as a lower bound below the runout stress. Not a gear S-N curve or exact failure life; no temperature correction; flank fatigue unassessed |
| HDT values | 95°C at 1.82 MPa; 175°C at 0.45 MPa | `main.m:81–82` | Values correspond to HP 3D High Reusability PA12 datasheet conditions; confirm this exact grade and test method ([datasheet copy](https://info.extolinc.com/hubfs/Downloads/HP%203D%20HR%20PA12%20Material%20Data%20Sheet.pdf)) |
| Temperature reduction in allowable | `pa12_temperature_factor.m` uses a project-defined linear factor from 1.0 at 25°C to 0.25 at 95°C | `pa12_temperature_factor.m` | Not identified as a VDI 2736 PA12 fatigue curve. Replace/calibrate using grade-specific elevated-temperature fatigue data |
| Safety-factor call path | `gear_safety.m` can evaluate supplied member-level stresses and allowables, but the current `main.m` does not call it | `gear_safety.m:1–25`; `main.m` | Therefore current reported stresses/temperatures do not, by themselves, establish computed temperature- and life-dependent safety factors |

## Undercut, tooth count, and the proposed geometry

The 11-tooth planet is in the low-tooth-count region where standard rack generation can produce undercut unless profile shift and tool geometry are selected to prevent it. The proposed positive profile shifts can increase root thickness and may reduce undercut, but the result needs an actual generated tooth form and checks for tip thickness, interference, contact ratio, and backlash.

The statement that undercut is “dictated by (Z_H)” needs correction. In the VDI contact-stress calculation, (Z_H) is the flank/contact zone factor (printed p.16); it does not represent undercut or tooth-root bending fatigue. VDI’s root calculation uses the tooth-form and stress-correction factors (Y_{Fa}) and (Y_{Sa}) (printed pp.11–13), along with the root geometry and permissible bending strength. VDI Figure 1 (printed p.12) relates tooth form factor to tooth count/profile shift and indicates the low-tooth-count/undercut limitations. High pressure angle can increase tooth thickness and strength, while small tooth counts still require careful avoidance of undercut and pointed teeth; see the [JSME study on high-pressure-angle gears with small tooth counts](https://cir.nii.ac.jp/crid/1390870696563807744).

For manual audit, the current `vdi2736.m` assigns common nominal root geometry (`s_Fn=πm_n/2`, `h_Fa=1.25m_n`, `ρ_F=0.38m_n`) to the sun, planet, and ring (around lines 253–285). Those values do not yet reflect each member’s tooth count and proposed profile shift. The ring also uses the generic `YFa`/`YSa` path; internal-gear root factors require particular scrutiny. This limits confidence in the present root-stress result for the 11-tooth planet and shifted design.

## VDI 2736 Method C audit notes

The standard PDF used in the audit is scanned; equation references below use its printed page numbering.

| Topic | Current implementation observation | Audit implication |
|---|---|---|
| Method | `vdi2736.m` is intended as Method C and does not switch to Method B | Keep the equations and factors traceable to the Method C clauses/figures in the supplied edition |
| Tooth-root stress | VDI Eq. (10), printed p.11; root factors are `YFa`, `YSa`, `Yε`, and `Yβ` | `Yepsilon` and spur `Ybeta` branches appear consistent; root geometry/factors need tooth-specific and profile-shift-specific validation |
| Load factors | `KF.m` and `KH.m` return 1.25 while `main.m` sets `K_A=1` | VDI simplified statements relate `K_F`/`K_H` approximately to `K_A` (printed pp.11,17); 1.25 is an extra conservative project multiplier, not the direct simplified result for `K_A=1` |
| Contact stress | VDI Eq. (14), printed p.15; `ZE` Eq. (15), `Zε` Eq. (16), `ZH` printed p.16 | Spur branches are generally aligned; normalize sun/planet ratio notation for readability. `Zepsilon.m` has an εβ≥1 branch that should be checked against the VDI expression even though β=0 here |
| Undercut | Addressed through generated tooth geometry and bending-form terms, not `ZH` | Do not use `ZH` as an undercut or root-fatigue correction |
| Thermal loss | VDI Eqs. (7)–(9), printed pp.8–10 | Loss aggregation must stay per one-planet mesh path until multiplying by three for total system loss; the thermal tooth-count input should be checked against the standard’s plastic-member definition |
| Allowables | Static comparison remains a rough screening only; root fatigue has a runout projection | TA Instruments EF037; `gear_safety.m` | Model root stress is below tested range and gear temperature is ~88.7°C in supplied run; this is not a temperature/life-adjusted allowable. Flank contact fatigue is unassessed |

## Complete assumption checklist

These assumptions currently affect or are proposed for the model:

1. Three planets share load equally; each planet therefore sees one third of each mesh’s total tangential force.
2. The two modeled meshes are sun–planet and planet–inner-ring; the ring is fixed in the kinematic model.
3. Tooth counts, module, face widths, and the gear layout are design inputs rather than derived test data.
4. The current source uses 20° pressure angle and zero profile shift; the proposed design uses 24.5° and shifts +0.40/+0.15/+0.70.
5. The gears are spur gears (β=0).
6. Vehicle mass, rolling resistance, grade, air density, frontal area, drivetrain efficiency, motor torque/speed, and wheel radii represent the modeled operating case.
7. `K_A=1`, quality grade 9, zero listed deviations, and equal planet loading approximate the build and load environment.
8. Ambient temperature is 25°C; the source currently uses 50% engagement duty, μ=0.50, thermal root coefficient 2148, `R_lambda_G=0`, and `A_G=1`.
9. PA12 property values represent a material/process/build-direction combination that must be matched to a specific grade and verified datasheet or coupon tests.
10. The temperature factor is a project linear approximation; it is not a demonstrated PA12 fatigue curve.
11. The 30.4 MPa, 40.4 MPa, and ~49°C values are user-reported case results pending reproduction from a source configuration that actually uses the proposed geometry and 25% duty.
12. The current root tooth geometry is simplified and common across members; tooth-specific undercut and profile-shift effects remain to be incorporated or verified.

## Items to resolve before treating the reported case as verified

- Enter 24.5° and the proposed profile shifts into `main.m`, then recompute the generated geometry and verify tooth thickness, clearance, interference, contact ratio, and planet phasing.
- Set and document `ED=0.25` if 25% means the VDI 10-minute tooth-engagement ratio; otherwise define precisely how the duty cycle maps to VDI `ED`.
- Confirm dry PA12/PA12 friction coefficient and the thermal coefficient units/material case. Current source uses μ=0.50.
- Re-run the max wheel-open case and record the force, stresses, losses, and temperature from the same source snapshot. This is needed to confirm or revise 30.4 MPa, 40.4 MPa, and ~49°C.
- Calculate root and flank safety factors from grade-specific PA12 allowable data at the computed temperature and required life; connect this call to `main.m`.
- Replace the generic root geometry with member-specific factors consistent with the actual shifted external and internal tooth forms, or document and validate an accepted approximation.
- Replace zero manufacturing/alignment deviations and ideal equal planet sharing with tolerances or measured load-distribution evidence when available.

## References

1. Verein Deutscher Ingenieure, **VDI 2736 Blatt 2: Thermoplastic gear wheels — Cylindrical gears — Calculation of the load-carrying capacity**, official standard page: [VDI 2736 Part 2](https://www.vdi.de/en/home/vdi-standards/details/vdi-2736-blatt-2-thermoplastic-gear-wheels-cylindrical-gears-calculation-of-the-load-carrying-capacity). Equation/page citations above refer to the user-supplied PDF: `C:\Users\nico5\OneDrive\Documents\Textbooks\Engineering Resources\Vdi2736-Blatt - PLASTIC GEAR CRITERIA.pdf`.
2. HP, [PA12 material reference](https://reinvent.hp.com/it-it-3d-digital-parts-manufacturing). Confirm that the exact grade and process match the parts before adopting values.
3. HP 3D High Reusability PA12, [material datasheet copy](https://info.extolinc.com/hubfs/Downloads/HP%203D%20HR%20PA12%20Material%20Data%20Sheet.pdf), including HDT test conditions. Use the manufacturer’s current controlled datasheet for final design substantiation.
4. JSME, [Design of High-Pressure-Angle Gears with a Small Number of Teeth](https://cir.nii.ac.jp/crid/1390870696563807744), DOI: 10.1299/jsmemecj.2025.s112-12.
5. “Static and fatigue behavior in presence of notches for PA12 additively manufactured via Multi Jet Fusion,” [International Journal of Fatigue](https://www.sciencedirect.com/science/article/abs/pii/S0142112322001815). Research context only; use data matching the actual material, print orientation, conditioning, temperature, and notch geometry.




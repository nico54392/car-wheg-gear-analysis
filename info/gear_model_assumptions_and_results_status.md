# Planetary gear model: assumptions, parameters and results status

Last updated 2026-10-28, after the VDI 2736 Blatt 2 audit. Page numbers are printed pages in
`Engineering Resources\Vdi2736-Blatt 2 - PLASTIC GEAR CRITERIA.pdf` (2014 edition).

## Results (current main.m)

| Quantity | Closed | Open | Notes |
|---|---:|---:|---|
| Carrier torque / speed | 0.502 N·m, 158.8 rpm | 0.866 N·m, 150.8 rpm | from motor curve vs road load |
| Force per planet, reference d | 6.20 N | 10.69 N | VDI Eq. (2) |
| Root stress, sun / planet (sp mesh) | 3.32 MPa | 5.72 MPa | same value: YFa/YSa are shared placeholders |
| Root stress, planet / ring (rp mesh) | 3.02 / 1.99 MPa | 5.20 / 3.42 MPa | |
| Flank stress sp / rp | 18.82 / 11.75 MPa | 24.71 / 15.42 MPa | |
| Contact ratio sp / rp | 1.331 / 1.532 | same | |
| Max characteristic temperature | 38.4 °C | 47.8 °C | sun flank, Eq. (9) |
| Deformation λ / λ_zul | ~4 % | ~7 % | Eq. (22) |
| Wear life to 0.1·m / 0.2·m | 15 / 30 h (sun governs) | | target is 5475 h |

Earlier numbers (30.4 MPa, 40.4 MPa, ~49 °C, and the 77.5 °C ring temperature) are superseded.

**Headline:** root and flank stresses are low. Temperature is fine against the 95 °C HDT screen.
The thing that actually fails is wear, by about two orders of magnitude, and that rests on a
provisional k_w (see open items).

## Calculation flow

1. `main.m`: vehicle force balance (rolling resistance, grade, drag) against the motor line
   gives max speed and carrier torque for the closed and open wheel.
2. `planetary_gear.m`: Willis relation with fixed ring, torque balance, power check, total and
   per-planet working-circle forces.
3. `geometry_calc.m`: single source for pitch radii, working pressure angle from the shift sums,
   working centre distance, closure, planet phasing and undercut screen.
4. `vdi2736.m`: per mesh and per member: contact ratio, YFa, YSa, Yε, ZE, ZH, Zε, σF (Eq. 10),
   σH (Eq. 14), λ (Eq. 22), H_V (Eq. 8), mesh power in the carrier frame.
5. `gear_temperature.m`: Eq. (7) root and Eq. (9) flank temperature per member. Sun and ring
   get the total of 3 meshes; each planet gets one mesh.
6. `gear_safety.m`: static screens, VDI deformation limit, provisional PA12 root runout.
7. `gear_wear.m`: Eq. (19) average wear, Eq. (21) limit 0.1–0.2·m.

## VDI audit, 2026-10-28

| # | Item | Was | Now | VDI ref |
|---|---|---|---|---|
| 1 | Ring tip radius | `r_r - m(1+x_r)`; tip at 17.3 mm, inside the 17.85 mm base circle | `r_r - m(1-x_r)`, same as `geometry_calc`; error if tip ≤ base circle | p.22 |
| 2 | Partial contact ratio | `(√(r_a²−r_b²) − r·sin α_wt)/p_bt` | `(√(r_a²−r_b²) − r_b·tan α_wt)/p_bt` | p.22 |
| 3 | Internal mesh σH, H_V | (u+1)/u | (u−1)/u (u negative for internal gears, DIN 3990) | Eq. 8, 14 |
| 4 | Rating force | working pitch circle | reference circle d; mesh power still working-circle | Eq. 2, 10 |
| 5 | K_F, K_H | hard-coded 1.25 with K_A = 1 | return K_A; K_A = 1.25 in main.m (same numbers) | p.7, 11, 17 |
| 6 | Friction μ | 0.129, unsourced (comment said PA/PA 0.28) | 0.20, dry plastic/steel | Table 2 |
| 7 | Range check | none | warning if ε_α outside 1–2 for Eq. 8 | p.9 |

Effect of 1–3: the ring contact ratio went from 3.35 to 1.53. Ring root and flank stresses roughly
went up 60 % and 47 %. Ring temperature dropped from 77.5 °C to about 31 °C, and ring wear life
went from 5 h to about 68 h. Items 2 and 4 raised the sun-planet stresses by 3–7 %.

Checked and consistent with VDI: Eq. (7), (8) external, (9), (10), (11), (14) form, (15), (16),
ZH (DIN 3990-2 form), (22) and λ_zul = 0.07·m, Table 3 k_θ for plastic/steel, ED definition.

## Assumptions register

### Architecture and geometry

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Planets | 3, equal sharing, no K_γ | `main.m`, `planetary_gear.m` | project assumption; needs stiff carrier and good tolerances |
| Tooth counts | 16 / 11 / 38 | `main.m` | design; closure 16 + 2·11 = 38, phasing (16+38)/3 = 18 ✓ |
| Module, face width | 1 mm, 10 mm all | `main.m` | design; b/m = 10 ≤ 12 so K_F ≈ K_A applies |
| Pressure angle | 20° | `main.m` | design |
| Profile shifts | +0.40 / +0.15 / +0.70 | `main.m` | x_s + x_p = x_r − x_p = 0.55 → α_w = 24.94°, a_w = 13.990 mm |
| Helix | β = 0 | `main.m` | spur; helical branches deliberately error |
| Tip circles | d ± 2m(1 ± x), no tip shortening | `geometry_calc.m`, `vdi2736.m` | nominal; real cutter geometry not modelled |
| Root geometry for YFa/YSa | s_Fn = πm/2, h_Fa = 1.25m, ρ_F = 0.38m, α_Fan = α_n, all gears | `vdi2736.m` | **placeholder**, ignores z and x. Code gives YFa 3.04, YSa 1.73 for every gear; VDI Fig. 1 for the sun (z 16, x 0.4) is roughly 2.5 |
| Ring YFa | 2.0 | `vdi2736.m` | VDI p.11 |
| Ring YSa | external DIN 3990-3 formula | `YSa.m` | approximation; VDI p.13 points to VDI 2737 |
| Undercut | planet x = 0.15 < x_min ≈ 0.36 | `geometry_calc.m` | screen flags it; real tooth form unchecked |

### Loads and operating case

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Vehicle mass | 8 kg | `main.m` | estimate |
| Rolling resistance | 0.10 | `main.m` | assumption |
| Grade | 0° | `main.m` | level ground |
| Air density, frontal area | 1.225 kg/m³, 0.0364 m² | `main.m` | standard air; area from dimensions |
| Drivetrain efficiency | 0.94 | `main.m` | assumption (VDI p.21 suggests ~0.8 for dry plastic stages) |
| Motor | 7.65 N·m stall, 170 rpm no-load, 12 V | `main.m` | motor data, no datasheet cited |
| Wheel radius closed / open | 0.060 / 0.1029 m | `main.m` | geometry |
| Operating point | max steady speed on the motor line | `main.m` | not a stall or peak-torque case |
| Application factor K_A | 1.25 | `main.m` | VDI p.7 range 1–1.25 for electric motor drives, upper end |
| Peak loads | not checked | — | VDI §3.3 Eq. (23)/(24) not implemented |

### Thermal

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Ambient | 25 °C | `main.m` | assumption |
| μ | 0.20 | `main.m` | VDI Table 2, dry plastic/steel |
| k_θ,Fuß / k_θ,Fla | 900 / 6300 | `main.m` | VDI Table 3, dry plastic/steel |
| ED | 0.30 | `main.m` | assumed engagement fraction over 10 min (VDI p.9 definition) |
| Housing | R_λ,G = 0, A_G = 1 | `main.m` | open, unimpeded air (Table 4); A_G irrelevant when R = 0 |
| Power in Eq. 7/9 | carrier-frame mesh power | `vdi2736.m` | rolling power is what drives mesh loss in a planetary |
| Member mapping | sun/ring: 3 meshes' power; planet: 1 mesh | `gear_temperature.m` | project extension of the single-pair equation |

### Material and allowables

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Sun, ring | HP MJF PA12, E 1.7 GPa (XY), ν 0.47 | `main.m` | provisional, room-temperature E (VDI wants E at gear temperature) |
| Planets | stainless steel, E 193 GPa, σ_y 205 MPa | `main.m` | grade not fixed; outside VDI 2736 scope |
| Static references | flexural 65 MPa (root); tensile 48 MPa kept as metadata | `gear_safety.m` | screening only, no safety factor |
| Root fatigue | 25 MPa runout at 10⁷ cycles | `main.m` | TA EF037 SLS PA12 coupons, not gear data, no temperature correction |
| Flank fatigue | none | — | no σ_HlimN for PA12 |
| Wear coefficient | 284·10⁻⁶ mm³/(N·m) | `main.m` | Odrobina thesis, PA12/PA12 SLS midpoint; real pairing is PA12/steel |
| Temperature derating | none | `pa12_temperature_factor.m` | interface only, returns NaN without calibration |

## Open items, roughly by impact

1. **Wear life (15 h vs 5475 h target).** Get a k_w for PA12 against steel. Also check l_Fl
   (2·m approximation) and drop wear results for the steel planets.
2. **VDI strength check.** Implement σ_FP = Y_St·σ_FlimN/S_Fmin (Eq. 13, Y_St = 2,
   S_Fmin 2.0 continuous / 1.6 intermittent) and σ_HP = σ_HlimN·Z_R/S_Hmin (Eq. 17,
   S_Hmin 1.4). Needs PA12 σ_FlimN and σ_HlimN curves at the computed temperature.
3. **Member-specific YFa/YSa.** Use VDI Fig. 1/2 or a real DIN 3990-3 root-section calc with z and x.
4. **Planet undercut.** Either raise x_p (closure then needs x_r = x_s + 2x_p) or check the
   generated tooth form.
5. **Peak load check**, VDI §3.3: σ_F,s ≤ 2.0·σ_S/S_Smin with S_Smin = 1.5.
6. **Ring YSa** per VDI 2737.
7. **Load sharing and tolerances**: replace zero deviations with drawing values; consider K_γ.

## References

1. VDI 2736 Blatt 2 (2014), *Thermoplastic gear wheels, cylindrical gears, calculation of the
   load-carrying capacity*. Local: `Engineering Resources\Vdi2736-Blatt 2 - PLASTIC GEAR CRITERIA.pdf`.
   [VDI page](https://www.vdi.de/en/home/vdi-standards/details/vdi-2736-blatt-2-thermoplastic-gear-wheels-cylindrical-gears-calculation-of-the-load-carrying-capacity)
2. VDI 2736 Blatt 1, materials and design. Local: `Engineering Resources\Vdi2736-Blatt-1.pdf`.
3. ISO 6336-2:2006 (ZH form). Local: `Engineering Resources\ISO-6336-2-2006  - GEARS.pdf`.
4. HP 3D HR PA12 datasheet (HDT values): [datasheet copy](https://info.extolinc.com/hubfs/Downloads/HP%203D%20HR%20PA12%20Material%20Data%20Sheet.pdf)
5. TA Instruments EF037, PA12 tensile fatigue: [PDF](https://www.tainstruments.com/pdf/literature/EF037.pdf)
6. Odrobina thesis (k_w): [PDF](https://phd.mater.uni-mate.hu/409/11/odrobina_miklos_thesis_DOI.pdf)
7. JSME, high-pressure-angle gears with few teeth: [link](https://cir.nii.ac.jp/crid/1390870696563807744)

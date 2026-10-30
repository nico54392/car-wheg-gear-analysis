# Planetary gear model: assumptions, parameters and results status

Last updated 2026-10-30: research-use pass/fail criteria added. VDI 2736 Blatt 2 audit 2026-10-28. Page numbers are printed pages in
`Engineering Resources\Vdi2736-Blatt 2 - PLASTIC GEAR CRITERIA.pdf` (2014 edition).

## Results (current main.m)

| Quantity | Closed | Open | Notes |
|---|---:|---:|---|
| Carrier torque / speed | 0.502 N·m, 158.8 rpm | 0.866 N·m, 150.8 rpm | from motor curve vs road load |
| Force per planet, reference d | 6.20 N | 10.69 N | VDI Eq. (2) |
| Root stress, sun / planet (sp mesh) | 3.32 MPa | 5.72 MPa | same value: YFa/YSa are shared placeholders |
| Root stress, planet / ring (rp mesh) | 3.02 / 1.99 MPa | 5.20 / 3.42 MPa | |
| Flank stress sp / rp | 18.66 / 11.64 MPa | 24.49 / 15.28 MPa | |
| Contact ratio sp / rp | 1.331 / 1.532 | same | |
| Max characteristic temperature | 38.4 °C | 47.8 °C | sun flank, Eq. (9) |
| Deformation λ / λ_zul | ~4 % | ~7 % | Eq. (22) |
| Wear life to 0.1·m / 0.2·m | 15 / 30 h (sun governs) | | target is 5475 h |

Earlier numbers (30.4 MPa, 40.4 MPa, ~49 °C, and the 77.5 °C ring temperature) are superseded.

## Pass/fail criteria (research use, set 2026-10-30)

This is a research prototype for short tests, so it's rated on two things:

1. **Static strength at motor stall**, 7.65 N·m on the carrier, 94.4 N per planet (`static_peak_check.m`).
   - Roots: VDI Eq. 23/24, σ_F,s ≤ 2.0·σ_S/S_Smin with S_Smin = 1.5, σ_S = 48 MPa. Steel planets use σ_y/S_Smin.
   - Flanks: VDI has no static check. The project screen is Hertz ≤ 1.67·σ_S/S_Smin, i.e. first subsurface yield with the safety factor. MARGINAL means under first yield but inside the factor.
2. **PA12 temperature during a test** (`thermal_check.m`), at the test operating points with ED = 1.
   - PASS below Tg = 44 °C (MJF PA12, DSC), CAUTION up to HDT 95 °C, FAIL above. Graded on the flank temperature (VDI Eq. 9).
   - The whole motor line is also swept and reported as a warning.

Wear and fatigue life are **reference only**, printed with the operating conditions they assume.

| Check | Result | Status |
|---|---|:-:|
| Sun root at stall | 40.4 / 64.0 MPa | PASS 1.58× |
| Ring root at stall | 24.2 / 64.0 MPa | PASS 2.65× |
| Steel planet roots at stall | 40.4, 36.8 / 136.7 MPa | PASS |
| Sun-planet flank at stall | 65.1 MPa vs 53.4 screen, 80 first yield | MARGINAL |
| Planet-ring flank at stall | 40.6 / 53.4 MPa | PASS |
| Flank / body temp, closed top speed, ED = 1 | 54 / 29 °C | CAUTION |
| Flank / body temp, open top speed, ED = 1 | 74 / 32 °C | CAUTION |
| Motor-line envelope | flank over HDT if held at 3–139 carrier rpm for long | warning |
| **Overall** | | **PASS** (flank marginal at stall, above Tg in tests) |

Reference: wear 15 h to 0.1·m at the nominal points (k_w 284·10⁻⁶, printed PA12 on steel).

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
| Planets | 3, equal sharing, no K_γ | `main.m`, `planetary_gear.m` | NR-geo (count); sharing is NR-est; needs stiff carrier and good tolerances |
| Tooth counts | 16 / 11 / 38 | `main.m` | NR-geo; closure 16 + 2·11 = 38, phasing (16+38)/3 = 18 ✓ (KG p.117) |
| Module, face width | 1 mm, 10 mm all | `main.m` | NR-geo; b/m = 10 ≤ 12 so K_F ≈ K_A applies (VDI2 p.11) |
| Pressure angle | 20° | `main.m` | NR-geo |
| Profile shifts | +0.40 / +0.15 / +0.70 | `main.m` | NR-geo; x_s + x_p = x_r − x_p = 0.55 → α_w = 24.94°, a_w = 13.990 mm (KG p.30) |
| Helix | β = 0 | `main.m` | NR-geo, spur; helical branches deliberately error |
| Tip circles | d ± 2m(1 ± x), no tip shortening | `geometry_calc.m`, `vdi2736.m` | KG p.11 basic rack, VDI2 p.22; nominal, real cutter not modelled |
| Root geometry for YFa/YSa | s_Fn = πm/2, h_Fa = 1.25m, ρ_F = 0.38m, α_Fan = α_n, all gears | `vdi2736.m` | **placeholder** from the KG p.11 basic rack, ignores z and x. Code gives YFa 3.04, YSa 1.73 for every gear; VDI2 Fig. 1 for the sun (z 16, x 0.4) is roughly 2.5 |
| Ring YFa | 2.0 | `vdi2736.m` | VDI2 p.11 |
| Ring YSa | external DIN 3990-3 formula (DYK Eq. 4) | `YSa.m` | approximation; VDI2 p.13 fn. 6 points to VDI 2737 |
| Undercut | planet x = 0.15 < x_min ≈ 0.36 | `geometry_calc.m` | KG p.30 limit; real tooth form unchecked |

### Loads and operating case

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Vehicle mass | 8 kg | `main.m` | NR-est |
| Rolling resistance | 0.10 | `main.m` | NR-est |
| Grade | 0° | `main.m` | NR-est, level ground |
| Air density, frontal area | 1.225 kg/m³, 0.0364 m² | `main.m` | USSA76; area from body dims NR-cad |
| Drivetrain efficiency | 0.94 | `main.m` | NR-est (VDI2 p.21 suggests ~0.8 for dry plastic stages) |
| Motor | 7.65 N·m stall, 170 rpm no-load, 12 V | `main.m` | NR-motor; model number still to record |
| Wheel radius closed / open | 0.060 / 0.1029 m | `main.m` | NR-cad |
| Operating point (reference) | max steady speed on the motor line | `main.m` | NR-motor line + NR-est vehicle; not a stall case |
| Application factor K_A | 1.25 | `main.m` | VDI2 p.7 range 1–1.25 for electric motor drives, upper end |
| Peak load | motor stall, 7.65 N·m on the carrier | `static_peak_check.m` | PROJ, value NR-motor; VDI2 §3.3 Eq. 23/24 |

### Thermal

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Ambient | 25 °C | `main.m` | NR-est |
| μ | 0.20 | `main.m` | VDI2 Table 2, dry plastic/steel (VDI1 Fig. 5: ~0.27) |
| k_θ,Fuß / k_θ,Fla | 900 / 6300 | `main.m` | VDI2 Table 3, plastic/steel |
| ED | 0.30 (reference) / 1.0 (test check) | `main.m`, `thermal_check.m` | NR-est / PROJ; VDI2 p.9 definition |
| Housing | R_λ,G = 0, A_G = 1 | `main.m` | VDI2 Table 4, open; A_G placeholder, irrelevant when R = 0 |
| Power in Eq. 7/9 | carrier-frame mesh power | `vdi2736.m` | VDI2 Eq. 7/9 with carrier-frame power (project choice): rolling power drives mesh loss |
| Member mapping | sun/ring: 3 meshes' power; planet: 1 mesh | `gear_temperature.m` | project extension of the single-pair equation |

### Material and allowables

| Assumption | Value | Where | Basis |
|---|---|---|---|
| Sun, ring | HP MJF PA12, E 1.8 GPa (HP-DS), ν 0.40 (FAES) | `main.m` | room-temperature E (VDI wants E at gear temperature) |
| Planets | stainless steel, E 193 GPa, σ_y 205 MPa | `main.m` | 304 assumed, TN304; grade not confirmed; outside VDI 2736 scope |
| Static references | flexural 65 MPa (root); tensile 48 MPa | `gear_safety.m` | HP-DS; screening only, no safety factor |
| Root fatigue | 25 MPa runout at 10⁷ cycles | `main.m` | TA (EF037) SLS PA12 coupons, not gear data, no temperature correction |
| Flank fatigue | none | — | VDI2 Fig. 6 has no PA12 / dry curve |
| Wear coefficient | 284·10⁻⁶ mm³/(N·m) | `main.m` | ODR midpoint; printed PA12 on steel 320–480 (NAR23), molded 16 (VDI1) |
| Temperature derating | none | `pa12_temperature_factor.m` | interface only, returns NaN without calibration |

## Open items, roughly by impact

1. **Wear life** is reference only now. k_w checked 2026-10-30: printed PA12 on steel ≈ 300–500·10⁻⁶ (molded ≈ 16).
2. **VDI strength check.** Implement σ_FP = Y_St·σ_FlimN/S_Fmin (Eq. 13, Y_St = 2,
   S_Fmin 2.0 continuous / 1.6 intermittent) and σ_HP = σ_HlimN·Z_R/S_Hmin (Eq. 17,
   S_Hmin 1.4). Needs PA12 σ_FlimN and σ_HlimN curves at the computed temperature.
3. **Member-specific YFa/YSa.** Use VDI Fig. 1/2 or a real DIN 3990-3 root-section calc with z and x.
4. **Planet undercut.** Either raise x_p (closure then needs x_r = x_s + 2x_p) or check the
   generated tooth form.
5. ~~Peak load check~~ done in `static_peak_check.m`.
6. **Ring YSa** per VDI 2737.
7. **Load sharing and tolerances**: replace zero deviations with drawing values; consider K_γ.

## References

Every source ID used above (NR-geo, VDI2, KG, HP-DS, OD20, ...) has its full citation and link in `info/Gear_Parameter_Values_and_Sources.txt`, which matches the Obsidian note "06 - Sources". NR-* entries are N. Ramos: gear design, robot CAD, motor data, and project estimates.

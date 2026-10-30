CAR WHEG PLANETARY GEARBOX — MATLAB MODEL
Last updated: 2026-10-28

WHAT IT DOES
3-planet fixed-ring planetary stage, equal load sharing. main.m works out the
vehicle demand (closed and open wheel), then for each case runs:
  planetary_gear.m  -> speeds, torques, per-planet mesh forces
  vdi2736.m         -> VDI 2736 Blatt 2 root stress, flank stress, deformation, H_V
  gear_temperature.m-> VDI Eq. 7 / 9 root and flank temperatures
  gear_safety.m     -> static screens + provisional PA12 root runout check
  gear_wear.m       -> VDI Eq. 19 / 21 average wear life
Shared geometry (pitch, working angle, shifts, closure) lives in geometry_calc.m.
Run main.m. Detailed assumptions: gear_model_assumptions_and_results_status.md

CURRENT DESIGN (as coded in main.m)
  Teeth sun/planet/ring: 16 / 11 / 38, m = 1 mm, b = 10 mm, spur
  Pressure angle 20 deg; shifts +0.40 / +0.15 / +0.70 -> working angle 24.94 deg, a_w = 13.990 mm
  Sun and ring: HP MJF PA12. Planets: stainless steel.
  K_A = 1.25 (KF = KH = K_A per VDI), mu = 0.20, k_theta 900 / 6300, ED = 0.30, open air

CURRENT RESULTS (run 2026-10-28, after the VDI audit fixes)
                          closed     open
  Force per planet [N]     6.20     10.69   (at reference diameter)
  Max root stress [MPa]    3.32      5.72   (sun / planet, sun-planet mesh)
  Max flank stress [MPa]  18.82     24.71   (sun-planet)
  Ring flank [MPa]        11.75     15.42
  Max temperature [C]     38.4      47.8    (sun flank characteristic)
  Contact ratio sp / rp   1.331 / 1.532
  Wear life to 0.1 m      15 h, sun governs  <-- far short of the 5475 h target

Old numbers (30.4 MPa, 40.4 MPa, ~49 C, and the 77.5 C ring) are superseded.

FIXES APPLIED IN THE 2026-10-28 VDI AUDIT
1. Ring tip radius used (1+x_r); now (1-x_r), matching geometry_calc. The old
   tip sat inside the base circle, so the ring contact ratio came out ~3.35
   instead of 1.53. That made ring-mesh stresses too low and H_V too high.
2. Partial contact ratios now use r_b*tan(alpha_wt) per VDI p.22 (was r*sin).
3. Internal mesh uses (u-1)/u in sigma_H and H_V (DIN 3990 sign convention).
4. Rating force taken at the reference diameter (VDI Eq. 2/10), not the
   working diameter. Mesh power still uses working-circle values.
5. KF/KH now return K_A, per VDI p.11/17. K_A moved to 1.25 in main.m, so
   the numbers are unchanged; the conservatism is just visible now.
6. mu set to 0.20 (VDI Table 2, dry plastic/steel). Was an unsourced 0.129.
7. Added checks: ring tip inside base circle, and eps_alpha outside 1..2 for Eq. 8.

STILL OPEN
- YFa / YSa use one placeholder root geometry for every gear; they ignore
  tooth count and profile shift. Read the VDI Fig. 1 / 2 values per gear or
  do a proper DIN 3990-3 root-section calc.
- Planet at x = 0.15 is below the rack undercut limit (x_min ~ 0.36).
- Steel planets are outside VDI 2736; rate them with ISO 6336 if it matters.
- gear_safety compares stress straight to flexural/yield strength. It is not
  the VDI check: that needs sigma_FP = 2.0*sigma_FlimN/S_Fmin (S_Fmin 2.0)
  and sigma_HP with S_Hmin 1.4, using PA12 data at the computed temperature.
- Wear: k_w is a provisional PA12/PA12 value but the actual pairing is
  PA12/steel. Wear on the steel planet entries is not meaningful.
- Ring YSa uses the external formula; VDI points to VDI 2737 for internal gears.
- Equal planet sharing and zero tolerances are idealized.

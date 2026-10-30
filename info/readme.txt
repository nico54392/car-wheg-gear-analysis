CAR WHEG PLANETARY GEARBOX — MATLAB MODEL
Last updated: 2026-10-30

WHAT IT'S FOR
Research prototype, short lab tests. The gears have to survive the worst
load the motor can apply and not soften or melt during a test. Life is
nice to know, not a requirement.

PASS/FAIL CHECKS
  1. static_peak_check.m  Static strength at motor stall (7.65 N*m on the
                          carrier). VDI 2736-2 Sec. 3.3, Eq. 23/24 for the
                          roots; first-subsurface-yield screen for flanks.
  2. thermal_check.m      PA12 temperature at the test operating points with
                          the gears running the whole test (ED = 1).
                          PASS < Tg 44 C, CAUTION < HDT 95 C, FAIL above.
                          Also sweeps the whole motor line as a warning.

REFERENCE ONLY (with the conditions they assume, printed by main.m)
  Wear life (gear_wear.m), PA12 root fatigue runout (gear_safety.m),
  stresses and temperatures at the nominal top-speed points.

CALL CHAIN
  main.m -> geometry_calc -> planetary_gear -> vdi2736 -> gear_temperature
         -> gear_safety, gear_wear (reference)
         -> static_peak_check, thermal_check (pass/fail)
  thermal_check reruns planetary_gear/vdi2736/gear_temperature quietly.

CURRENT DESIGN
  Teeth sun/planet/ring 16 / 11 / 38, m = 1 mm, b = 10 mm, spur, 3 planets
  alpha 20 deg, shifts +0.40 / +0.15 / +0.70 -> alpha_w 24.94 deg, a_w 13.990 mm
  Sun, ring: MJF PA12. Planets: stainless steel.
  K_A = 1.25, mu = 0.20, k_theta 900 / 6300, open housing, 25 C ambient

RESULTS (2026-10-30)
  Static at stall, 94.4 N per planet:
    sun root 40.4 / 64.0 MPa allow           PASS (1.58x)
    ring root 24.2 / 64.0                    PASS (2.65x)
    steel planet roots 40.4 and 36.8 / 137   PASS
    sun-planet flank 65.7 MPa                MARGINAL: over the 53.4 MPa
      screen, under first yield (80 MPa). A stall may mark the sun flank.
    planet-ring flank 41.0 / 53.4            PASS
  Temperature, gears running the whole test (flank / body):
    closed top speed  54 / 29 C              CAUTION (flank above Tg)
    open top speed    74 / 32 C              CAUTION
    Holding high torque at low speed (3-139 carrier rpm on the motor line)
    for a long time would push the flank over HDT. Keep those moments short.
  OVERALL: PASS, with those two flags.

  Reference: wear 15 h to 0.1*m at the nominal points (k_w 284e-6, printed
  PA12 on steel), root stress 5.7 MPa vs 25 MPa coupon runout.

OPEN
- YFa / YSa are one placeholder geometry for all gears (YFa 3.04). The
  real sun value is ~2.5, so the stall root margin is probably better.
- Planet x = 0.15 is below the rack undercut limit (~0.36).
- sigma_S for PA12 = 23 C tensile strength (48 MPa); no hot-strength data.
- Add test_points rows in main.m for any harder test (e.g. a climb).
- Power path (carrier -> sun) should be confirmed against CAD.
- Ring YSa per VDI 2737, K_gamma, tolerances, steel grade.

VDI AUDIT 2026-10-28 (commit 914ecfb): ring tip sign, contact ratio
r_b*tan(alpha_wt), internal (u-1), F_t at reference d, KF = KH = K_A,
mu 0.20. Details in gear_model_assumptions_and_results_status.md.

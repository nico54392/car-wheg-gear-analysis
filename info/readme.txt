PLANETARY GEAR MODEL — SUMMARY & ASSUMPTIONS

SUMMARY
The MATLAB model represents a three-planet planetary gearbox with equal load sharing. It calculates vehicle demand, planetary speeds and torques, per-planet forces, VDI 2736 Method C tooth stresses, and mesh-loss heating. Shared gear geometry is calculated in geometry_calc.m.

Reported maximum wheel-open results:
  Tooth-root stress: 30.4 MPa
  Flank pressure:    40.4 MPa
  Gear temperature:  about 49°C at 25% duty

These are user-reported values, not yet reproduced from the current code. The current main.m uses 20° pressure angle, zero profile shifts, and 50% engagement duty. The proposed 24.5° and profile shifts (+0.40 sun, +0.15 planet, +0.70 ring) still need to be entered and run. Safety factors against temperature- and life-dependent PA12 properties are intended, but the current main script does not yet run that evaluation.

KEY ASSUMPTIONS AND PARAMETERS
• Three planets; equal load sharing, so each planet carries one third of total mesh force. Files: main.m, planetary_gear.m, vdi2736.m.
• Gear teeth: sun 16, planet 11, inner ring 38; module 1 mm; face widths 10 mm. File: main.m.
• Current geometry: 20° pressure angle, spur gears, zero profile shift. File: main.m. Proposed geometry: 24.5° and shifts +0.40/+0.15/+0.70; not yet in code.
• Vehicle case: mass 8 kg, rolling resistance 0.10, level road, air density 1.225 kg/m³, drivetrain efficiency 0.94. File: main.m. These are project inputs, not sourced test values.
• Thermal case: ambient 25°C, friction coefficient 0.50, thermal coefficient 2148, ED=0.50, open-air factor 0, area factor 1. File: main.m. The requested 25% case requires ED=0.25 if duty means VDI's engagement-time fraction.
• PA12 inputs include tensile strength 48 MPa (XY/Z), flexural strength 65/70 MPa, modulus 1700/1800 MPa, fatigue reference 2 million cycles at 29.4 MPa and R=0.1, and HDT 95°C/175°C at the stated test loads. File: main.m. Exact material grade/process and sources must be confirmed; pa12_temperature_factor.m uses a project-defined temperature multiplier, not a validated fatigue curve.
• Load factors KF and KH are set to 1.25 in their factor files; main.m uses KA=1. This is an added conservative factor requiring confirmation against the selected VDI simplification.
• Tooth-root geometry in vdi2736.m currently uses common nominal dimensions for all members; the 11-tooth planet and proposed shifts need tooth-specific geometry and undercut checks.

UNDERCUT AND VDI NOTE
A low tooth count can cause undercut and reduce usable root section. Positive profile shift can improve root thickness, subject to tooth-tip, clearance, interference, contact-ratio, and manufacturing checks. In VDI 2736, ZH is a flank/contact zone factor; it does not model undercut or root fatigue. Root bending uses YFa and YSa with the actual tooth geometry. See the supplied VDI PDF, printed pages 11–16, and the small-tooth-count/high-pressure-angle study linked below.

NEXT CHECKS
1. Enter the proposed pressure angle and profile shifts; validate the actual tooth forms and planetary closure.
2. Set ED=0.25 if that matches the intended duty definition.
3. Run the maximum wheel-open case and confirm or revise 30.4 MPa, 40.4 MPa, and ~49°C.
4. Connect safety calculations to grade-specific PA12 strength-versus-temperature-and-life data.
5. Audit member-specific root factors and thermal equation inputs against the supplied VDI edition.

RESOURCES
• VDI 2736 Part 2 (standard scope): https://www.vdi.de/en/home/vdi-standards/details/vdi-2736-blatt-2-thermoplastic-gear-wheels-cylindrical-gears-calculation-of-the-load-carrying-capacity
• User-supplied VDI PDF: C:\Users\nico5\OneDrive\Documents\Textbooks\Engineering Resources\Vdi2736-Blatt - PLASTIC GEAR CRITERIA.pdf
• HP PA12 material reference: https://reinvent.hp.com/it-it-3d-digital-parts-manufacturing
• HP PA12 datasheet copy (HDT conditions): https://info.extolinc.com/hubfs/Downloads/HP%203D%20HR%20PA12%20Material%20Data%20Sheet.pdf
• Small-tooth-count/high-pressure-angle gear study: https://cir.nii.ac.jp/crid/1390870696563807744
• PA12 MJF fatigue study: https://www.sciencedirect.com/science/article/abs/pii/S0142112322001815

Detailed report: gear_model_assumptions_and_results_status.md

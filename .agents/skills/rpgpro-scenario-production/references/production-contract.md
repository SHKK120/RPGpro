# RPGpro Scenario Production Contract

## Camera source of truth

- Scene: `scenes/prototype/green_coast_m02.tscn`
- Projection: perspective
- Position: `(0, 5.35, 10.8)`
- Rotation: `(-27, 0, 0)` degrees
- FOV: `52`
- Rule: re-read the active `Camera3D` before a production batch. Generated assets
  must look photographed within this camera family, not from unrelated per-asset
  viewpoints.

## Environment sprite output

- One isolated environment subject, fully visible.
- RGBA PNG with transparent background and transparent corners.
- No title, label, UI, logo, border, comparison object, or baked environment floor.
- Bottom-centre ground contact; enough transparent padding for filtering.
- Uniform scale only; preserve aspect ratio.
- Stable Green Coast perspective, light direction, palette, material language, and
  detail density.
- Minimum working master: 1024 px on the longest useful dimension unless a live
  model constraint requires another size.

## Quality gate

Score each criterion PASS, WARN, or FAIL and retain the evidence:

1. canonical style match;
2. camera consistency;
3. silhouette clarity;
4. correct asset category;
5. palette consistency;
6. detail density;
7. ground contact;
8. no unwanted background;
9. no baked random props;
10. no UI or text;
11. no obvious perspective mismatch;
12. suitable for Sprite3D;
13. credible beside already approved assets.

Overall PASS requires no FAIL. WARN needs a recorded acceptance reason or a targeted
edit before production approval. Human approval remains separate.

## Bounded refine loop

One candidate -> quality critique -> largest one or two defects -> targeted edit or
controlled regeneration -> quality gate. Default automatic maximum: one refinement
round. A second round requires a named residual failure cause and must remain within
the pre-agreed per-asset CU ceiling. After that, diagnose prompt, reference, control,
or model selection and stop.

## Credit gate

Connection, diagnostics, lean tool discovery, registry work, schema reading, and
planning may proceed without generation. Run `dry_run` before every credit-consuming
operation when supported, record estimated CU, compare it with a pre-agreed
per-asset ceiling, and obtain user approval before the first paid call. Generate one
candidate per asset by default and preserve a usable first result. Model training
always requires separate explicit approval. Never buy add-on credits, upgrade a
subscription, open a payment flow, or enable automatic payment.

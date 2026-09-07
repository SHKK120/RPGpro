---
name: rpgpro-scenario-production
description: Direct RPGpro environment asset production through the official Scenario MCP using canonical references, approved asset IDs, fixed camera and sprite contracts, proxy controls, quality gates, bounded refinement, and Godot 2.5D validation. Use when preparing, generating, editing, approving, or importing Green Coast visual assets with Scenario while preserving the 3D gameplay layer.
---

# RPGpro Scenario Production

Orchestrate the installed official Scenario skills without duplicating their API
instructions. Preserve MASTER-03R: Godot owns gameplay geometry, navigation,
collision, camera, input, combat, and saves; Scenario only produces the visible
2.5D layer.

## Start safely

1. Read `AGENTS.md`, `docs/00_시작.md`, `docs/14_아트스타일.md`,
   `docs/MASTER_03R_2D5D_Visual_Architecture.md`, and
   `docs/art/SCENARIO_REFERENCE_REGISTRY.md`.
2. Confirm the official `scenario` MCP is authenticated and use live diagnostics,
   team/project discovery, model discovery, and tool schemas. Never infer an API
   parameter or silently select among multiple teams/projects.
3. Never put OAuth tokens, API keys, account data, or secrets in the repository.
4. Do not spend credits, train a model, purchase, upgrade, or proceed through a
   payment screen without the applicable user approval. Run `dry_run` before every
   credit-consuming call when the live schema supports it, record estimated CU, and
   stop when the pre-agreed per-asset CU ceiling would be exceeded.
5. Do not design final heroes or monsters unless the user explicitly opens that
   production scope.

## Direct the official skills

- Use `scenario` for connection, discovery, schema inspection, jobs, and downloads.
- Use `scenario-game-assets` and `scenario-image` for image production.
- Use `scenario-consistency` and `scenario-identity-library` for approved reference
  reuse and family identity.
- Use `scenario-asset-analysis` and `scenario-quality-gate` before accepting output.
- Use `scenario-refine-loop` and `scenario-image-editing` for bounded corrections.
- Use `scenario-sprite-animation` only after a directional animation scope is
  explicitly opened.
- Use `scenario-model-training` only after separate model-training approval.

If a required sibling is missing, stop that stage and report the exact missing
skill. Do not reconstruct its workflow from memory. Keep the MCP toolset lean:
discover only the tools required for the current stage rather than loading the full
catalog continuously.

## Apply the production order

Use this priority whenever a canonical reference exists:

1. approved Scenario asset ID;
2. canonical local reference or approved clean crop;
3. edge, depth, silhouette, or proxy control supported by the live model schema;
4. stable category baseline;
5. concise delta describing only the requested change.

Do not replace this chain with a new bare prompt. Prompt-only generation is allowed
only for initial exploration or a category with no usable reference, and its output
remains a candidate.

## Lock baseline and delta

Keep the Green Coast baseline stable and reuse it from this skill and the registry
instead of restating a long style prompt on every call: approved camera family, warm coastal palette,
stylized low-poly material language, rounded readable silhouettes, controlled detail
density, consistent light direction, and the transparent 2.5D output contract. A
delta names only subject-specific changes such as size, lean, canopy, damage, or
equipment. Reuse an approved master plus a delta for variants and family members.

## Prepare controls

Use Godot or Blender proxies for scale, width, height, footprint, silhouette,
orientation, collision intent, and simple mass. A proxy is structural evidence, not
final art. Render it from the actual gameplay camera family. Use edge/depth/control
inputs only after live model discovery confirms the exact supported fields.

## Enforce the sprite contract

For an environment asset require one isolated subject, transparent background,
complete silhouette, bottom-centre ground contact, uniform scale, no text/UI/logo,
no baked floor, no unrelated props, fixed perspective family, and consistent light.
Preserve source aspect ratio. Never stretch X and Y independently.

The gameplay camera source of truth is the active Godot `Camera3D`. The current
Green Coast baseline is perspective, FOV 52 degrees, pitch -27 degrees, yaw 0
degrees, position `(0, 5.35, 10.8)` in the prototype scene. Re-read the scene before
production and record any intentional change; do not improvise a camera per asset.

## Gate quality and refinement

Evaluate each candidate against all thirteen criteria in
`references/production-contract.md`. Record PASS, WARN, or FAIL plus evidence.
Only PASS may enter the approved production directory. Generate one automatic
candidate per asset by default. If it is usable, do not regenerate it. For FAIL,
select the largest one or two causes and run a targeted edit or regeneration. Limit
automatic refinement to one round by default. A second round is allowed only when a
specific remaining failure cause is recorded and its estimated CU stays under the
pre-agreed asset ceiling. After that, report whether prompt, reference, control, or
model selection is the likely cause instead of generating indefinitely.

Prefer editing a strong candidate when only background, colour, framing, decoration,
canopy, or a small silhouette area is wrong. Preserve the approved master.

## Import only approved output

Download only a PASS RGBA asset into `assets/art/2p5d/green_coast/` under its
category. Record provenance and Scenario asset ID in the registry. Then use
`rpgpro-2d5d-asset` for pivot, scale, billboard/fixed-angle rules, import filtering,
and collision proxy linkage. Use `rpgpro-visual-slice` to judge the actual gameplay
frame beside already approved assets.

Never let Scenario output define walkable geometry or collision. Reject collage
appearance, perspective/scale/light mismatch, clipping, false ground contact, or UI
text corruption in the Godot validation scene.

## Close the production slice

Report MCP/auth/team/project/model/tool status separately from local pipeline
readiness. Report credit use as zero unless a live paid operation completed. Keep
technical PASS separate from human visual approval. Do not stage, commit, or push
without a later checkpoint instruction.

Before batch production, validate no more than Tree A, Medium Rock, and Ruin Arch.
Do not mass-produce Terrain, Nature, or Village assets until those representative
assets pass the Godot gameplay-camera check and human review.

---
name: rpgpro-visual-slice
description: Judge and integrate an approved RPGpro gameplay visual slice in Godot, including 2.5D sprite visuals, simple 3D gameplay foundations, reference hierarchy, fixed-frame comparison, density, lighting, Vista composition, and engine verification. Use for visual architecture, scene art passes, environment polish, material and lighting passes, or human-review frames. Do not invent unapproved game, character, or monster design.
---

# RPGpro Visual Slice

Produce a coherent in-game result for the current Bright & Warm Stylized Fantasy Adventure direction while preserving approved gameplay and unresolved art decisions. Prefer image-based 2.5D visible assets over forced AI 3D modeling where the fixed high 3/4 camera allows it. This skill owns what passes on screen; the 2.5D, modeling, and material skills own how visuals and gameplay proxies are made.

## Establish the approved boundary

1. Read `AGENTS.md`, `docs/00_시작.md`, and `docs/40_구현순서.md` first.
2. Read the current slice document plus `docs/14_아트스타일.md`, `docs/16_AI_입체픽셀_스타일가이드.md`, and `docs/MASTER_02_Visual_Production_Baseline.md` when present.
3. Treat the latest user-supplied Gameplay Visual Target, Green Coast Layout Target, and modular production sheets as higher-priority visual evidence than ART-01. Preserve ART-01 as a past technical trial.
4. If the requested slice is not defined, or its predecessor still needs user confirmation, perform only tool or reference preparation. Do not start asset or scene implementation.
5. Keep every `[미정]` unresolved unless the user explicitly decides it. Do not treat a generated image, external review, or tool default as approval.

## Define the visual proof before editing

- Select two to four representative in-game frames from the approved slice: normal play, its main interaction or threat, a location-defining view, and Vista or return-to-base only when relevant.
- Record what each frame must communicate and what gameplay information must remain readable.
- Capture a baseline at a fixed resolution, camera, state, and time of day when the current scene can reproduce it.
- Judge the running Godot frame, not an isolated Blender viewport or concept image, as the final integration surface.
- When an environment baseline is being judged, separate a Production Overview camera from a closer Gameplay Validation camera. Use the overview for module coverage and connections; use the gameplay view for visual acceptance.

## Choose the smallest suitable production path

Use this order unless the slice explains why another path is necessary:

1. Reuse an accepted RPGpro image, sprite, material, or gameplay proxy.
2. Use `rpgpro-2d5d-asset` for actors, vegetation, props, and small structures whose visible quality is best preserved as raster art.
3. Use Godot primitives, reusable scenes, shaders, or deterministic build scripts for ground, collision, ramps, navigation, water, and simple effects.
4. Treat generated imagery as a candidate until its subject, proportions, alpha, pivot, scale, and actual Godot frame match the approved reference.
5. Use `rpgpro-lowpoly-modeling` and `rpgpro-material-texture` for gameplay-support geometry and shared surfaces; use Blender MCP only for an approved high-value form that cannot be expressed cleanly otherwise.
6. Use Meshy, Tripo, Hyper3D, asset libraries, or other external generation only after explicit approval of the service, cost, licence, download, and source-storage plan.

Do not add a different pipeline for every asset type. Prefer deterministic regeneration and shared materials.

## Iterate in visible layers

Work in this order and compare the approved frames after each meaningful layer:

1. Composition and large silhouettes.
2. Traversable floor, boundaries, character, threats, rewards, and interaction readability.
3. Dominant, supporting, and accent colour relationships.
4. Material identity and consistent detail density.
5. Lighting, water, fog, particles, and other restrained finishing effects.

Fix large-shape and value problems before adding surface noise or post-processing. Preserve gameplay roots, IDs, collision, navigation, saving, and input unless the slice explicitly includes them.

Do not stop at the first successful render. Compare it against the highest-priority gameplay target, list the largest visible mismatches, and perform at least one corrective render pass before requesting human visual approval.

## Use Blender MCP safely

- Start with `get_scene_info`, `get_object_info`, and `get_viewport_screenshot` when those tools are exposed.
- The repository MCP registration stays pinned to the existing Blender, package version, loopback address, safe mode, and disabled telemetry unless a separately approved tool-maintenance slice changes them.
- Do not enable `execute_blender_code` merely because this skill triggered. For a concrete approved Blender edit, first write the exact reproducible script in the slice's approved working folder, preserve the source `.blend`, and add only that tool with per-call approval.
- Keep code execution free of external network access, subprocesses, credential reads, arbitrary file traversal, and persistent installation. Save and export only to approved paths.
- After the Blender operation, inspect the scene, object statistics, transforms, pivot, ground contact, materials, and viewport. Restore the MCP allowlist to observation tools when the operation is complete.
- Import through GLB only after checking scale, orientation, pivot, material count, triangle count, and licence/source notes.

## Run the visual quality gate

Compare the final fixed frames with the baseline and check:

- The region and focal point read at first glance.
- Player, route, blocked edge, threat, reward, and interaction do not merge into the background.
- Large silhouettes and value groups read before small texture marks.
- Stone, wood, foliage, cloth, metal, ground, and water remain distinguishable without high-frequency noise.
- Textures do not shimmer, crawl, mismatch UVs, or look intentionally broken during camera movement.
- Vista frames show foreground, middle distance, and background without hiding player state or navigation boundaries.
- Added effects support depth and mood without erasing edges.
- Import, parsing, representative runtime flow, and relevant regressions are checked with the actual Godot executable.

Separate technical confirmation from human visual, play-feel, and fun judgment. Never record an unperformed check as passed.

## Close the slice

- Update `docs/40_구현순서.md` with the exact resume point and `docs/지시장부.md` with the performed work.
- List changed files, generated sources, reproducibility commands, technical evidence, and remaining human checks.
- Do not stage, commit, push, or expand into a later slice unless the user approved that scope.

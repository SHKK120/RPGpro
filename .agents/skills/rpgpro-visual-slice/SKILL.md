---
name: rpgpro-visual-slice
description: Execute an approved RPGpro visual vertical slice or 입체 픽셀 아트패스 in Godot, including reference exploration, Blender asset iteration, fixed-frame visual comparison, and engine verification. Use for M05, Visual Vertical Slice, scene art passes, environment polish, material and lighting passes, Vista composition, or importing and reviewing a Blender asset for this repository. Do not use to invent an unapproved game design or skip a pending predecessor check.
---

# RPGpro Visual Slice

Produce a coherent in-game visual result while preserving the approved gameplay and the project's unresolved art decisions.

## Establish the approved boundary

1. Read `AGENTS.md`, `docs/00_시작.md`, and `docs/40_구현순서.md` first.
2. Read the current slice document plus `docs/14_아트스타일.md` and `docs/16_AI_입체픽셀_스타일가이드.md`.
3. If the requested slice is not defined, or its predecessor still needs user confirmation, perform only tool or reference preparation. Do not start asset or scene implementation.
4. Keep every `[미정]` unresolved unless the user explicitly decides it. Do not treat a generated image, external review, or tool default as approval.

## Define the visual proof before editing

- Select two to four representative in-game frames from the approved slice: normal play, its main interaction or threat, a location-defining view, and Vista or return-to-base only when relevant.
- Record what each frame must communicate and what gameplay information must remain readable.
- Capture a baseline at a fixed resolution, camera, state, and time of day when the current scene can reproduce it.
- Judge the running Godot frame, not an isolated Blender viewport or concept image, as the final integration surface.

## Choose the smallest suitable production path

Use this order unless the slice explains why another path is necessary:

1. Reuse an accepted RPGpro asset or material.
2. Use Godot primitives, reusable scenes, shaders, or deterministic build scripts for terrain, repeated props, water, fog, and simple effects.
3. Use image generation only for composition, palette, silhouette, or texture-reference exploration. Treat its output as a candidate, not a shipping asset by default.
4. Use Blender MCP for a high-value form whose silhouette or authored geometry cannot be expressed cleanly in the existing Godot path.
5. Use Meshy, Tripo, Hyper3D, asset libraries, or other external generation only after explicit approval of the service, cost, licence, download, and source-storage plan.

Do not add a different pipeline for every asset type. Prefer deterministic regeneration and shared materials.

## Iterate in visible layers

Work in this order and compare the approved frames after each meaningful layer:

1. Composition and large silhouettes.
2. Traversable floor, boundaries, character, threats, rewards, and interaction readability.
3. Dominant, supporting, and accent colour relationships.
4. Material identity and pixel-detail frequency.
5. Lighting, water, fog, particles, and other restrained finishing effects.

Fix large-shape and value problems before adding surface noise or post-processing. Preserve gameplay roots, IDs, collision, navigation, saving, and input unless the slice explicitly includes them.

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
- Pixel-like patterns do not shimmer or turn sandy during camera movement.
- Vista frames show foreground, middle distance, and background without hiding player state or navigation boundaries.
- Added effects support depth and mood without erasing edges.
- Import, parsing, representative runtime flow, and relevant regressions are checked with the actual Godot executable.

Separate technical confirmation from human visual, play-feel, and fun judgment. Never record an unperformed check as passed.

## Close the slice

- Update `docs/40_구현순서.md` with the exact resume point and `docs/지시장부.md` with the performed work.
- List changed files, generated sources, reproducibility commands, technical evidence, and remaining human checks.
- Do not stage, commit, push, or expand into a later slice unless the user approved that scope.

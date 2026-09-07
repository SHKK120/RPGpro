---
name: rpgpro-lowpoly-modeling
description: "Build or revise gameplay-support 3D geometry for RPGpro in Godot 4: ground, height, ramps, stairs, foundations, collision proxies, navigation surfaces, cliff blocks, and rare approved hybrid forms. Use when 3D structure affects movement or collision. Do not use as the default pipeline for visible characters, vegetation, props, or small structures after the 2.5D architecture transition."
---

# RPGpro Low-Poly Modeling

Create simple, dependable gameplay-support geometry beneath the Bright & Warm 2.5D visual layer. Let `rpgpro-visual-slice` decide whether the assembled screen passes and `rpgpro-2d5d-asset` own most visible assets; this skill owns physical space, foundations, and proxies.

## Establish the production boundary

1. Read `AGENTS.md`, `docs/00_시작.md`, `docs/40_구현순서.md`, `docs/14_아트스타일.md`, and the active slice document.
2. Read `docs/MASTER_02_Visual_Production_Baseline.md` when it exists. Use its reference hierarchy and exemplar measurements; do not turn them into final game-wide rules without user approval.
3. Preserve gameplay roots, IDs, scripts, collision, navigation, save data, and inputs unless the active slice explicitly includes them.
4. Keep character, monster, combat, and world-design decisions marked `[미정]` or trial-only at their current status.

## Build gameplay geometry in the right order

1. Establish the traversable footprint, blocked footprint, height, and connection plane.
2. Build only geometry required for movement, collision, navigation, shadow reception, or a hybrid cliff/building foundation.
3. Keep the proxy visually subordinate to its sprite layer; do not add detail already carried by the image.
4. Remove hidden geometry, tiny pieces, surface noise, excessive polygon density, and mesh-derived collision.
5. Compare the visible sprite and proxy together from the actual RPGpro gameplay camera.

## Keep assets game-ready

- Use consistent Godot world units and compare against the current player capsule or approved scale reference.
- Place the pivot at the repeatable placement point: ground centre for freestanding assets, connection origin for modules, or documented rig origin for characters.
- Keep ground contact at local `Y = 0` unless a module explicitly documents a different connection plane.
- Make repeated placement deterministic and avoid scene-specific coordinates inside reusable assets.
- Separate visible geometry from collision. Use simple collision shapes that follow the large silhouette.
- Keep traversable surfaces simple and continuous; keep decorative cliff faces, foliage, and rubble out of NavigationMesh baking where appropriate.
- Name child nodes by function and material family, not by transient generator indices.

## Choose the smallest production path

### Tier A — repeated simple forms

Use Godot primitives, reusable scenes, or deterministic construction for ground, paths, cliff modules, basic rocks, fences, platforms, transitions, and test modules.

Treat primitives as construction inputs, not as a production acceptance criterion. Before a Tier A asset is called production-ready, break the default primitive silhouette where its identity depends on form: use tapered trunks and directed branches, asymmetric faceted foliage masses, flat-based directional boulders, large cliff planes, irregular ruin crowns, visible roof overhangs, and clear post-to-rail proportions. If the gameplay-camera read is still Cylinder + Sphere, round ball, plain box wall, or flat colour board, keep it at blockout status and revise the large form.

### Tier B — authored silhouettes

Use approved Blender MCP write tools only when they are already exposed and necessary for a ruin arch, building module, special tree, watchtower part, trophy, or similarly distinctive prop. Preserve the source `.blend`, use the pinned project environment, and export GLB after scale, orientation, pivot, materials, and triangle count checks.

### Tier C — hero, monster, or complex unique assets

Do not call Meshy or another external AI 3D service without explicit approval covering service, cost, licence, download, and source storage. Prepare production requirements and cleanup checklists instead.

Never weaken safe mode, enable arbitrary code or shell execution, download external assets, or expose a non-loopback server to bypass a missing Blender capability. Continue Tier A work in Godot and report only the blocked unique asset.

## Design modular environment pieces

- Give each terrain family explicit connection roles such as Straight, Inner Corner, Outer Corner, End Cap, Ramp, and Transition.
- Align connection edges, top planes, module depth, and pivot convention within a family.
- Prefer reusable building parts—Wall, Door Wall, Window Wall, Corner, Roof, Gable, Porch, Stair—over one indivisible building.
- Build nature from a few base silhouettes plus controlled scale, rotation, and material variation. Do not create a unique mesh for every placement.
- Test at least two adjacent copies and one rotated connection. Reject visible gaps, overlaps, or collision seams that impede play.

## Validate before handoff

- Confirm parse/import success, resource references, scale, pivot, ground contact, collision simplicity, and NavigationMesh effect in Godot 4 Compatibility.
- Inspect triangle and material counts when importing GLB; keep material slots intentional.
- Assemble the asset with neighbouring modules and shared RPGpro materials.
- Check silhouette and repetition from gameplay distance, not only in an isolated editor view.
- Compare same-family variants by silhouette, not scale alone, and reject a production candidate whose identity disappears when rendered without small details.
- Record technical evidence separately from human visual approval and final design approval.
- Do not stage, commit, or push unless the user separately approves it.

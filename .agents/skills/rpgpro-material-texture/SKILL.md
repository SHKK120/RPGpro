---
name: rpgpro-material-texture
description: Create, consolidate, or review RPGpro materials for the 3D foundation beneath the 2.5D visual layer. Use for Green Coast ground, paths, cliffs, ramps, water, collision blocks, sprite filtering, alpha edges, mipmaps, colour matching, or hybrid structure surfaces while preserving older ART-01 trials.
---

# RPGpro Material & Texture

Unify ground, cliff, water, simple-block, and sprite-sampling behaviour for the Bright & Warm 2.5D visual architecture. Let `rpgpro-lowpoly-modeling` own gameplay geometry, `rpgpro-2d5d-asset` own raster visuals, and `rpgpro-visual-slice` own assembled-screen acceptance.

## Establish the production boundary

1. Read `AGENTS.md`, `docs/00_시작.md`, `docs/40_구현순서.md`, `docs/14_아트스타일.md`, and the active slice document.
2. Read `docs/MASTER_02_Visual_Production_Baseline.md` when it exists for the active palette, material families, reference hierarchy, and trial status.
3. Preserve ART-01's 64×64/Nearest assets as a past technical trial unless replacement is explicitly in scope. Do not use them as the default for new production assets.
4. Preserve gameplay code, IDs, collision, navigation, and save state while changing visual resources.

## Resolve surfaces in priority order

1. Silhouette.
2. Geometry and plane readability.
3. Base colour blocks.
4. Material separation.
5. Lighting response.
6. Texture only where the first five cannot express necessary surface information.

Never use texture noise to hide weak geometry.

## Reuse minimal foundation material families

Prefer a small shared library and intentional variants.

- Foundation: Grass, Soil/Path, Rock Cliff, Sand, Shallow Water, Wood, Stone.
- Sprite sampling: RGBA alpha, mipmaps, linear filtering by default, and no material tint unless intentional.
- Character: Skin, Cloth, Leather, Wood, Metal, Accent.
- Add a family only when its surface response is meaningfully different. Do not create one unique material per asset or placement.
- Use restrained warm grass and soil, sunlit neutral stone, warm wood, clear coastal blue, and small purposeful accent colours consistent with the supplied Green Coast sheets.
- Calibrate families together in one engine-lit frame. Preserve value separation between grass, path, sand, cliff, masonry, wood, and water; do not approve a swatch in isolation when lighting turns it neon, pure cyan, lemon yellow, clipped white, or crushed black.

## Choose the simplest stable surface method

Use this order:

1. Colour block in a shared `StandardMaterial3D`.
2. Vertex colour or a small number of material slots for large planes.
3. Simple material parameters shared by a family.
4. A limited texture for readable wood direction, broad stone variation, restrained fabric accent, or a hero asset that genuinely needs surface information.

Do not enforce one texture resolution across the game. Choose the lowest resolution that remains stable at gameplay distance and matches asset size and reuse. Avoid photoreal PBR, micro-noise, deliberately broken pixelation, UV-mismatched repetition, and detail too small for the camera.

## Control filtering and UV stability

- Do not default to Nearest. Test movement for shimmer, crawling, broken edges, and mismatched UV scale.
- Prefer mipmaps and suitable filtering when a texture is visible in motion.
- Prefer vertex colour, simplified UVs, or triplanar projection when those are more stable than a repeated texture.
- Keep similar texel/detail density across environment and character families.
- Review the running Godot frame after camera motion, not only a still texture preview.

## Treat water as a restrained family

- Start with a clear base colour, shallow/deep value separation, small motion, and restrained highlight.
- Avoid expensive realistic reflection, high-frequency normals, dense foam, and effects that obscure boundaries.
- Keep the result compatible with the project's Godot Compatibility renderer unless another renderer is explicitly approved.

## Validate before handoff

- Confirm every resource path resolves and every material works in Godot 4 Compatibility without shader errors.
- Compare adjacent assets for coherent brightness, saturation, roughness, and detail density.
- Re-render after lighting changes and lower material values or light energy when bright planes lose their shape; "bright and warm" must retain facet readability.
- Verify ground/path contrast, walkable/blocked separation, cliff face readability, and water/shore distinction.
- Check repeated assets under scale, rotation, and material variation for noise or obvious cloning.
- Separate technical success from human approval of beauty, atmosphere, and final palette.
- Do not stage, commit, or push unless the user separately approves it.

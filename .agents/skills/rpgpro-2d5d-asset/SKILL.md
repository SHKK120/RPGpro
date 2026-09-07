---
name: rpgpro-2d5d-asset
description: Build, connect, and validate image-based 2.5D visual assets for RPGpro in Godot 4 using Sprite3D, AnimatedSprite3D, fixed-angle structure cards, billboard vegetation, directional actors, and separate simple 3D collision proxies. Use for Green Coast sprite extraction or generation, directional frame setup, pivot and scale calibration, 2.5D props or structures, validation scenes, and replacing visible 3D art without changing gameplay space.
---

# RPGpro 2.5D Asset

Keep the playable world three-dimensional while expressing most visible actors,
vegetation, props, and small structures with image-based assets. Let
`rpgpro-visual-slice` judge the final screen, `rpgpro-lowpoly-modeling` own gameplay
proxies and terrain, and `rpgpro-material-texture` own ground, cliff, water, and
simple-block surfaces.

## Establish the boundary

1. Read `AGENTS.md`, `docs/00_시작.md`, `docs/40_구현순서.md`,
   `docs/14_아트스타일.md`, and the active visual slice document.
2. Use the latest user-supplied Gameplay Visual Target, Green Coast Layout Target,
   and modular kit sheets before older ART-01 evidence.
3. Preserve movement, click-to-move, combat, triggers, IDs, navigation, and saves.
4. Do not design final heroes or monsters without explicit approval. Use a clearly
   identified technical placeholder when directional art is absent.

## Classify every visual

- Use **Billboard Vegetation** for trees, bushes, grass, and small flora. Give only
  trunks or large blocking masses a collision proxy.
- Use **Directional Actor Sprite** for heroes and monsters. Prefer eight directions;
  accept four-direction fallback without duplicating frames deceptively.
- Use **Fixed-Angle Structure Sprite** for a small façade or prop that is only viewed
  from the approved camera range.
- Use **Hybrid Structure** for houses, arches, cliffs, and gates: image visual plus
  separate boxes/capsules/cylinders for walls, openings, and blocked edges.
- Use **Simple 3D Foundation** for ground, ramps, stairs, height, navigation, and any
  surface whose depth affects play.

See [asset-spec.md](references/asset-spec.md) for config fields and numeric defaults.

## Prepare raster assets

1. Keep one subject per source image. Exclude labels, logos, borders, comparison
   figures, and sheet text from runtime textures.
2. Preserve the source aspect ratio. Never compensate for layout by scaling X and Y
   independently.
3. Export RGBA PNG or WebP with transparent corners, a clean matte, and no key-colour
   fringe. Keep the selected generation source under `art/source/` and the runtime
   texture under `assets/art/` when the active slice requires reproducibility.
4. Keep the ground-contact point centered horizontally and at the bottom of visible
   content. Store any exceptional pivot in the asset config.
5. Use mipmaps and linear filtering for painterly or rendered cutouts. Use Nearest
   only for explicitly approved pixel art.
6. Inspect the sprite at 1280x720 in Compatibility/ANGLE. Reject stretching,
   over-cropping, halos, unreadable silhouettes, or a result that no longer matches
   the approved reference subject.

## Connect to Godot

1. Instantiate the repository base scene matching the classification.
2. Assign an `AssetConfig2D5D`; do not hide scale, pivot, facing, or collision policy
   in scene-specific code.
3. Keep the visual below a dedicated `VisualRoot` and gameplay collision below a
   dedicated `CollisionProxy`. Never generate collision from sprite alpha.
4. Use full billboard only for soft vegetation. Use fixed-Y billboard when a prop
   must stay upright. Disable billboard for architecture composed for the fixed camera.
5. Keep actors' movement vector, aim vector, and visual facing separate. Quantize the
   visual direction only after choosing four- or eight-direction mode.
6. Keep optional shadows simple and separate from the sprite texture.

## Validate the assembled result

- Confirm project load, headless scene load, Compatibility/ANGLE render, missing
  resources, and broken references.
- Verify click movement and collision proxies against the visible footprint.
- Check that openings look open and are traversable, while visible walls block play.
- Check several depths and screen edges for aspect-ratio drift or billboard flipping.
- Inspect all visible Korean and English UI text for missing glyphs, clipping, overlap,
  and accidental text baked into sprites.
- Compare the final gameplay frame with the original supplied images. Record large
  composition, density, palette, and silhouette mismatches before requesting human
  approval.
- Keep technical confirmation separate from human visual approval. Do not stage,
  commit, or push unless the user separately approves it.

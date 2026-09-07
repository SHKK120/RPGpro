# RPGpro 2.5D asset specification

## Config fields

| Field | Meaning |
|---|---|
| `visual_type` | Billboard vegetation, directional actor, fixed-angle structure, hybrid structure, or simple 3D foundation |
| `facing_mode` | Full billboard, fixed-Y billboard, fixed angle, directional four, or directional eight |
| `texture` / `sprite_frames` | Runtime RGBA texture or animation resource |
| `pixel_size` | World metres per source pixel |
| `uniform_scale` | One multiplier applied equally to width and height |
| `ground_pivot` | Normalized contact point; default `(0.5, 1.0)` |
| `collision_type` | None, box, capsule, or cylinder |
| `collision_size` | Proxy dimensions in world metres |
| `collision_offset` | Proxy offset from the visual root |
| `optional_shadow` | Enables the separate cheap ground shadow |
| `navigation_obstacle` | Marks a future navigation-obstacle policy; it does not auto-bake sprite alpha |

## Production defaults

- Use a single `uniform_scale`; never stretch width and height independently.
- Use `pixel_size = 0.005` as the initial rendered-cutout calibration, then compare to
  the 2 m player proxy in the validation scene.
- Use `(0.5, 1.0)` for freestanding ground-contact pivots.
- Use fixed-Y billboard for trees and free-standing small props.
- Use fixed angle for a cottage or ruin composed for the approved high 3/4 camera.
- Use capsule collision for actors, narrow box collision for trunks and sign posts,
  and multiple simple boxes for structures with openings.

## Direction keys

Name direction animations with a shared state prefix followed by a direction suffix:

`idle_s`, `idle_sw`, `idle_w`, `idle_nw`, `idle_n`, `idle_ne`, `idle_e`, `idle_se`.

For four-direction fallback, provide `s`, `w`, `n`, and `e`; the runtime maps diagonal
requests to the nearest available cardinal animation.

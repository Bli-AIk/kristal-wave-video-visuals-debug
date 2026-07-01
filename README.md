# Kristal Wave Video Debug

A small Kristal library for overlaying per-wave Ogg Theora videos or reference images during battle waves.

## Usage

Install this repository as a folder or zip under your project's `libraries/` directory.

Enable it in your project's `mod.json`:

```json
"config": {
    "wave-video-debug": {
        "enabled": true,
        "priority": "video",
        "alpha": 0.3
    }
}
```

Place debug files under a `debug/` directory in your mod root (NOT under `assets/`, so they won't be packaged into the game build):

```text
debug/kris_phase1_1.ogv
debug/kris_phase1_1.jpg
```

The filename must match the wave id. Supported formats:
- Video: `.ogv`, `.ogg` (Ogg Theora)
- Image: `.png`, `.jpg`, `.jpeg`

## Config

- `enabled`: `true` to show debug visuals.
- `debug_dir`: directory under the mod root containing debug videos and images; defaults to `"debug"`.
- `priority`: `"video"` or `"image"`; defaults to `"video"`.
- `alpha`: overlay opacity from `0` to `1`; defaults to `0.3`.
- `layer`: battle layer name or number; defaults to `"top"`.
- `audio`: whether to load video audio; defaults to `false`.
- `fit`: `"stretch"`, `"contain"`, or `"cover"`; defaults to `"stretch"`.
- `loop`: whether the reference video loops; defaults to `false`.
- `sync_timescale`: whether videos seek by Kristal stage timescale; defaults to `true`, matching Ctrl+O selection slowdown.

If several waves run at once, the first wave with a matching visual is used. Missing visuals are ignored.

When Ctrl+O object selection is open and Kristal's Selection Timestop setting is enabled, arrow keys nudge the overlay by 1px for alignment.

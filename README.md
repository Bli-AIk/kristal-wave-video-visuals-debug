# Kristal Wave Video Debug

A small Kristal library for overlaying per-wave Ogg Theora videos or PNG reference images during battle waves.

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

Place videos under `assets/videos/waves/`, using the wave id as the filename:

```text
assets/videos/waves/kris_phase1_1.ogv
```

Kristal only supports Ogg Theora videos for `assets/videos`.

If a video is missing, the library can show a PNG with the same wave id:

```text
assets/sprites/waves/kris_phase1_1.png
```

## Config

- `enabled`: `true` to show debug visuals.
- `video_dir`: folder under `assets/videos`; defaults to `waves`.
- `image_dir`: folder under `assets/sprites`; defaults to `waves`.
- `priority`: `video` or `image`; defaults to `video`.
- `alpha`: overlay opacity from `0` to `1`; defaults to `0.3`.
- `layer`: battle layer name or number; defaults to `top`.
- `audio`: whether to load video audio; defaults to `false`.
- `fit`: `stretch`, `contain`, or `cover`; defaults to `stretch`.
- `loop`: whether the reference video loops; defaults to `false`.
- `sync_timescale`: whether videos seek by Kristal stage timescale; defaults to `true`, matching Ctrl+O selection slowdown.

If several waves run at once, the first wave with a matching visual is used. Missing visuals are ignored.

# SpaceArt — a macOS screen saver

A screen saver that slowly pans and crossfades through classic painterly
space art: huge stations and ships hanging over planets, in the style of
John Berkey and Chris Foss.

Each image stays on screen for about 24 seconds while it slowly drifts and
zooms — a Ken Burns pan, so the ships and stations seem to glide across the
screen — then crossfades into the next. A full cycle through all 59 images
takes about 25 minutes. Works full-screen and in the System Settings
preview pane.

## Install

On a Mac with Xcode Command Line Tools installed:

```sh
./install.sh
```

Then open **System Settings > Screen Saver** and pick **SpaceArt**.

Or build without installing:

```sh
./build.sh
```

then double-click the resulting `SpaceArt.saver`.

No Xcode project is needed — `build.sh` compiles the Swift source directly
with `swiftc`.

## Add your own images

1. Drop a `.jpg` into `Resources/`.
2. Add its file name (without extension) to the `imageNames` list in
   `Sources/SpaceArtView.swift`.
3. Rebuild with `./install.sh`.

## Artwork

59 paintings, all at least 1400 px on the long edge (most 1500 px, the
largest 3000 px), included here for personal use as a screen saver:

- **John Berkey** (54) — including "Fly-Over", the 1977 Star Wars
  soundtrack poster, and a run of his Space Study paintings
- **Chris Foss** (2) — including a tethered ship over an asteroid field
- **Peter Elson** (1) — a starship dwarfed by a ringed planet
- **Jim Burns** (1) — "His Conquering Sword"
- **Tim White** (1) — an A-shaped orbital habitat over a green planet

## How it works

`Sources/SpaceArtView.swift` is a single `ScreenSaverView` subclass. Two
`CALayer`s alternate: the incoming layer gets the next image and a slow
combined zoom-and-pan animation, then a `CATransaction` crossfades the two
layers. The pan direction and zoom direction vary from slide to slide.

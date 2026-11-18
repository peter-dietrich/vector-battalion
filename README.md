# Vector Battalion — Fun City Arcade

A native macOS three-lane auto-shooter built with SwiftUI and SceneKit. Steer a moving squad, shoot numbered gates, recruit additional soldiers and survive progressively harder waves.

## Play

- Move the mouse horizontally (or click and drag) to steer.
- Squad weapons fire automatically.
- Destroy cyan recruitment pods and yellow upgrade gates before they reach the squad.
- Avoid red blockers. Recruit additional soldiers for increased firepower.
- Press **P** to pause/resume; **Command-N** to restart.

## Build and run on macOS

Requires macOS 13+ and Xcode 16+.

Open `Package.swift` with Xcode, select the **VectorBattalion** executable scheme and run on **My Mac**. Alternatively:

```sh
swift run VectorBattalion
```

This is the initial gameplay prototype (v0.1.0). It has not yet been compiled or playtested on a Mac in this development environment.

## Design / ownership

Part of the [Fun City Arcade](https://github.com/peter-dietrich/fun-city) family. Each game stays in its own repository. Assets are programmatically generated; there are no third-party game art assets.

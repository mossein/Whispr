# Whispr

<p align="center">
  <img src="https://raw.githubusercontent.com/mossein/Whispr/82d6f3bc3899ef1105c1088a291cf06a1adbccd2/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" alt="Whispr icon">
</p>

A lightweight macOS menubar app for voice-to-text. Hold a key, speak, release - your words are transcribed and pasted instantly.

Powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit) for fully local, on-device transcription via CoreML. No data leaves your Mac.

## How it works

1. Hold **Right Command** (configurable) - a floating popup appears with a waveform
2. Speak
3. Release - transcribed text is pasted into the focused app

## Install

```bash
brew tap mossein/whispr
brew install --cask whispr
```

Or download `Whispr-macOS.zip` from [Releases](https://github.com/mossein/Whispr/releases).

On first launch, grant **Accessibility** and **Microphone** permissions when prompted.
The speech model downloads automatically on first use.

## Build from source

Requires Xcode 16+ and Apple Silicon.

```bash
brew install xcodegen    # if not installed
xcodegen generate
xcodebuild -project Whispr.xcodeproj -scheme Whispr -configuration Release build
```

The built app is at `build/Release/Whispr.app` - copy to `/Applications`.

## Architecture

| File | Purpose |
|------|---------|
| `KeyMonitor.swift` | Global key detection via NSEvent |
| `AudioEngine.swift` | Mic capture at 16kHz with real-time audio levels |
| `Transcriber.swift` | WhisperKit wrapper (base.en model, CoreML) |
| `PopupPanel.swift` | Non-activating floating panel with waveform |
| `PasteService.swift` | Clipboard + simulated Cmd+V |
| `AppCoordinator.swift` | Wires everything together |
| `Settings.swift` | Configurable key binding and model selection |

## Requirements

- macOS 14+
- Apple Silicon (M1/M2/M3/M4)

## License

MIT

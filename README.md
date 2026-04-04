# Whispr

A lightweight macOS menubar app for voice-to-text. Hold a key, speak, release - your words are transcribed and pasted instantly.

Powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit) for fully local, on-device transcription via CoreML. No data leaves your Mac.

## How it works

1. Hold **Right Command** - a floating popup appears with a waveform
2. Speak
3. Release - transcribed text is pasted into the focused app

## Requirements

- macOS 14+
- Apple Silicon (M1/M2/M3/M4)
- ~1-3GB disk space for the Whisper model (downloaded on first launch)

## Download

Grab `Whispr-macOS.zip` from [Releases](https://github.com/mossein/Whispr/releases), unzip, and move to Applications.

Since the app isn't code-signed, macOS will block it. Run this once to fix:

```bash
xattr -cr /Applications/Whispr.app
```

## Build from source

```bash
swift build
swift run
```

## Permissions

On first launch, grant **Accessibility** and **Microphone** in System Settings > Privacy & Security.

## How it's built

| File | Purpose |
|------|---------|
| `KeyMonitor.swift` | Global right-Command key detection via CGEventTap |
| `AudioEngine.swift` | Mic capture at 16kHz with real-time audio levels |
| `Transcriber.swift` | WhisperKit wrapper (large-v3 model, CoreML) |
| `PopupPanel.swift` | Non-activating floating panel with waveform |
| `PasteService.swift` | Clipboard + simulated Cmd+V |
| `AppCoordinator.swift` | Wires everything together |

## License

MIT

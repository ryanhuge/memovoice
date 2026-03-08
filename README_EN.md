# MemoVoice

**English | [繁體中文](README.md)**

MemoVoice is a native macOS speech-to-text application powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit). All speech processing runs entirely on-device — nothing is uploaded to the cloud, keeping your data private. It supports long-form audio transcription, AI translation, meeting summaries, text-to-speech, subtitle export, and more.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License](https://img.shields.io/badge/License-Private-lightgrey)

## Features

### Speech-to-Text
- **On-device recognition with WhisperKit** — Accelerated by Apple Neural Engine + GPU (Metal) + CPU. All processing stays on your Mac.
- **Multiple model options** — Choose from Tiny (~75MB) to Large V3 (~2.9GB) to balance speed and accuracy:
  - Tiny (~75MB) — Fastest, suitable for real-time use
  - Base (~140MB) — Basic quality
  - Small (~466MB) — Balanced speed and quality
  - Medium (~1.5GB) — High quality
  - Large V3 (~2.9GB) — Highest accuracy
  - Large V3 Turbo (~1.6GB) — Recommended; near Large V3 accuracy with faster speed
- **Smart VAD segmentation** — Voice Activity Detection automatically segments audio with precise timestamps
- **14 languages supported** — Traditional Chinese (default), Simplified Chinese, English, Japanese, Korean, French, German, Spanish, and more
- **Model preloading** — Default model loads in the background at app launch, so transcription starts instantly
- **Pause / Cancel** — Pause or cancel transcription at any time
- **Concurrent processing** — Multi-core parallel decoding for maximum hardware utilization

### Audio Import
- **Audio files** — MP3, WAV, M4A, FLAC, AAC, OGG, AIFF, QTA
- **Video files** — MP4, MOV, MKV, AVI, WebM, and more (audio extracted via FFmpeg)
- **YouTube import** — Paste a YouTube URL to automatically fetch the video title, download audio, and transcribe (requires yt-dlp)
- **Built-in recording** — Record directly within the app and transcribe immediately
- **Voice Memos integration** — Supports macOS Voice Memos `.qta` (QuickTime Audio) format via Finder's "Open With"
- **Drag & drop** — Drag audio or video files into the window to import

### AI Translation
- **Multiple providers** — Claude CLI, OpenAI, Google Gemini, DeepSeek, OpenRouter
- **Segment-by-segment** — Each timestamped segment is translated independently, preserving the original text
- **Side-by-side display** — Original and translated text shown in parallel columns

### Meeting Summaries
- **AI-powered summaries** — Automatically generate structured summaries from transcripts using Claude CLI or other AI services
- **Built-in templates** — Meeting notes, action items, standup reports
- **Custom templates** — Create, edit, and manage your own summary templates in Settings
- **Export summaries** — Markdown, plain text, or Word document format

### Text-to-Speech (TTS)
- **Multiple TTS engines** — System voices, Edge TTS, Fish Audio, MiniMax
- **Read original or translated text** — Choose to read aloud the transcription or its translation

### Audio Player
- **Built-in player** — Play/pause, skip forward/backward 5 seconds, seekable progress bar
- **Adjustable playback speed** — 0.5x to 2.0x
- **Timestamp sync** — Click any segment to jump to that position; current segment is highlighted during playback

### Export
- **SRT subtitles** — Standard SRT format, ready for video subtitle software
- **Word documents** — DOCX format with timestamps, segments, and translations
- **Markdown** — With title, timestamps, and segment text
- **Plain text** — TXT format, with optional timestamps

### Storage Management
- **Model management** — Download or delete individual Whisper models
- **Cache cleanup** — View and clear extracted audio, TTS cache, and other temporary files in Settings

## System Requirements

| Item | Requirement |
|------|-------------|
| OS | macOS 14.0 (Sonoma) or later |
| Processor | Apple Silicon (M1/M2/M3/M4) recommended; Intel Macs also supported |
| RAM | 8GB minimum (16GB+ recommended for Large models) |
| Disk | 500MB minimum (~2GB+ with models) |

## Installation

### Option 1: Download Release

Go to [Releases](https://github.com/ryanhuge/memovoice/releases) and download the latest `MemoVoice.zip`:

1. Download and unzip `MemoVoice.zip`
2. Drag `MemoVoice.app` to your Applications folder
3. On first launch, if you see "cannot be opened", go to System Settings > Privacy & Security and click "Open Anyway"
4. The default speech recognition model (Large V3 Turbo ~1.6GB) will download automatically on first launch

### Option 2: Build from Source

```bash
git clone https://github.com/ryanhuge/memovoice.git
cd memovoice
open MemoVoice.xcodeproj
```

Select the `MemoVoice` scheme in Xcode and press `Cmd+R` to run.

#### Build Release and Install

```bash
xcodebuild -scheme MemoVoice -configuration Release archive -archivePath /tmp/MemoVoice.xcarchive
cp -R /tmp/MemoVoice.xcarchive/Products/Applications/MemoVoice.app /Applications/
```

## Optional Tools

The following tools are optional and can be installed via [Homebrew](https://brew.sh):

| Tool | Purpose | Install |
|------|---------|---------|
| [FFmpeg](https://ffmpeg.org) | Extract audio from video, convert audio formats | `brew install ffmpeg` |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Download audio from YouTube | `brew install yt-dlp` |
| [Claude CLI](https://github.com/anthropics/claude-code) | AI translation and meeting summaries | `npm install -g @anthropic-ai/claude-code` |

Tool paths can be customized in the app under Settings > Tools.

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Speech Recognition | WhisperKit (CoreML / Neural Engine / Metal) |
| Data Storage | SwiftData |
| Audio Playback | AVFoundation |
| Translation | Claude CLI / OpenAI / Gemini / DeepSeek / OpenRouter |
| Text-to-Speech | System Voices / Edge TTS / Fish Audio / MiniMax |
| DOCX Export | SwiftDocX |
| API Key Storage | Keychain |
| Localization | String Catalog (.xcstrings) — English & Traditional Chinese |

## Project Structure

```
MemoVoice/
├── App/                    # App entry point, AppDelegate, global state
├── Models/                 # SwiftData models
├── Views/                  # SwiftUI views
│   ├── MainWindow/         # Main window (sidebar, welcome screen)
│   ├── Import/             # Import interface & recording
│   ├── Transcription/      # Transcription results & audio player
│   ├── Translation/        # Translation interface
│   ├── Summary/            # Meeting summaries
│   ├── Export/             # Export settings
│   ├── TTS/                # Text-to-speech controls
│   └── Settings/           # Settings (General, API Keys, Tools, Templates, TTS, Storage)
├── ViewModels/             # View models (MVVM architecture)
├── Services/               # Service layer
│   ├── Whisper/            # WhisperKit wrapper & model management
│   ├── Audio/              # Recording (AVAudioRecorder) & audio playback
│   ├── Translation/        # Translation service implementations
│   ├── TTS/                # TTS service implementations
│   ├── Export/             # SRT / DOCX / Markdown / TXT exporters
│   ├── Summary/            # AI summary service
│   ├── YouTube/            # yt-dlp wrapper
│   └── Subprocess/         # General-purpose external process runner
├── Utilities/              # Extensions, Keychain helper, time formatters
└── Resources/              # App icon, summary templates, localized strings
```

## License

This is a private project.

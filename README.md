# MemoVoice

**[English](README_EN.md) | 繁體中文**

MemoVoice 是一款 macOS 原生語音轉文字應用程式，使用 [WhisperKit](https://github.com/argmaxinc/WhisperKit) 在本機進行語音辨識。所有語音處理皆在裝置上完成，無需上傳雲端，保護您的隱私。支援長時間音檔轉錄、AI 翻譯、會議摘要、語音朗讀、字幕匯出等完整工作流程。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License](https://img.shields.io/badge/License-Private-lightgrey)

## 功能特色

### 語音轉文字
- **WhisperKit 本機辨識** — 使用 Apple Neural Engine + GPU (Metal) + CPU 三重加速，所有處理皆在本機完成
- **多種模型選擇** — 從 Tiny (~75MB) 到 Large V3 (~2.9GB)，依需求平衡速度與準確度
  - Tiny (~75MB) — 最快速，適合即時場景
  - Base (~140MB) — 基礎品質
  - Small (~466MB) — 平衡速度與品質
  - Medium (~1.5GB) — 高品質
  - Large V3 (~2.9GB) — 最高精度
  - Large V3 Turbo (~1.6GB) — 推薦，精度接近 Large V3 但速度更快
- **VAD 智慧分段** — 使用語音活動偵測（Voice Activity Detection）自動分段，產生精確時間碼
- **多語言支援** — 繁體中文（預設）、簡體中文、英文、日文、韓文、法文、德文、西班牙文等 14 種語言
- **App 啟動預載模型** — 預設模型在 App 啟動時背景載入，開始轉錄無需等待
- **暫停 / 取消** — 轉錄過程中可隨時暫停或取消
- **並行處理** — 多核心並行解碼，充分利用硬體效能

### 音訊匯入
- **音檔匯入** — MP3、WAV、M4A、FLAC、AAC、OGG、AIFF、QTA
- **影片匯入** — MP4、MOV、MKV、AVI、WebM 等（透過 FFmpeg 自動擷取音軌）
- **YouTube 匯入** — 貼上 YouTube 網址，自動取得影片標題、下載音訊並轉錄（需安裝 yt-dlp）
- **錄音功能** — 內建錄音介面，錄製完成後直接進入轉錄流程
- **語音備忘錄整合** — 支援 macOS 語音備忘錄的 `.qta` (QuickTime Audio) 格式，可透過 Finder「打開方式」直接匯入
- **拖放匯入** — 將音訊或影片檔案拖入視窗即可匯入

### AI 翻譯
- **多服務提供者** — Claude CLI、OpenAI、Google Gemini、DeepSeek、OpenRouter
- **逐段翻譯** — 每個時間碼段落獨立翻譯，保留原文對照
- **雙欄顯示** — 原文與譯文並排顯示，方便比對

### 會議摘要
- **AI 摘要生成** — 使用 Claude CLI 或其他 AI 服務自動從轉錄內容生成結構化摘要
- **預設模板** — 會議紀錄、行動項目、站會報告等模板
- **自訂模板** — 可在設定中建立、編輯、管理自訂摘要模板
- **匯出摘要** — 支援 Markdown、純文字、Word 文件格式

### 語音朗讀 (TTS)
- **多 TTS 引擎** — 系統內建語音、Edge TTS、Fish Audio、MiniMax
- **朗讀原文或譯文** — 可選擇朗讀轉錄原文或翻譯後的內容

### 音訊播放器
- **內建播放器** — 播放 / 暫停、前進 / 後退 5 秒、拖曳進度條
- **可調速播放** — 0.5x ~ 2.0x 播放速度
- **時間碼同步** — 點擊段落即跳轉到對應時間播放，播放時自動高亮當前段落

### 匯出功能
- **SRT 字幕** — 標準 SRT 格式，可直接用於影片字幕軟體
- **Word 文件** — DOCX 格式，含時間碼、段落與翻譯
- **Markdown** — 含標題、時間碼、段落文字
- **純文字** — TXT 格式，可選擇是否包含時間碼

### 儲存空間管理
- **模型管理** — 個別下載或刪除 Whisper 模型
- **快取清理** — 在設定中檢視並清理擷取音訊、TTS 快取等暫存檔案

## 系統需求

| 項目 | 需求 |
|------|------|
| 作業系統 | macOS 14.0 (Sonoma) 或更新版本 |
| 處理器 | Apple Silicon (M1/M2/M3/M4) 建議使用，Intel Mac 亦可運行 |
| 記憶體 | 至少 8GB（使用 Large 模型建議 16GB+） |
| 磁碟空間 | 至少 500MB（含模型約 2GB+） |

## 安裝

### 方式一：下載安裝檔

前往 [Releases](https://github.com/ryanhuge/memovoice/releases) 下載最新版 `MemoVoice.zip`：

1. 下載並解壓縮 `MemoVoice.zip`
2. 將 `MemoVoice.app` 拖入「應用程式」資料夾
3. 首次開啟時，若出現「無法打開」提示，請至「系統設定 > 隱私與安全性」點選「仍要打開」
4. 首次啟動會自動下載預設語音辨識模型（Large V3 Turbo ~1.6GB），需等待下載完成

### 方式二：從原始碼建置

```bash
git clone https://github.com/ryanhuge/memovoice.git
cd memovoice
open MemoVoice.xcodeproj
```

在 Xcode 中選擇 `MemoVoice` scheme，按 `Cmd+R` 執行。

#### 建置 Release 並安裝

```bash
xcodebuild -scheme MemoVoice -configuration Release archive -archivePath /tmp/MemoVoice.xcarchive
cp -R /tmp/MemoVoice.xcarchive/Products/Applications/MemoVoice.app /Applications/
```

## 外部工具（選配）

以下工具為選配功能，透過 [Homebrew](https://brew.sh) 安裝：

| 工具 | 用途 | 安裝指令 |
|------|------|----------|
| [FFmpeg](https://ffmpeg.org) | 影片音軌擷取、音訊格式轉換 | `brew install ffmpeg` |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | YouTube 音訊下載 | `brew install yt-dlp` |
| [Claude CLI](https://github.com/anthropics/claude-code) | AI 翻譯與會議摘要 | `npm install -g @anthropic-ai/claude-code` |

可在 App 內「設定 > 工具路徑 (Tools)」中自訂路徑或一鍵安裝。

## 技術架構

| 項目 | 技術 |
|------|------|
| UI 框架 | SwiftUI |
| 語音辨識 | WhisperKit (CoreML / Neural Engine / Metal) |
| 資料儲存 | SwiftData |
| 音訊播放 | AVFoundation |
| 翻譯服務 | Claude CLI / OpenAI / Gemini / DeepSeek / OpenRouter |
| 語音合成 | 系統語音 / Edge TTS / Fish Audio / MiniMax |
| DOCX 匯出 | SwiftDocX |
| API Key 儲存 | Keychain |
| 本地化 | String Catalog (.xcstrings)，支援英文與繁體中文 |

## 專案結構

```
MemoVoice/
├── App/                    # 應用程式入口、AppDelegate、全域狀態
├── Models/                 # SwiftData 資料模型
├── Views/                  # SwiftUI 視圖
│   ├── MainWindow/         # 主視窗（側邊欄、歡迎畫面）
│   ├── Import/             # 匯入介面與錄音
│   ├── Transcription/      # 轉錄結果、音訊播放器
│   ├── Translation/        # 翻譯介面
│   ├── Summary/            # 會議摘要
│   ├── Export/             # 匯出設定
│   ├── TTS/                # 語音朗讀控制
│   └── Settings/           # 設定頁面（一般、API Keys、工具、模板、TTS、儲存空間）
├── ViewModels/             # 視圖模型（MVVM 架構）
├── Services/               # 服務層
│   ├── Whisper/            # WhisperKit 封裝、模型管理
│   ├── Audio/              # 錄音（AVAudioRecorder）、音訊播放
│   ├── Translation/        # 各翻譯服務實作
│   ├── TTS/                # 各 TTS 服務實作
│   ├── Export/             # SRT / DOCX / Markdown / TXT 匯出
│   ├── Summary/            # AI 摘要服務
│   ├── YouTube/            # yt-dlp 封裝
│   └── Subprocess/         # 通用外部程序執行器
├── Utilities/              # 擴充方法、Keychain、時間格式化
└── Resources/              # App 圖示、摘要模板、本地化字串
```

## 授權

本專案為私人專案。

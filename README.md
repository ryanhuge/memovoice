# MemoVoice

MemoVoice 是一款 macOS 原生語音轉文字應用程式，使用 [WhisperKit](https://github.com/argmaxinc/WhisperKit) 在本機進行語音辨識，支援長時間音檔轉錄、翻譯、會議摘要、字幕匯出等功能。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## 功能特色

### 語音轉文字
- **WhisperKit 本機辨識** — 使用 Apple Neural Engine / Metal 加速，所有處理皆在本機完成，無需上傳雲端
- **多種模型選擇** — Tiny (~75MB)、Base (~140MB)、Small (~466MB)、Large V3 Turbo (~1.6GB)
- **VAD 智慧分段** — 自動根據語音活動偵測進行分段，產生精確時間碼
- **多語言支援** — 支援繁體中文（預設）、簡體中文、英文、日文、韓文、法文、德文、西班牙文等 14 種語言

### 音訊匯入
- **音檔匯入** — 支援 MP3、WAV、M4A、FLAC、AAC、OGG、AIFF、QTA
- **影片匯入** — 支援 MP4、MOV、MKV 等影片格式（透過 FFmpeg 擷取音軌）
- **YouTube 匯入** — 貼上 YouTube 網址，自動下載並轉錄（需安裝 yt-dlp）
- **錄音功能** — 內建錄音介面，錄製後直接轉錄
- **語音備忘錄整合** — 支援 macOS 語音備忘錄的 .qta 格式，可透過「打開方式」直接匯入
- **拖放匯入** — 將音訊/影片檔案拖入視窗即可匯入

### AI 翻譯
- **多服務提供者** — Claude CLI、OpenAI、Google Gemini、DeepSeek、OpenRouter
- **逐段翻譯** — 每個時間碼段落獨立翻譯，保留原文對照
- **雙欄顯示** — 原文與譯文並排顯示

### 會議摘要
- **AI 摘要生成** — 使用 Claude CLI 或其他 AI 服務自動生成會議摘要
- **預設模板** — 會議紀錄、行動項目、站會報告等模板
- **自訂模板** — 可建立、編輯自訂摘要模板
- **匯出摘要** — 支援 Markdown、純文字、Word 文件格式

### 語音朗讀 (TTS)
- **多 TTS 引擎** — 系統內建語音、Edge TTS、Fish Audio、MiniMax
- **朗讀原文或譯文** — 可選擇朗讀轉錄原文或翻譯結果

### 音訊播放器
- **內建播放器** — 播放/暫停、快進快退 5 秒、拖曳進度條
- **可調速播放** — 0.5x ~ 2.0x 播放速度
- **時間碼同步** — 點擊段落即跳轉到對應位置播放，播放時高亮目前段落

### 匯出功能
- **SRT 字幕** — 標準 SRT 格式，可直接用於影片字幕
- **Word 文件** — DOCX 格式，含時間碼與段落
- **Markdown** — 含標題、時間碼、段落、摘要
- **純文字** — TXT 格式，可選擇是否包含時間碼

## 系統需求

- macOS 14.0 (Sonoma) 或更新版本
- Apple Silicon (M1/M2/M3/M4) 建議使用，Intel Mac 亦可
- 至少 8GB RAM（使用 Large 模型建議 16GB+）

## 安裝

### 從原始碼建置

```bash
git clone https://github.com/ryanhuge/memovoice.git
cd memovoice
open MemoVoice.xcodeproj
```

在 Xcode 中選擇 `MemoVoice` scheme，按 `Cmd+R` 執行。

### 安裝到應用程式

```bash
xcodebuild -scheme MemoVoice -configuration Release archive -archivePath /tmp/MemoVoice.xcarchive
cp -R /tmp/MemoVoice.xcarchive/Products/Applications/MemoVoice.app /Applications/
```

## 外部工具（選配）

以下工具為選配，透過 Homebrew 安裝：

| 工具 | 用途 | 安裝指令 |
|------|------|----------|
| FFmpeg | 影片音軌擷取 | `brew install ffmpeg` |
| yt-dlp | YouTube 下載 | `brew install yt-dlp` |
| Claude CLI | AI 翻譯與摘要 | `npm install -g @anthropic-ai/claude-code` |

可在「設定 > 工具路徑」中自訂路徑或一鍵安裝。

## 技術架構

| 項目 | 技術 |
|------|------|
| UI 框架 | SwiftUI |
| 語音辨識 | WhisperKit (CoreML / Neural Engine) |
| 資料儲存 | SwiftData |
| 音訊播放 | AVFoundation |
| 翻譯 | Claude CLI / OpenAI / Gemini / DeepSeek / OpenRouter |
| TTS | 系統語音 / Edge TTS / Fish Audio / MiniMax |
| DOCX 匯出 | SwiftDocX |
| API Key 儲存 | KeychainAccess |

## 專案結構

```
MemoVoice/
├── App/                    # 應用程式入口與全域狀態
├── Models/                 # SwiftData 模型
├── Views/                  # SwiftUI 視圖
│   ├── MainWindow/         # 主視窗（側邊欄、歡迎畫面）
│   ├── Import/             # 匯入與錄音
│   ├── Transcription/      # 轉錄結果顯示與播放器
│   ├── Translation/        # 翻譯介面
│   ├── Summary/            # 會議摘要
│   ├── Export/             # 匯出
│   ├── TTS/                # 語音朗讀
│   └── Settings/           # 設定頁面
├── ViewModels/             # 視圖模型
├── Services/               # 服務層
│   ├── Whisper/            # WhisperKit 封裝與模型管理
│   ├── Audio/              # 錄音與播放服務
│   ├── Translation/        # 各翻譯服務實作
│   ├── TTS/                # 各 TTS 服務實作
│   ├── Export/             # 匯出格式處理
│   ├── Summary/            # AI 摘要服務
│   ├── YouTube/            # yt-dlp 封裝
│   └── Subprocess/         # 通用子程序執行
├── Utilities/              # 工具類別與擴充
└── Resources/              # 資源檔（圖示、模板、本地化）
```

## 授權

本專案為私人專案。

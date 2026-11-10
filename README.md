# 🛠️ Advanced-Root-Toolkit (進階 ROOT 軍火庫)

🚀 **The ultimate interactive terminal control panel & asset repository tailormade for Android power users, kernel adjusters, and root environment developers.**  
🚀 **專為 Android 進階玩家、內核調校開發者打造的互動式終端控制台與自動化防線軍火庫。**

---

## 🌟 Overview / 專案簡介

`Advanced-Root-Toolkit` 是一個集成了歷史、主流與最前沿 Android 玩機工具鏈的開源資產庫。本專案核心由長達數千行的核心指令腳本 `cmd.sh` 動態驅動，提供全自動目錄嗅探、全平台基帶字庫生命線備份、深層安全環境審查以及一鍵式無痕防檢測部署。

---

## 🔥 Core Features / 核心功能

### 🖥️ 1. Interactive Terminal Control Panel (`cmd.sh`) / 互動式終端控制箱
* **Dynamic Group Sniffing (動態分組面板):** Automatically scans the target directory structure and high-lights root factions (Magisk Alpha/KSU/APatch), utility suites, and detection indicators.
  自動掃描目錄架構，高亮顯示各大面具陣營、搞機工具與檢測軟體。
* **One-Click Silent Deployment (一鍵/單獨安裝):** Implements hyper-efficient static transfer installation loops to upgrade specific apps or instantly deploy a clean verification environment.
  整合高效中轉靜默部署邏輯，可單獨編號升級或一鍵批量初始化完整測試環境。
* **Partition Lifeline Safeguard (分區生命線):** Built-in high-risk partition flashing logic (`dd` short-cuts) for Snapdragon (Qualcomm) & Dimensity (MTK) basebands, NVRAM, and persist partitions.
  內置高通與聯發科雙平台基帶、字庫、Persist 分區的一鍵備份與還原指令小抄。

### 🛡️ 2. Micro-Kernel & Security Audit (`run_security_scans`) / 內核級綜合安全檢測
* **Oppo/OnePlus Inte.ko Detection (歐加反作弊檢測):** Live-audits active anti-cheat kernel drivers (`/proc/inte_ko`) to evaluate environment exposure risks.
  實時動態檢測歐加系內置驅動級內核反作弊模組的加載狀態與通訊邊界。
* **DeviceHub RAT IOC Scanner (遠控木馬深檢):** Multi-dimensional checks involving process regex matching (`pgrep`), executable SHA-256 validation, environment array auditing, and `127.0.0.1:8080` back-door intercept.
  針對高危遠控木馬進行跨 PID 進程特徵匹配、二進制 SHA-256 比對及回環後門精準防禦。

### 🌀 3. Advanced Hook & Sandbox Telemetry / 高階大師環境嗅探
* **Zygisk Next Tracker:** Telemeters active states of `zn-daemon` vs. legacy zygote hook components.
  實時追蹤 Zygisk Next 注入守護進程，精準判定環境隱蔽級別。
* **Seccomp Sandbox Telemetry:** Parses `/proc/$$/status` filter parameters to isolate running scripts from Android process sandbox vectors.
  解析進程過濾指標，動態判定當前 Shell 執行權限是否受到 Seccomp 沙盒沙盒化干預。

---

## 📦 Asset Arsenal Ledger / 軍火庫清單

| Category / 分類 | Volume / 數量 | Highlighted Assets / 亮點資產 |
| :--- | :--- | :--- |
| **ROOT Managers** | 20+ Factions | Magisk Alpha, KernelSU, SukiSU Ultra (19 Derivatives), APatch (FolkPatch), SKroot / SKroot Pro. |
| **Power Utilities** | 48 Advanced Tools | GG Modifier, HyperIsland, Shizuku Mod, FolkPure, Moonbow Helper, GhostLock, Arsenal-Box. |
| **Core Modules** | 28 Essential Items | Zygisk Next, LSPosed, HMA-OSS, Tricky Store, Target Hide-Root Adjusters. |
| **Integrity Checks** | 18 Verification Apps | Momo, Ruru, Hunter, Duck Detector, Play Integrity API Checker, MemoryDetector, Holmes. |

---

## ⚡ Quick Start / 快速啟動

### Prerequisites / 執行環境
* An Android device with active `UID=0` (Full Root Access) via **KernelSU / SukiSU / APatch / Magisk**.
  已獲取全域超級用戶權限（UID=0）的 Android 設備。
* A modern terminal environment (e.g., **Termux** or **ADB Shell**).
  配置完成的本機 Termux 終端或電腦端 ADB Shell 控制台。

### Execution / 腳本運行
```bash
# Enter superuser environment / 進入超級用戶權限
su

# Navigate to your download folder & launch / 進入下載路徑並執行
cd /storage/emulated/0/Download/Root_Collection_All
sh cmd.sh
```

---

## ⚠️ Disclaimer / 免責聲明

1. **High-Risk Operations (高風險操作):** The scripts and assets contained herein involve Android system-level kernel modifications, partition overrides (`dd` commands), and security bypasses.
   本倉庫內置工具及腳本皆涉及 Android 系統底層核心修改、分區讀寫等高風險操作。
2. **No Liability (概不負責):** The maintainer holds **NO responsibility** for any hardware damage, infinity bootloops, data loss, or missing IMEI/baseband states. Use with extreme caution.
   因使用本倉庫工具導致的任何硬體損壞、無限重啟（Bootloop）、數據丟失或基帶未知，作者概不負責。
3. **Backup First (備份第一):** Remember the golden rule of Android modding: **Backup your data before any flash attempt.**
   刷機千萬條，備份第一條。操作前請務必確保已備份重要數據。

---

## 👥 Developers & Community / 開發與社群
* **Core Contributor (核心開發者):** 抖音 user哥 (TikTok user_Bro)
* **GitHub Repository:** [hx358273-a11y/Advanced-Root-Toolkit](https://github.com)
* Give a ⭐️ if this toolkit helped your Android development pipeline! 
  如果這個控制台幫到了你的搞機之路，歡迎點擊右上角 **Star** 支持！

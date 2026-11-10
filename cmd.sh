#!/system/bin/sh

# =======================================================
#               Top Root Arsenal - Interactive Panel
#               開發者：抖音user哥 (TikTok user_Bro)
# =======================================================

# 智慧動態路徑嗅探
if [ -d "/storage/emulated/0" ]; then
    INTERNAL_STORAGE="/storage/emulated/0"
elif [ -d "/sdcard" ]; then
    INTERNAL_STORAGE="/sdcard"
else
    INTERNAL_STORAGE="/mnt/sdcard"
fi

# 基礎絕對路徑定案
BASE_DIR="${INTERNAL_STORAGE}/Download/Root_Collection_All"

# 暫存目錄：優先使用 Android shell 暫存區；非 Root/Termux 環境則回退到 TMPDIR。
TEMP_DIR="/data/local/tmp"
if [ ! -d "$TEMP_DIR" ] || [ ! -w "$TEMP_DIR" ]; then
    if [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ] && [ -w "$TMPDIR" ]; then
        TEMP_DIR="$TMPDIR"
    else
        TEMP_DIR="${INTERNAL_STORAGE}/Download"
    fi
fi

# 顏色定義
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
PURPLE='\e[1;35m'
CYAN='\e[1;36m'
NC='\e[0m'

# 檢測 Android 現代核心架構與分區指標
check_android_architecture_status() {
    # 1. Project Treble & VNDK 檢測
    local TREBLE_EN=$(getprop ro.treble.enabled 2>/dev/null)
    local VNDK_VER=$(getprop ro.vndk.version 2>/dev/null)
    local TREBLE_STR="${RED}未支援Project Treble${NC}"
    if [ "$TREBLE_EN" = "true" ]; then
        if [ -n "$VNDK_VER" ]; then
            TREBLE_STR="${GREEN}支援Project Treble (VNDK ${VNDK_VER})${NC}"
        else
            TREBLE_STR="${GREEN}支援Project Treble${NC}"
        fi
    fi

    # 2. A/B 無縫更新與當前 Slot 檢測
    local SLOT_SUFFIX=$(getprop ro.boot.slot_suffix 2>/dev/null)
    local AB_STR="${RED}未支援 (傳統單分區)${NC}"
    if [ -n "$SLOT_SUFFIX" ]; then
        # 去除底線，讓顯示更美觀 (例如 _a 變成 A)
        local CLEAN_SLOT=$(echo "$SLOT_SUFFIX" | tr -d '_' | tr '[:lower:]' '[:upper:]')
        AB_STR="${GREEN}支援 (當前正運行於 Slot_${CLEAN_SLOT} 分區)${NC}"
    fi

    # 3. CPU 架構與類型檢測
    local CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null)
    local CPU_STR="${YELLOW}${CPU_ABI}${NC}"
    if [ "$CPU_ABI" = "arm64-v8a" ]; then
        CPU_STR="${GREEN}64-bit ARM (arm64-v8a)${NC}"
    elif [ "$CPU_ABI" = "armeabi-v7a" ]; then
        CPU_STR="${YELLOW}32-bit ARM (armeabi-v7a)${NC}"
    fi

    # 4. System-as-root (SAR) 檢測
    local SAR_EN=$(getprop ro.build.system_root_image 2>/dev/null)
    local SAR_STR="${RED}未支援${NC}"
    # 僅用明確屬性或 A/B slot 作為線索；不能只憑 SDK 版本斷言 SAR。
    if [ "$SAR_EN" = "true" ]; then
        SAR_STR="${GREEN}屬性回報支援${NC}"
    elif [ -n "$SLOT_SUFFIX" ]; then
        SAR_STR="${YELLOW}疑似支援 (A/B slot 線索，未直接驗證)${NC}"
    else
        SAR_STR="${YELLOW}無法確認 (屬性未提供)${NC}"
    fi

    # ==================== 科技感高亮輸出 ====================
    echo -e "${CYAN}[系統資訊] Project Treble: ${TREBLE_STR}"
    echo -e "${CYAN}[系統資訊] 無縫系統更新: ${AB_STR}"
    echo -e "${CYAN}[系統資訊] CPU 核心架構: ${CPU_STR}"
    echo -e "${CYAN}[系統資訊] System-as-root: ${SAR_STR}"
}

# SELinux 狀態檢測與自動修復
check_selinux() {
    local STATUS
    # 檢查是否擁有 Root 權限
    if [ "$(id -u 2>/dev/null)" != 0 ]; then
        echo -e "${YELLOW}[提示] 非 Root 執行；部分狀態可能無法讀取與修改。${NC}"
    fi

    STATUS=$(getenforce 2>/dev/null)
    [ -n "$STATUS" ] || STATUS="未知"
    
    echo -e "${CYAN}[系統狀態] 目前 SELinux 狀態為：${YELLOW}$STATUS${NC}"

    # 如果狀態是 Permissive（寬容），則自動修正為 Enforcing（強制）
    if [ "$STATUS" = "Permissive" ]; then
        echo -e "${YELLOW}[自動修復] 檢測到寬容模式，正在嘗試修正為強制模式...${NC}"
        if setenforce 1 2>/dev/null; then
            # 重新確認修改後的狀態
            NEW_STATUS=$(getenforce 2>/dev/null)
            echo -e "${GREEN}[修復成功] SELinux 已成功切換為：${YELLOW}$NEW_STATUS${NC}"
        else
            echo -e "${RED}[修復失敗] 無法寫入設定，請檢查是否擁有足夠的 Root 權限。${NC}"
        fi
    elif [ "$STATUS" = "Enforcing" ]; then
        echo -e "${GREEN}[核心狀態] SELinux 已處於強制模式，無需修改。${NC}"
    else
        echo -e "${RED}[核心狀態] SELinux 處於未知或已停用 (Disabled) 狀態，無法直接切換。${NC}"
    fi
}

# Zygisk Next (zn-daemon) 進程狀態即時監測
check_zygisk_status() {
    if pgrep -f "zn-daemon" >/dev/null 2>&1; then
        echo -e "${GREEN}[核心狀態] Zygisk Next (zn-daemon) 已成功注入執行中！${NC}"
    elif pgrep -f "zygisk" >/dev/null 2>&1; then
        echo -e "${YELLOW}[核心狀態] 偵測到舊版 Zygisk 守護進程。${NC}"
    else
        echo -e "${RED}[核心狀態] 未偵測到 Zygisk 環境（可能需要重啟或處於非隱蔽狀態）${NC}"
    fi
}

# 1. 檢測設備型號
check_device_model() {
    # 獲取市場行銷名稱（例如 Xiaomi 15T），若無則抓取內部代號
    local MODEL=$(getprop ro.product.marketname 2>/dev/null)
    [ -z "$MODEL" ] && MODEL=$(getprop ro.product.model 2>/dev/null)
    [ -z "$MODEL" ] && MODEL="未知設備"

    echo -e "${CYAN}[設備資訊] 設備型號為: ${YELLOW}$MODEL${NC}"
}

# 2. 檢測內核版本
check_kernel_version() {
    # 獲取簡短的核心版本號（例如 6.6.118）
    local KERNEL_SHORT=$(uname -r 2>/dev/null)
    if [ -n "$KERNEL_SHORT" ]; then
        echo -e "${CYAN}[系統資訊] 內核版本為: ${YELLOW}$KERNEL_SHORT${NC}"

    else
        echo -e "${RED}[系統資訊] 無法獲取內核版本${NC}"
    fi
}

# 交叉檢測 Bootloader 軟硬體真實狀態
# 檢測 Bootloader 鎖狀態（聚焦軟體與模組對抗）
check_bl_integrity_status() {
    local PROP_LOCK=$(getprop ro.boot.flash.locked 2>/dev/null)

    if [ "$PROP_LOCK" = "1" ]; then
        # ro.boot.flash.locked 只代表系統回報值，不能單靠 Root 狀態推斷 Tricky Store。
        if [ "$(id -u 2>/dev/null)" = "0" ] || { command -v su >/dev/null 2>&1 && su -c "id" >/dev/null 2>&1; }; then
            echo -e "${PURPLE}[核心狀態] BL 回報狀態: 鎖定 (目前可取得 Root；此結果不能證明 BL 真實狀態)${NC}"
        else
            echo -e "${GREEN}[核心狀態] BL 回報狀態: 鎖定 (僅代表系統屬性回報值)${NC}"
        fi
    elif [ "$PROP_LOCK" = "0" ]; then
        echo -e "${YELLOW}[核心狀態] BL 認證狀態: 軟體[解鎖] (常規解鎖環境)${NC}"
    else
        echo -e "${RED}[核心狀態] BL 認證狀態: 軟體[未知狀態]${NC}"
    fi
}

# 檢測 Xposed 框架環境 (LSPosed / Vector)
check_xposed_framework() {
    # 1. 狀況一：沒有 Root 權限，無法讀取 /data/adb
    if ! command -v su >/dev/null 2>&1; then
        echo -e "${RED}[核心狀態] 未檢測到 Xposed 框架 (無 ROOT 權限，無法掃描環境)${NC}"
        return
    fi

    # 2. 狀況二：有 Root 權限，精準掃描是否有 lspd 守護進程資料夾
    if su -c "[ -d /data/adb/lspd ]" >/dev/null 2>&1; then
        echo -e "${GREEN}[核心狀態] 檢測到 Xposed 框架 (LSPosed / Vector)${NC}"
    
    # 3. 狀況三：有 Root 權限，但未發現特徵資料夾
    else
        echo -e "${YELLOW}[核心狀態] 未檢測到 Xposed 框架環境${NC}"
    fi
}

# 檢測超級用戶權限狀態
check_su_permission() {
    local CURRENT_UID
    CURRENT_UID=$(id -u 2>/dev/null)

    # 1. 狀況一：UID=0，代表已經完全進入 Root 環境
    if [ "$CURRENT_UID" = "0" ]; then
        echo -e "${GREEN}[核心狀態] 超級用戶權限: 已完全接管 (全域 Root, UID=0)${NC}"
        return
    fi

    # 2. 狀況二：UID 不為 0，但系統有 su 指令，嘗試進行動態提權檢測
    if command -v su >/dev/null 2>&1; then
        if su -c "id" >/dev/null 2>&1; then
            echo -e "${GREEN}[核心狀態] 超級用戶權限: 已成功授予 (Shell 動態提權)${NC}"
            return
        fi
    fi

    # 觸發非 Root 方案：開始精準判定 UID 並進行警告 
    
    # 狀況三：UID=2000，代表目前僅持有 ADB / Shizuku 的 Shell 權限
    if [ "$CURRENT_UID" = "2000" ]; then
        echo -e "${YELLOW}[核心狀態] 超級用戶權限: 僅獲取到 Shell 權限 (UID=2000)${NC}"
        echo -e "${RED}[警告] ⚠️ 未獲取完整 ROOT 權限，安裝等核心功能將無法使用！${NC}"
    
    # 狀況四：UID>=10000，代表只是普通 App 權限，或者完全沒有 Root 方案
    elif [ -n "$CURRENT_UID" ] && [ "$CURRENT_UID" -ge 10000 ] 2>/dev/null; then
        echo -e "${RED}[核心狀態] 超級用戶權限: 普通應用權限 (UID=$CURRENT_UID, 非 ROOT 方案)${NC}"
        echo -e "${RED}[警告] ⚠️ 未獲取完整 ROOT 權限，有些功能可能沒法使用！${NC}"
    
    # 保底狀況：防禦性未知權限
    else
        echo -e "${RED}[核心狀態] 超級用戶權限: 未授權或未知權限環境${NC}"
        echo -e "${RED}[警告] ⚠️ 未獲取完整 ROOT 權限，有些功能可能沒法使用！${NC}"
    fi
}

#檢測 ROOT 方案 
check_root_solution() {
    # 如果完全沒有 root 權限，直接判定為無 root
    if ! command -v su >/dev/null 2>&1; then
        echo -e "${RED}[核心狀態] ROOT 方案為: 無 ROOT 環境${NC}"
        return
    fi

    # 透過 su -c 權限去偵測 /data/adb 內部的關鍵特徵與古董特徵
    if su -c "[ -f /data/adb/ksud ]" >/dev/null 2>&1; then
        echo -e "${GREEN}[核心狀態] ROOT 方案為: KernelSU / SukiSU 分支${NC}"
        
    elif su -c "[ -f /data/adb/apd ]" >/dev/null 2>&1; then
        echo -e "${YELLOW}[核心狀態] ROOT 方案為: APatch 方案${NC}"
        
    elif su -c "[ -f /data/adb/magisk.db ]" >/dev/null 2>&1; then
        echo -e "${YELLOW}[核心狀態] ROOT 方案為: 傳統阿爾法面具 (Magisk Alpha)${NC}"
        
    # 古董級 KingRoot 特徵檢測：通常會在 /data/data/ 或系統內留下 kinguser 或 k_daemon
    elif su -c "[ -d /data/data/com.kingroot.kinguser ] || [ -f /system/bin/rt-root ] || [ -f /system/xbin/ku.sud ]" >/dev/null 2>&1; then
        echo -e "${RED}[核心狀態] ROOT 方案為: 古董級 KingRoot 方案${NC}"
        
    else
        # 四大特徵皆無的未知 Root
        echo -e "${RED}[核心狀態] ROOT 方案為: 未知自訂超級用戶環境${NC}"
    fi
}

#檢測鉤子類型
check_hook_type() {
    # 如果完全沒有 root 權限
    if ! command -v su >/dev/null 2>&1; then
        echo -e "${RED}[核心狀態] 未檢測到hook類型（可能為內聯鉤子或是無root）${NC}"
        return
    fi

    local IS_KSU=""
    local IS_SUSFS=""
    local IS_APATCH=""
    local IS_MAGISK=""

    # 收集核心檔案特徵
    if su -c "[ -f /data/adb/ksud ]" >/dev/null 2>&1; then
        IS_KSU="true"
    fi
    if su -c "[ -d /data/adb/modules/susfs4ksu ] || [ -d /data/adb/susfs ]" >/dev/null 2>&1; then
        IS_SUSFS="true"
    fi
    if su -c "[ -f /data/adb/apd ]" >/dev/null 2>&1; then
        IS_APATCH="true"
    fi
    if su -c "[ -f /data/adb/magisk.db ]" >/dev/null 2>&1; then
        IS_MAGISK="true"
    fi

    # Root 管理器檔案只能辨識方案家族，不能據此判定核心 Hook 技術。
    # 結合嚴謹性與玩機爽感的完全體輸出
    if [ "$IS_KSU" = "true" ] && [ "$IS_SUSFS" = "true" ]; then
        echo -e "${GREEN}[核心狀態] 鉤子類型/特徵: SuSFS 2.3.0鉤子技術(偵測到 kernelSU+SUSFS)${NC}"
    elif [ "$IS_KSU" = "true" ]; then
        echo -e "${GREEN}[核心狀態] 鉤子類型/特徵:Tracepoint Syscall Redirect 重定向鉤子技術(基於系統特徵推測)${NC}"
    elif [ "$IS_APATCH" = "true" ]; then
        echo -e "${YELLOW}[核心狀態] 鉤子類型/特徵: 核心級 KP (KernelPatch) 內聯 Hook (基於系統特徵推測)${NC}"
    elif [ "$IS_MAGISK" = "true" ]; then
        echo -e "${YELLOW}[核心狀態] 鉤子類型/特徵: 傳統 Magisk 內置 ptrace/Zygote Hook (基於系統特徵推測)${NC}"
    else
        echo -e "${YELLOW}[核心狀態] 鉤子類型/特徵: 未匹配已知管理器標記 (暫定為未知 Hook 類型)${NC}"
    fi
}

#Seccomp状态检测
check_seccomp() {
    local SECCOMP_STATUS
    SECCOMP_STATUS=$(awk '/^Seccomp:/ {print $2; exit}' "/proc/$$/status" 2>/dev/null)

    if [ "$SECCOMP_STATUS" = "2" ]; then
        echo -e "${GREEN}[核心狀態] 目前腳本進程 Seccomp: Filter (2)過濾器模式（此腳本將受到Seccomp影響，但大部分功能暫時可用）${NC}"
    elif [ "$SECCOMP_STATUS" = "1" ]; then
        echo -e "${YELLOW}[核心狀態] 目前腳本進程 Seccomp: Strict (1)嚴格模式（此進程將受到Seccomp過濾影響，只能呼叫 read、write、_exit 和 sigreturn 這些函數）${NC}"
    elif [ "$SECCOMP_STATUS" = "0" ]; then
        echo -e "${YELLOW}[核心狀態] 目前腳本進程 Seccomp: Disabled (0)完全未啟用過濾(此腳本進程不會找受Seccomp的沙盒影響）${NC}"
    else
        echo -e "${RED}[核心狀態] 無法讀取目前腳本進程的 Seccomp 狀態${NC}"
    fi
}

show_header() {
    # 僅顯示標題；子選單呼叫時不重複執行裝置檢測。
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${GREEN}                頂級搞機軍火庫 (互動面板)        ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "開發者：抖音user哥"
    echo ""
}

show_system_status() {
    # 僅由 1-12 主選單呼叫，其他子頁面不執行這些檢測。
    check_kernel_version
    check_device_model
    check_bl_integrity_status
    check_android_architecture_status
    check_selinux
    check_seccomp
    check_su_permission
    check_root_solution
    check_zygisk_status
    check_xposed_framework
    check_hook_type
    echo ""
}

# 掃描與安裝核心函數
scan_and_install() (
    local sub_folder="$1"
    local target_path=""

    if echo "$sub_folder" | grep -q "^/"; then
        target_path="$sub_folder"
    else
        target_path="$BASE_DIR/$sub_folder"
    fi

    show_header
    echo -e "${PURPLE}=== 當前分組：$(basename "$target_path") ===${NC}"
    echo -e "正在掃描目錄: $target_path"
    echo ""

    if [ ! -d "$target_path" ]; then
        echo -e "${RED}錯誤: 找不到該資料夾！請檢查路徑。${NC}"
        echo -e "預期路徑為: $target_path"
        echo "-------------------------------------------------"
        echo -n "按任意鍵返回..."
        read -n 1
        return
    fi

    cd "$target_path" || return

    local has_apk=0
    for file in *.apk; do
        if [ -f "$file" ]; then has_apk=1; break; fi
    done

    if [ "$has_apk" -eq 0 ]; then
        echo -e "${YELLOW} 提示：該資料夾內目前沒有發現任何 APK 安裝包。${NC}"
        echo "-------------------------------------------------"
        echo -n "按任意鍵返回..."
        read -n 1
        return
    fi

    echo -e "${CYAN}可用的 APK 檔案列表：${NC}"
    local count=1
    for file in *.apk; do
        [ -f "$file" ] || continue
        echo -e "  [ ${YELLOW}$count${NC} ] $file"
        count=$((count + 1))
    done

    echo "-------------------------------------------------"
    echo -e "輸入 [ ${YELLOW}數字${NC} ] 單獨安裝該編號的 APK"
    echo -e "輸入 [ ${YELLOW}all${NC}  ] 一鍵批量安裝此分組下的所有 APK"
    echo -e "輸入 [ ${YELLOW}0${NC}    ] 返回上級選單"
    echo "-------------------------------------------------"
    echo -n "請輸入指令: "
    read apk_choice
    apk_choice=$(echo "$apk_choice" | tr -d '\r\n\t ')

    case "$apk_choice" in
        0|"")
            return
            ;;
        all)
            echo -e "${YELLOW}\n 開始一鍵中轉靜默部署所有工具...${NC}"
            for apk in *.apk; do
                [ -e "$apk" ] || continue
                echo -ne "正在傳輸並部署: $apk ... "
                install_tmp="/data/local/tmp/root_collection_install_$$_${count}.apk"
                if ! cp "$apk" "$install_tmp"; then
                    echo -e "[ ${RED}失敗：無法複製 APK${NC} ]"
                    continue
                fi
                chmod 600 "$install_tmp" 2>/dev/null
                if pm install -r "$install_tmp"; then
                    echo -e "[ ${GREEN}成功${NC} ]"
                else
                    echo -e "[ ${RED}失敗：請檢查簽名、版本或安裝權限${NC} ]"
                fi
                rm -f "$install_tmp"
                count=$((count + 1))
            done
            echo -e "${GREEN}\n 該分組流程執行完畢！${NC}"
            echo -n "按任意鍵返回..."
            read -n 1
            ;;
        [1-9]|[1-9][0-9]|[1-9][0-9][0-9])
            local match_count=1
            local target_apk=""
            for apk in *.apk; do
                [ -f "$apk" ] || continue
                if [ "$match_count" -eq "$apk_choice" ]; then target_apk="$apk"; break; fi
                match_count=$((match_count + 1))
            done

            if [ -n "$target_apk" ]; then
                echo -e "${YELLOW}\n 正在中轉單獨安裝: $target_apk ...${NC}"
                install_tmp="/data/local/tmp/root_collection_install_$$_single.apk"
                if ! cp "$target_apk" "$install_tmp"; then
                    echo -e "${RED} [失敗] 無法複製 APK 到暫存目錄。${NC}"
                else
                    chmod 600 "$install_tmp" 2>/dev/null
                    if pm install -r "$install_tmp"; then
                        echo -e "${GREEN} [成功] 安裝流程執行完畢！${NC}"
                    else
                        echo -e "${RED} [失敗] 安裝終止，請檢查簽名、版本或安裝權限。${NC}"
                    fi
                    rm -f "$install_tmp"
                fi
            else
                echo -e "${RED}錯誤: 找不到該編號對應的 APK！${NC}"
                sleep 1.5
            fi
            echo "-------------------------------------------------"
            echo -n "按任意鍵返回..."
            read -n 1
            ;;
        *)
            echo -e "${RED}輸入錯誤，請重新輸入！${NC}"
            sleep 1
            ;;
    esac
)

# 隱藏模組與 TEE 專用分流選單
hide_modules_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}[ 隱藏/防檢測模組專區 ]${NC}"
        echo -e " 1)  進入：隱藏模組主目錄 (Hide Root Modules)"
        echo -e " 2)  進入：輔助 TEE 專區 (Auxiliary TEE)"
        echo -e " 0)  返回上級選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-2): "
        read hide_choice
        hide_choice=$(echo "$hide_choice" | tr -d '\r\n\t ')

        case "$hide_choice" in
            0|"") break ;;
            1) scan_and_install "Magisk_Ksu_Modules/Hide Root Modules/" ;;
            2) scan_and_install "Magisk_Ksu_Modules/Hide Root Modules/Auxiliary TEE/" ;;
            *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
        esac
    done
}

# 高階玩機模組二級選單
advanced_modules_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}[ 請選擇高階 Magisk / KSU 模組分類 ]${NC}"
        echo -e " 1)  去廣告模組 (Ad-Blocker Module)"
        echo -e " 2)  去除一加 Inte 反作弊 (Auto-Uninstall OnePlus)"
        echo -e " 3)  救磚/防重啟模組 (Bootloop Rescue Modules)"
        echo -e " 4)  進入：隱藏防檢測分流選單 (含輔助 TEE)"
        echo -e " 5)  越獄模組專區 (Jailbreak Modules)"
        echo -e " 6)  核心框架模組 (LSPosed Modules)"
        echo -e " 7)  元模組/核心依賴 (Meta Modules)"
        echo -e " 8)  一鍵安裝檢測軟體 (One-Click Installer)"
        echo -e " 9)  系統優化模塊 (Tweaks Modules)"
        echo -e " 0)  返回主選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-9): "
        read mod_choice
        mod_choice=$(echo "$mod_choice" | tr -d '\r\n\t ')

        case "$mod_choice" in
            0|"") break ;;
            1) scan_and_install "Magisk_Ksu_Modules/Ad-Blocker Module (via Xposed,Hook)/" ;;
            2) scan_and_install "Magisk_Ksu_Modules/Auto-Uninstall OnePlus Integrity Check Kernel Module on Boot/" ;;
            3) scan_and_install "Magisk_Ksu_Modules/Bootloop Rescue Modules/" ;;
            4) hide_modules_menu ;;
            5) scan_and_install "Magisk_Ksu_Modules/Jailbreak Modules/" ;;
            6) scan_and_install "Magisk_Ksu_Modules/LSPosed Modules/" ;;
            7) scan_and_install "Magisk_Ksu_Modules/Meta Modules/" ;;
            8) scan_and_install "Magisk_Ksu_Modules/One-Click Installer & Checker/" ;;
            9) scan_and_install "Magisk_Ksu_Modules/Tweaks Modules/" ;;
            *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
        esac
    done
}

# 獨立玩機大師工具箱選單
root_tools_pack_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}[ 請選擇 Root_Tools_Pack 大師工具箱分類 ]${NC}"
        echo -e " 1)  進入：小米澎湃專區 (HyperOS Zone)"
        echo -e " 2)  進入：越獄核心集散地 (Jailbreak Hub)"
        echo -e " 3)  進入：好用必備的 LSP 模組 (Must-Have LSPosed Modules)"
        echo -e " 4)  進入：硬核玩機高權限軟體 (Root-Required Apps)"
        echo -e " 5)  進入：Shizuku 免 Root 權限大師專區 (Shizuku & Root Power Users)"
        echo -e " 0)  返回主選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-5): "
        read tool_pack_choice
        tool_pack_choice=$(echo "$tool_pack_choice" | tr -d '\r\n\t ')

        case "$tool_pack_choice" in
            0|"") break ;;
            1) scan_and_install "Root_Tools_Pack/HyperOS Zone/" ;;
            2) scan_and_install "Root_Tools_Pack/Jailbreak Hub/" ;;
            3) scan_and_install "Root_Tools_Pack/Must-Have LSPosed Modules/" ;;
        4) scan_and_install "Root_Tools_Pack/Root-Required Apps/" ;;
        5) scan_and_install "Root_Tools_Pack/Shizuku & Root Power Users Zone/" ;;
        *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
    esac
    done
}

# =================================================================
# 三級選單：KernelSU 家族深度管理 (利用短變數防範長路徑超出邊框)
# =================================================================
kernelsu_family_menu() {
    local R="Root_Managers_All/KernelSU_Series"
    while true; do
        show_header
        echo -e "${PURPLE}=== [KernelSU 家族硬核專區] ===${NC}"
        echo -e " 1)  防查管理器 (Anti-Detection Manager)"
        echo -e " 2)  爆改版Ksu (KernelSU Heavily Modded)"
        echo -e " 3)  網頁版Ksu (KernelSU WebUI)"
        echo -e " 4)  進入：KernelSU-Next 專區"
        echo -e " 5)  Ksu越獄專區 (Ksu Jailbreak)"
        echo -e " 6)  MizuSU 核心"
        echo -e " 7)  ReSukiSU (已改名為BakaSU)"
        echo -e " 8)  SukiSU Ultra"
        echo -e " 9)  進入：Wild_KSU 專區"
        echo -e " 10) ZySU 專區 (⚠️不支援 4.x & 5.x 內核)"
        echo -e " 11) FinaSU"
        echo -e " 12) Dafeiyu_KSU"
        echo -e " 13) 直達 KernelSU 基礎主目錄"
        echo -e " 0)  返回上級選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-13): "
        read ksu_choice
        ksu_choice=$(echo "$ksu_choice" | tr -d '\r\n\t ')

        case "$ksu_choice" in
            0|"") break ;;
            1) scan_and_install "$R/Anti-Detection Manager/" ;;
            2) scan_and_install "$R/KernelSU Heavily Modded/" ;;
            3) scan_and_install "$R/KernelSU WebUI/" ;;
            4)         
            while true; do
            show_header
            echo -e "${BLUE}>> KernelSU-Next 面具選單${NC}"
            echo -e "  1) 進入標準版"
            echo -e "  2) 進入偽裝版"
            echo -e "  0) 返回 KSU 選單"
            echo "-------------------------------------"

            echo -ne "請選擇："
            read next_choice
            next_choice=$(echo "$next_choice" | tr -d '\r\n\t ')

            case "$next_choice" in
                0|"") break ;;
                1) scan_and_install "Root_Managers_All/KernelSU_Series/kernelSU-Next/" ;;
                2) scan_and_install "Root_Managers_All/KernelSU_Series/kernelSU-Next/Package name obfuscation version/" ;;
                *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
            esac
        done
        ;;

            5) scan_and_install "$R/Ksu Jailbreak/" ;;
            6) scan_and_install "$R/MizuSU/" ;;
            7)        
             while true; do
            show_header
            echo -e "${BLUE}>> BakaSU 面具選單${NC}"
            echo -e "  1) 進入標準版"
            echo -e "  2) 進入測試版"
            echo -e "  0) 返回 KSU 選單"
            echo "-------------------------------------"

            echo -ne "請選擇："
            read next_choice
            next_choice=$(echo "$next_choice" | tr -d '\r\n\t ')

            case "$next_choice" in
                0|"") break ;;
                1) scan_and_install "Root_Managers_All/KernelSU_Series/BakaSU (ReSukiSU)/" ;;
                2) scan_and_install "Root_Managers_All/KernelSU_Series/BakaSU (ReSukiSU)/beta/" ;;
                *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
            esac
        done
        ;;

            8) 
        while true; do
            show_header
            echo -e "${BLUE}>> SukiSU Ultra 面具選單${NC}"
            echo -e "  1) 進入標準版"
            echo -e "  2) 進入beta"
            echo -e "  3) 進入偽裝版"
            echo -e "  4) 進入beta+spoofed"
            echo -e "  0) 返回 KSU 選單"
            echo "-------------------------------------"

            echo -ne "請選擇："
            read next_choice
            next_choice=$(echo "$next_choice" | tr -d '\r\n\t ')

            case "$next_choice" in
                0|"") break ;;
                1) scan_and_install "Root_Managers_All/KernelSU_Series/Sukisu Ultra/" ;;
                2) scan_and_install "Root_Managers_All/KernelSU_Series/Sukisu Ultra/beta/" ;;
                3) scan_and_install "Root_Managers_All/KernelSU_Series/Sukisu Ultra/Spoofed/" ;;
                4) scan_and_install "Root_Managers_All/KernelSU_Series/Sukisu Ultra/beta+Spoofed/" ;;
                *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
            esac
        done
        ;;
            9)        
             while true; do
            show_header
            echo -e "${BLUE}>> Wild_KSU 面具選單${NC}"
            echo -e "  1) 進入標準版"
            echo -e "  2) 進入偽裝版"
            echo -e "  0) 返回 KSU 選單"
            echo "-------------------------------------"

            echo -ne "請選擇："
            read next_choice
            next_choice=$(echo "$next_choice" | tr -d '\r\n\t ')

            case "$next_choice" in
                0|"") break ;;
                1) scan_and_install "Root_Managers_All/KernelSU_Series/Wild_KSU/" ;;
                2) scan_and_install "Root_Managers_All/KernelSU_Series/Wild_KSU/Package name obfuscation version/" ;;
                *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
            esac
        done
        ;;
            10) scan_and_install "$R/ZySU (Unsupported on Kernel v4.x & v5.x !!!)/" ;;
            11) scan_and_install "$R/FinaSU/" ;;
            12) scan_and_install "$R/Dafeiyu_KSU/" ;;
            13) scan_and_install "$R/" ;;
            *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
        esac
    done
}

# =================================================================
# 核心二級選單：四大 Root 面具總端
# =================================================================
root_mask_menu() {
    local M="Root_Managers_All"
    while true; do
        show_header
        echo -e "${YELLOW}[ 請選擇要管理的面具陣營 ]${NC}"
        echo -e " 1)  阿爾法系列面板 (Magisk Alpha)"
        echo -e " 2)  SK系列陣營 (SKroot_Series)"
        echo -e " 3)  進入：KernelSU 家族硬核大本營"
        echo -e " 4)  APatch 系列面板 (APatch / FolkPatch)"
        echo -e " 0)  返回主選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-4): "
        read mask_choice
        mask_choice=$(echo "$mask_choice" | tr -d '\r\n\t ')

        case "$mask_choice" in
            0|"") break ;;
            1) 
                while true; do
                    show_header
                    echo -e "${CYAN}>> Magisk Alpha 營地${NC}"
                    echo -e " 1) Magisk Alpha 官方原版"
                    echo -e " 2) 美化主題版 (Magisk Themed)"
                    echo -e " 0) 返回上級"
                    echo "-------------------------------------------------"
                    echo -n "請選擇: "
                    read alpha_choice
                    alpha_choice=$(echo "$alpha_choice" | tr -d '\r\n\t ')
                    case "$alpha_choice" in
                        0|"") break ;;
                        1) scan_and_install "$M/Magisk_Alpha_Series/" ;;
                        2) scan_and_install "$M/Magisk_Alpha_Series/Magisk Themed/" ;;
                        *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            2) scan_and_install "$M/SKroot_Series/" ;; 
            3) kernelsu_family_menu ;; 
            4) 
                while true; do
                    show_header
                    echo -e "${CYAN}>> APatch 營地${NC}"
                    echo -e " 1) APatch / FolkPatch 核心目錄"
                    echo -e " 2) 美化主題版 (APatch Themed)"
                    echo -e " 0) 返回上級"
                    echo "-------------------------------------------------"
                    echo -n "請選擇: "
                    read ap_choice
                    ap_choice=$(echo "$ap_choice" | tr -d '\r\n\t ')
                    case "$ap_choice" in
                        0|"") break ;;
                        1) scan_and_install "$M/APatch_Series/" ;;
                        2) scan_and_install "$M/APatch_Series/APatch Themed/" ;;
                        *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
        esac
    done
}

# =================================================================
# Telegram 頻道導航面板
# =================================================================
tg_channels() {
    show_header
    echo -e "${PURPLE}=== 官方紙飛機（Telegram）源頭情報站 ===${NC}"
    echo -e " 1) Magisk Alpha    2) KernelSU     3) APatch"
    echo -e " 4) FolkPatch       5) Kitsune Mask 6) 所有檢測軟件地址"
    echo -e " 7) 內核討論群     8) 所有模塊紙飛機群 9) kitsune 官方頻道"
    echo -e " 10) 秋刀魚內核討論群   11) LSPosed 官方頻道"
    echo "-------------------------------------------------"
    echo -n "請輸入編號跳轉 (輸入 0 返回): "
    read tg_choice
    tg_choice=$(echo "$tg_choice" | tr -d '\r\n\t ')

    [ "$tg_choice" = "0" ] || [ -z "$tg_choice" ] && return

    local url=""
    case "$tg_choice" in
        1) url="https://t.me/magiskalpha" ;;
        2) url="https://t.me/KernelSU" ;;
        3) url="https://t.me/APatchChannel" ;;
        4) url="https://t.me/FolkPatch" ;;
        5) url="https://t.me/KitsuneUfork" ;;
        6) url="https://t.me/root_hook_poc" ;;
        7) url="https://t.me/xiaogeyyds" ;;
        8) url="https://t.me/karyaanaktangerang" ;;
        9) url="https://t.me/magiskalpha" ;;
        10) url="https://t.me/qdyKernel" ;;
        11) url="https://t.me/LSPosed" ;;
    esac

    if [ -n "$url" ]; then
        am start -a android.intent.action.VIEW -d "$url" >/dev/null 2>&1
    fi
}

prepare_obfuscation_output() {
    SRC_ORIGINAL="$SRC_PATH"
    SRC_OUTPUT="${SRC_ORIGINAL}.obfuscated.sh"
    if [ -e "$SRC_OUTPUT" ]; then
        echo -n "輸出檔已存在：$SRC_OUTPUT；是否覆寫？(y/N): "
        IFS= read -r overwrite_choice
        case "$overwrite_choice" in y|Y|yes|YES) ;; *) echo "已取消，原始檔未變更。"; return 1 ;; esac
    fi
    if ! cp -p "$SRC_ORIGINAL" "$SRC_OUTPUT"; then
        echo "無法建立輸出副本，已取消。"
        return 1
    fi
    SRC_PATH="$SRC_OUTPUT"
}

shell_obfuscation() {
    show_header
    purple="\033[35m"
blue="\033[34m"
cyan="\033[36m"
yellow="\033[33m"
green="\033[32m"
red="\033[31m"
white="\033[37m"
reset="\033[0m"
clear

echo -e "${cyan}"
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃     💤 小颜公益免费加密工具 💤      ┃"
echo "┃        官方频道:@BYYXnb                    ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo -e "${reset}"

echo -e "${purple}╭──────────────────────────────────────────────╮${reset}"
echo -e "${purple}│${reset} ${cyan}工具特性：脚本混淆｜免Root加密混淆｜${reset}    ${purple}│${reset}"
echo -e "${purple}│${reset} ${yellow}加密前务必备份你的原始脚本！${reset}      ${purple}│${reset}"
echo -e "${purple}│${reset} ${red}root玩家建议使用二进制乱码加密${reset}            ${purple}│${reset}"
echo -e "${purple}╰──────────────────────────────────────────────╯${reset}"
echo ""

echo -e "${cyan}══════════════════  卡密验证（卡密：12345678） ══════════════════${reset}"
echo -ne "${green}▶ 请输入卡密：${reset}"
read -r CARD_KEY

if [ "$CARD_KEY" != "12345678" ]; then
    echo -e "${red}卡密錯誤或為空，返回主菜單${reset}"
    sleep 1.5
    return
fi

echo ""
echo -e "${green}卡密校验成功！正在加载加密方案列表...${reset}"
sleep 0.3
echo ""

echo -e "${cyan}══════════════════ 加密方案菜单 ══════════════════${reset}"
echo ""
echo -e "${yellow}▸ Root权限方案${reset}"
echo -e "${purple}  [01]${reset} 二进制乱码加密"
echo -e "${purple}  [02]${reset} 标记分割加密"
echo -e "${purple}  [03]${reset} 变量加密"
echo ""
echo -e "${green}▸ 免Root加密方案${reset}"
echo -e "${purple}  [04]${reset} 垃圾函数加密"
echo -e "${purple}  [05]${reset} 多层嵌套循环加密"
echo -e "${purple}  [06]${reset} 子shell嵌套回填加密"
echo -e "${purple}  [07]${reset} 伪循环垃圾迭代加密"
echo ""
echo -e "${cyan}═══════════════════════════════════════════════════${reset}"
echo -ne "${green}请输入方案编号：${reset}"
read -r SEL

if [ "$SEL" = "2" ];then
    echo ""
    echo -ne "${cyan}请输入要加密文件完整路径：${reset}"
    read -r SRC_PATH

    if [ ! -f "$SRC_PATH" ];then
        echo -e "${red}此文件不存在！返回主菜单${reset}"
        sleep 1.5
        return
    fi

    prepare_obfuscation_output || return
    TMP_GZ="${TEMP_DIR}/_gz_$$.tmp"
    TMP_B64="${TEMP_DIR}/_b64_$$.tmp"
    gzip -c "$SRC_PATH" > "$TMP_GZ"
    base64 -w 76 "$TMP_GZ" > "$TMP_B64"

    cat > "$SRC_PATH" <<'EOF'
#!/system/bin/sh
TMPDEC="${TMPDIR:-/data/local/tmp}/_dec_$$.sh"
sed '1,/^#__DATA__/d' "$0" | base64 -d | gzip -d > "$TMPDEC"
chmod 755 "$TMPDEC"
sh "$TMPDEC"
rm -f "$TMPDEC"
exit 0
#__DATA__
EOF
    cat "$TMP_B64" >> "$SRC_PATH"

    chmod 755 "$SRC_PATH"
    rm -f "$TMP_GZ" "$TMP_B64"

    echo ""
    echo -e "${green}加密执行完成！${reset}"
    echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
    echo -n "按任意键返回主菜单..."
    read -n 1
    return
fi

if [ "$SEL" = "3" ];then
    echo ""
    echo -ne "${cyan}请输入要加密文件完整路径：${reset}"
    read -r SRC_PATH

    if [ ! -f "$SRC_PATH" ];then
        echo -e "${red}文件不存在，返回主菜单${reset}"
        sleep 1.5
        return
    fi

    prepare_obfuscation_output || return
    TMPHEX="${TEMP_DIR}/_hex_$$.tmp"
    xxd -p "$SRC_PATH" | tr -d '\n' > "$TMPHEX"
    HEXDATA=$(cat "$TMPHEX")

    cat > "$SRC_PATH" <<EOF
#!/system/bin/sh
# 小颜公益免费变量加密
h="$HEXDATA"
RAW=\$(echo "\$h" | xxd -r -p)
eval "\$RAW"
exit 0
EOF
    rm -f "$TMPHEX"
    chmod 755 "$SRC_PATH"
    echo ""
    echo -e "${green}加密执行完成！${reset}"
    echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
    echo -n "按任意键返回主菜单..."
    read -n 1
    return
fi

# ==========4 垃圾函数加密【4星，三重base64+垃圾干扰函数】==========
if [ "$SEL" = "4" ];then
    echo ""
    echo -ne "${cyan}请输入要加密文件完整路径：${reset}"
    read -r SRC_PATH

    if [ ! -f "$SRC_PATH" ];then
        echo -e "${red}文件不存在，返回主菜单${reset}"
        sleep 1.5
        return
    fi

    prepare_obfuscation_output || return
    RAW=$(cat "$SRC_PATH")
    b1=$(printf "%s" "$RAW"|base64 -w0)
    b2=$(printf "%s" "$b1"|base64 -w0)
    b3=$(printf "%s" "$b2"|base64 -w0)
    junk="s9k2x7q5"
    mixed="${junk}${b3}${junk}"

    cat > "$SRC_PATH" <<'LOADER'
#!/system/bin/sh
_f0(){ local a=0;return $a; }
_f1(){ local b=1;return $b; }
_f2(){ :; :; :; }
_f3(){ echo "" >/dev/null; }
_f4(){ read xxx </dev/null; }
_f0;_f1;_f2;_f3;_f4

__RAW_BUF="REPLACE_MIXED_DATA"
JUNK_MARK="s9k2x7q5"

strip_junk(){
inp="$1"
step1="${inp#$JUNK_MARK}"
step2="${step1%$JUNK_MARK}"
printf "%s" "$step2"
}

get_payload(){
dat=$(strip_junk "$__RAW_BUF")
l3=$(echo "$dat"|base64 -d)
l2=$(echo "$l3"|base64 -d)
l1=$(echo "$l2"|base64 -d)
printf "%s" "$l1"
}

PAYLOAD=$(get_payload)
eval "$PAYLOAD"
exit $?
LOADER

sed -i "s|__RAW_BUF=\"REPLACE_MIXED_DATA\"|__RAW_BUF=\"${mixed}\"|" "$SRC_PATH"
chmod 755 "$SRC_PATH"

    echo ""
    echo -e "${green}加密执行完成！${reset}"
    echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
    echo -n "按任意键返回主菜单..."
    read -n 1
    return
fi

# ==========5 多层嵌套循环加密【免root】四重base64嵌套eval==========
if [ "$SEL" = "5" ];then
    echo ""
    echo -ne "${cyan}请输入要加密文件完整路径：${reset}"
    read -r SRC_PATH

    if [ ! -f "$SRC_PATH" ];then
        echo -e "${red}文件不存在，返回主菜单${reset}"
        sleep 1.5
        return
    fi

    prepare_obfuscation_output || return
    RAW=$(cat "$SRC_PATH")
    e1=$(printf "%s" "$RAW" | base64 -w0)
    e2=$(printf "%s" "$e1" | base64 -w0)
    e3=$(printf "%s" "$e2" | base64 -w0)
    e4=$(printf "%s" "$e3" | base64 -w0)

    cat > "$SRC_PATH" <<'MULTI_LOADER'
#!/system/bin/sh
#小颜公益免费多层嵌套循环加密
__dec(){
d="$1"
for _t in 1 2 3 4
do
d=$(printf "%s" "$d"|base64 -d 2>/dev/null)
done
printf "%s" "$d"
}
__X="REPLACE_NEST_DATA"
__OUT=$(__dec "$__X")
eval "$__OUT"
exit $?
MULTI_LOADER

sed -i "s|__X=\"REPLACE_NEST_DATA\"|__X=\"${e4}\"|" "$SRC_PATH"
chmod 755 "$SRC_PATH"

    echo ""
    echo -e "${green}加密执行完成！${reset}"
    echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
    echo -n "按任意键返回主菜单..."
    read -n 1
    return
fi

# ==========6 子shell嵌套回填加密（原9号）==========
if [ "$SEL" = "6" ];then
    echo ""
    echo -ne "${cyan}请输入要加密文件完整路径：${reset}"
    read -r SRC_PATH
    if [ ! -f "$SRC_PATH" ];then
        echo -e "${red}文件不存在，返回主菜单${reset}"
        sleep 1.5
        return
    fi
    prepare_obfuscation_output || return
    RAW=$(cat "$SRC_PATH"|base64 -w0)
    cat > "$SRC_PATH" <<'SUBSHELL_LOADER'
#!/system/bin/sh
#小颜公益免费子shell嵌套回填加密
__inner(){
local _z="REPLACE_SUB_SHELL_DATA"
(
echo "$_z"
)
}
__outer(){
local ret
ret=$(__inner)
echo "$ret"|base64 -d
}
eval "$(__outer)"
exit $?
SUBSHELL_LOADER
sed -i "s|local _z=\"REPLACE_SUB_SHELL_DATA\"|local _z=\"${RAW}\"|" "$SRC_PATH"
chmod 755 "$SRC_PATH"
    echo ""
    echo -e "${green}加密执行完成！${reset}"
    echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
    echo -n "按任意键返回主菜单..."
    read -n 1
    return
fi

# ==========7 伪循环垃圾迭代加密（原10号）==========
if [ "$SEL" = "7" ];then
    echo ""
    echo -ne "${cyan}输入要加密文件完整路径：${reset}"
    read -r SRC_PATH
    if [ ! -f "$SRC_PATH" ];then
        echo -e "${red}文件不存在，返回主菜单${reset}"
        sleep 1.5
        return
    fi
    prepare_obfuscation_output || return
    RAW=$(cat "$SRC_PATH"|base64 -w0)
    cat > "$SRC_PATH" <<'FAKELOOP_LOADER'
#!/system/bin/sh
#小颜公益免费伪循环垃圾迭代加密
_buf=""
_payload="REPLACE_FAKE_LOOP_DATA"
for t in 1 2 3 4 5;do
    : dummy iter
    if [ $t -eq 3 ];then
        _buf="$_payload"
    fi
done
__run(){
echo "$_buf"|base64 -d
}
eval "$(__run)"
exit $?
FAKELOOP_LOADER
sed -i "s|_payload=\"REPLACE_FAKE_LOOP_DATA\"|_payload=\"${RAW}\"|" "$SRC_PATH"
chmod 755 "$SRC_PATH"
    echo ""
    echo -e "${green}加密执行完成！${reset}"
    echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
    echo -n "按任意键返回主菜单..."
    read -n 1
    return
fi

#二进制乱码加密逻辑
if [ "$SEL" != "1" ];then
    echo -e "${red}输入无效，返回主菜单${reset}"
    sleep 1.5
    return
fi

echo ""
echo -ne "${cyan}请输入要加密文件完整路径：${reset}"
read -r SRC_PATH

if [ ! -f "$SRC_PATH" ];then
    echo -e "${red}文件不存在，返回主菜单${reset}"
    sleep 1.5
    return
fi

    prepare_obfuscation_output || return
TMP_GZ="${TEMP_DIR}/_gz_$$.tmp"
gzip -c "$SRC_PATH" > "$TMP_GZ"

cat > "$SRC_PATH" <<'EOF'
#!/system/bin/sh
TMPDEC="${TMPDIR:-/data/local/tmp}/_dec_$$.sh"
sed '1,/^#__DATA__/d' "$0" | gzip -d > "$TMPDEC"
chmod 755 "$TMPDEC"
sh "$TMPDEC"
rm -f "$TMPDEC"
exit 0
#__DATA__
EOF
cat "$TMP_GZ" >> "$SRC_PATH"

chmod 755 "$SRC_PATH"
rm -f "$TMP_GZ"

echo ""
echo -e "${green}加密任务执行完成！${reset}"
echo -e "${cyan}输出路径：${SRC_PATH}${reset}"
echo -n "按任意键返回主菜单..."
read -n 1
}

# =================================================================
# 內嵌檢測腳本：先 Inte.ko，再遠控木馬 IOC 掃描
# ================================================================
run_embedded_scan() {
    local scan_name="$1"
    local scan_body="$2"
    local scan_tmp="${TEMP_DIR}/.root_collection_${scan_name}_$$.sh"
    local scan_rc
    if ! (umask 077; : > "$scan_tmp") 2>/dev/null; then
        echo -e "${RED}[錯誤] 無法建立暫存檔：$scan_tmp${NC}"
        return 1
    fi
    if ! printf '%s\n' "$scan_body" > "$scan_tmp" || ! chmod 700 "$scan_tmp" 2>/dev/null; then
        echo -e "${RED}[錯誤] 無法完整寫入檢測腳本。${NC}"
        rm -f "$scan_tmp"
        return 1
    fi
    sh "$scan_tmp"
    scan_rc=$?
    rm -f "$scan_tmp"
    return "$scan_rc"
}

run_security_scans() {
    # 移除 show_header，直接全面清屏，給後續的檢測留出完整的螢幕空間
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${GREEN}                頂級搞機軍火庫 (綜合安全檢測)    ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW}執行順序：1. 歐加 Inte.ko 檢測  2. DeviceHub 遠控病毒 IOC 檢測${NC}"
    echo -e "檢測腳本以唯讀方式執行；不會自動清除檔案或終止程序。"
    echo "-------------------------------------------------"
    
    echo -e "${CYAN}[1/2] 開始歐加反作弊 Inte.ko 檢測...${NC}"
    run_embedded_scan "inteko" "$INTEKO_SCAN"
    inte_rc=$?
    echo
    
    echo -e "${CYAN}[2/2] 開始遠控病毒檢測...${NC}"
    run_embedded_scan "devicehub" "$DEVICEHUB_SCAN"
    devicehub_rc=$?
    echo
    
    echo "-------------------------------------------------"
    echo "檢測流程完成。Inte.ko 狀態碼：$inte_rc；遠控檢測狀態碼：$devicehub_rc"
    echo -n "按任意鍵返回主選單..."
    IFS= read -r -n 1 _key
    echo
}

INTEKO_SCAN=$(cat <<'__INTEKO_SCAN_EOF__'
set -eu
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'
R=$(printf '\033[0;31m'); G=$(printf '\033[0;32m')
Y=$(printf '\033[1;33m'); B=$(printf '\033[1;36m'); N=$(printf '\033[0m')
PASS=0; WARN=0; FAIL=0; SKIP=0; TOTAL=0
_pass()  { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); printf "  ${GREEN}[PASS]${NC} %s\n" "$1"; }
_warn()  { WARN=$((WARN+1)); TOTAL=$((TOTAL+1)); printf "  ${YELLOW}[WARN]${NC} %s\n" "$1"; }
_fail()  { FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); printf "  ${RED}[FAIL]${NC} %s\n" "$1"; }
_skip()  { SKIP=$((SKIP+1)); TOTAL=$((TOTAL+1)); printf "  ${WHITE}[SKIP]${NC} %s\n" "$1"; }
_info()  { printf "  ${CYAN}  >${NC} %s\n" "$1"; }
_hdr()   { echo ""; sleep 1 ; echo "==================================================";  echo "  $1"; echo "=================================================="; sleep 0; }
_sub()   { echo ""; echo "-- $1 --"; }

    echo
    printf "$G"
    cat <<'MAPLE_BANNER'
███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
██╔████╔██║███████║██████╔╝██║     █████╗
██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝
MAPLE_BANNER
    printf "$N\n"
    printf "$B━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
    printf "$B  MAPLE · Inte.ko模块检测$N\n"
    printf "\n$B  『时光流转，愿你能与珍爱之人再度重逢』🍁$N\n\n"
    printf "$B  By.MapleAutumn 交流群 757313825$N\n"
    printf "$B━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$N\n"
    sleep 1
echo "── 内核检测状态 ──"
echo

for p in /proc/inte_ko /proc/inte_systbl /proc/inte_status; do
    if ls -ld "$p" >/dev/null 2>&1; then
        echo "[存在] $p"
    else
        echo "[不存在] $p（不存在或访问受限）"
    fi
done

echo
echo "── 模块状态 ──"
if cat /proc/modules 2>/dev/null | grep -q '^inte '; then
    echo "[确认] inte 模块已加载 欧加KO反作弊已内置"
    sleep 3

    sleep 0.8

else
    echo "[不存在] 不存在或未找到模块记录 未内置驱动反作弊"
    
fi
__INTEKO_SCAN_EOF__
)

DEVICEHUB_SCAN=$(cat <<'__DEVICEHUB_SCAN_EOF__'

if [ ! -t 1 ]; then
  R=''; M=''; C=''; B=''; G=''; Y=''; E=''
else
  R='\033[0m'; M='\033[1;35m'; C='\033[1;36m'; B='\033[1;34m'
  G='\033[1;32m'; Y='\033[1;33m'; E='\033[1;31m'
fi
CUR="INIT"
sec()  { CUR="$1"; printf '\n%b===== %s : %s =====%b\n' "$C" "$1" "$2" "$R"; }
info() { printf '%b[INFO]%b [%s] %s\n' "$B" "$R" "$CUR" "$1"; }
ok()   { printf '%b[ OK ]%b [%s] %s\n' "$G" "$R" "$CUR" "$1"; }
warn() { printf '%b[WARN]%b [%s] %s\n' "$Y" "$R" "$CUR" "$1"; }
hit()  { printf '%b[HIT!]%b [%s] %s\n' "$E" "$R" "$CUR" "$1"; }

have(){ command -v "$1" >/dev/null 2>&1; }

# ---------- IOC（全部来自逆向报告）----------
HASH_MAIN='3c91e2e66cc2e480428da3e120467b085f019cfd20c988b766d584c7df7a835d'
HASH_ACE='8ea955c6c7001223593858d75aaaf9bb61ef2c0f0cd85f160f44f70c5fe891dc'
PKG_AGENT='com.devicehub.agent'
PKG_ACE='com.mycompany.myapp'
ACE_COMP='com.mycompany.myapp.a'
C2_DOMAIN='360nb.top'          # 辅助证据，原逆向报告未直接给出，来源存疑

PROC_RE='devicehub-device|devicehub_inject|devicehub-agent|devicehub-watchdog|devicehub-app-supervisor|devicehub-root-supervisor|devicehub-rootctl|devicehub-account|devicehub-screen\.jar|/data/system/devicehub|com\.devicehub\.agent'
ENV_RE='DH_APP_PORT|DH_MANAGED_ROOT_DIR|DH_MODULE_DIR|DH_DEVICE_BIN|DH_STATE_PATH|DH_APP_PACKAGE|DEVICEHUB_PROTOCOL_VECTORS'

DIR_IOC='/data/system/devicehub /devicehub-media'

FILE_IOC='/data/system/devicehub/devicehub-device
/data/system/devicehub/devicehub-device.json
/data/system/devicehub/devicehub-device.log
/data/system/devicehub/agent-install.log
/data/system/devicehub/devicehub-watchdog.pid
/data/system/devicehub/app-first-install
/data/adb/service.d/devicehub-agent.sh
/data/adb/service.d/devicehub-agent-extras.sh
/devicehub-screen.jar
/devicehub-live.pid
/devicehub-account.sh
/devicehub-rootctl.sh
/devicehub-watchdog.sh
/devicehub-app-supervisor.sh
/devicehub-root-supervisor.sh
/devicehub-managed-root-common.sh
/devicehub-managed-root-lock.sh
/devicehub_inject
/devicehub_inject.sh
/sdcard/devicehub-agent.apk
/data/local/tmp/devicehub-device
/data/local/tmp/devicehub_inject
/module.id'

# 运行时临时文件（安全通配，循环内 [ -e ]/[ -L ] || continue）
FILE_GLOB='/devicehub_screen_*
/devicehub_record_*
/devicehub_cmd_*.sh'

# 目录通配（staging / 模块）
DIR_GLOB='/devicehub_managed_*
/data/adb/*devicehub*
/data/adb/modules/*devicehub*'

# 系统分区残留
SYS_SUSPECT='/system/bin/devicehub-device
/system/bin/devicehub-watchdog
/system/xbin/devicehub-device
/system/xbin/devicehub-watchdog
/system/etc/devicehub-agent.sh
/system/etc/devicehub-watchdog.sh
/vendor/bin/devicehub-device
/vendor/bin/devicehub-watchdog'

# appops 七项（报告明确）
APPOP_KEYS='CAMERA|READ_SMS|MANAGE_EXTERNAL_STORAGE|WAKE_LOCK|RUN_IN_BACKGROUND|RUN_ANY_IN_BACKGROUND|START_FOREGROUND'

# ---------- 判定计数 ----------
C_CONF=0; C_SUS=0; C_RES=0
R_CONF=""; R_SUS=""; R_RES=""
conf(){ C_CONF=$((C_CONF+1)); R_CONF="$R_CONF
  - $1"; }
sus() { C_SUS=$((C_SUS+1));   R_SUS="$R_SUS
  - $1"; }
res() { C_RES=$((C_RES+1));   R_RES="$R_RES
  - $1"; }

# ---------- 哈希 ----------
sha_of(){
  if have sha256sum; then sha256sum "$1" 2>/dev/null | awk '{print $1}'
  elif have toybox; then toybox sha256sum "$1" 2>/dev/null | awk '{print $1}'; fi
}
check_hash(){
  [ -f "$1" ] && [ ! -L "$1" ] || return 2
  _h=$(sha_of "$1"); [ -n "$_h" ] || return 3
  [ "$_h" = "$2" ] && return 0; return 1
}

SELF=$(readlink -f "$0" 2>/dev/null); [ -n "$SELF" ] || SELF="$0"

# ============================================================
# 作者/频道信息（base64 编码）
# ============================================================
ENCODED_TG_URL="dGc6Ly9yZXNvbHZlP2RvbWFpbj1BU0RLODg2JnBvc3Q9Ng=="
ENCODED_WEB_URL="aHR0cHM6Ly90Lm1lL0FTREs4ODY="

TELEGRAM_URL=""
WEB_URL=""
if have base64; then
  TELEGRAM_URL=$(printf '%s' "$ENCODED_TG_URL" | base64 -d 2>/dev/null)
  WEB_URL=$(printf '%s' "$ENCODED_WEB_URL" | base64 -d 2>/dev/null)
fi
[ -n "$TELEGRAM_URL" ] || TELEGRAM_URL='tg://resolve?domain=aadaili&post=6'
[ -n "$WEB_URL" ]      || WEB_URL='https://t.me/aadaili'

# ---------- 三行彩色提醒 ----------
show_reminders(){
  printf '\n'
  printf '%b  [!] 重要提醒：本脚本仅用于安全检测与学习研究，严禁用于非法侵入、监控他人设备 %b\n' "$E" "$R"
  printf '%b  [!] 免责声明：检测结果仅供参考，最终判定请结合人工分析与官方安全工具二次确认 %b\n' "$Y" "$R"
  printf '%b  [OK] 泛滥频道:@ASDK886   |   反馈与更新：%s %b\n' "$G" "$WEB_URL" "$R"
  printf '\n'
}

# ============================================================
# 环境自检
# ============================================================
printf '%b' "$M"
cat <<EOF
############################################################
#  DeviceHub / 平安远控  纯检测 v11（只读 · 零修改）
#  UID: $(id -u 2>/dev/null)    SELinux: $(getenforce 2>/dev/null || echo '?')
#  检测范围: 仅逆向确认的精确 IOC，不扫描用户目录
#  行为范围: 不刪除 / 不終止 / 不修改系統設定 / 不卸載；只建立並清理暫存檢測腳本
############################################################
EOF
printf '%b' "$R"

IS_ROOT=0
[ "$(id -u 2>/dev/null)" = "0" ] && IS_ROOT=1
if [ "$IS_ROOT" = "1" ]; then
  ok "以 root 运行，可读取全部受保护路径与进程信息"
else
  warn "非 root 运行：/data/system/* 与跨应用 /proc 信息不可见，可能漏检"
  warn "建议: su -c 'sh $SELF'"
fi

# ---------- 三行彩色提醒 ----------
show_reminders

# ============================================================
# 段 A：文件与目录 IOC
# ============================================================
sec "A" "文件/目录 IOC（精确路径 + 安全通配）"
for d in $DIR_IOC; do
  if [ -d "$d" ] || [ -L "$d" ]; then
    hit "目录: $d"
    if [ -f "$d/devicehub-device" ] || [ -f "$d/devicehub-device.json" ]; then
      conf "木马状态目录: $d（含密钥/状态文件）"
    else
      res "残留目录: $d（无核心文件，历史痕迹）"
    fi
  fi
done
for f in $FILE_IOC; do
  if [ -e "$f" ] || [ -L "$f" ]; then
    hit "文件: $f"
    case "$f" in
      /data/system/devicehub/devicehub-device|\
      /devicehub_inject|\
      /devicehub-screen.jar|\
      /data/adb/service.d/devicehub-agent*.sh)
        conf "核心载荷/持久化: $f" ;;
      /module.id)
        info "可疑标记文件: $f（低置信，需人工确认来源）" ;;
      *)
        res "残留文件: $f" ;;
    esac
  fi
done
# 安全通配
for f in $FILE_GLOB; do
  [ -e "$f" ] || [ -L "$f" ] || continue
  hit "运行时文件: $f"
  res "运行时临时文件: $f（木马执行痕迹）"
done
for f in $DIR_GLOB; do
  [ -d "$f" ] || [ -L "$f" ] || continue
  hit "通配目录: $f"
  res "通配目录残留: $f"
done
# service.d 通配
for f in /data/adb/service.d/devicehub-agent-*.sh; do
  [ -e "$f" ] || [ -L "$f" ] || continue
  hit "service.d 自启: $f"
  conf "service.d 自启脚本: $f"
done

# ============================================================
# 段 B：SHA-256 精确比对（静态路径，运行时路径由段 C 兜底）
# ============================================================
sec "B" "SHA-256 静态比对（主 ELF / ACE APK）"
for f in \
  /data/system/devicehub/devicehub-device \
  /data/local/tmp/devicehub-device \
  /data/adb/devicehub-device \
  /system/bin/devicehub-device \
  /system/xbin/devicehub-device
do
  [ -f "$f" ] || continue
  check_hash "$f" "$HASH_MAIN"; rc=$?
  if [ "$rc" = "0" ]; then
    hit "SHA-256 匹配主 ELF: $f"; conf "主 ELF 精确匹配: $f"
  elif [ "$rc" = "1" ]; then
    warn "同名异 hash（疑似变种）: $f"; sus "疑似变种: $f"
  fi
done
for f in /sdcard/devicehub-agent.apk; do
  [ -f "$f" ] || continue
  check_hash "$f" "$HASH_ACE"; rc=$?
  if [ "$rc" = "0" ]; then
    hit "SHA-256 匹配 ACE APK: $f"; conf "ACE APK 精确匹配: $f"
  elif [ "$rc" = "1" ]; then
    warn "同名异 hash: $f"; sus "疑似变种 ACE: $f"
  fi
done

# ============================================================
# 段 C：活跃进程（cmdline + exe hash + environ 注入）
# ============================================================
sec "C" "活跃恶意进程（cmdline / exe hash / environ）"
_p(){ sed -n 's/^PPid:[[:space:]]*\([0-9]*\).*/\1/p' "/proc/$1/status" 2>/dev/null | head -n1; }
SKIP=" "; _cur=$$; _d=0
while [ -n "$_cur" ] && [ "$_cur" != "0" ] && [ "$_cur" != "1" ] && [ "$_d" -lt 64 ]; do
  SKIP="$SKIP$_cur "
  _n=$(_p "$_cur")
  if [ -z "$_n" ] || [ "$_n" = "$_cur" ]; then break; fi
  _cur=$_n; _d=$((_d+1))
done

PIDS=""
for cf in /proc/[0-9]*/cmdline; do
  [ -r "$cf" ] || continue
  grep -qaE "$PROC_RE" "$cf" 2>/dev/null || continue
  pid=${cf#/proc/}; pid=${pid%/cmdline}
  case "$SKIP" in *" $pid "*) continue;; esac
  c=$(tr '\0' ' ' < "$cf" 2>/dev/null | tr -d '\r\n')
  [ -n "$SELF" ] && case "$c" in *"${SELF##*/}"*) continue;; esac
  PIDS="$PIDS $pid"
done

if [ -n "$PIDS" ]; then
  for pid in $PIDS; do
    c=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | tr -d '\r\n')
    exe=$(readlink "/proc/$pid/exe" 2>/dev/null)
    hit "PID=$pid EXE=$exe CMD=[$c]"
    conf "活跃进程 PID=$pid: $c"

    case "$exe" in
      *"(deleted)"*)
        sus "PID=$pid exe 已删除（反取证）: $exe" ;;
    /*)
        if [ -f "$exe" ]; then
            check_hash "$exe" "$HASH_MAIN"; rc=$?
            if [ "$rc" = "0" ]; then
                conf "PID=$pid exe SHA-256 精确匹配主 ELF"
            elif [ "$rc" = "1" ]; then
                sus "PID=$pid exe 同路径异 hash（疑似变种）"
            fi
        fi
        ;;
    esac

    if [ -r "/proc/$pid/environ" ]; then
      envs=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -aE "^($ENV_RE)=" )
      if [ -n "$envs" ]; then
        hit "PID=$pid 注入环境变量:"
        printf '%s\n' "$envs" | while read -r l; do printf '         %s\n' "$l"; done
        conf "PID=$pid 含 DeviceHub 注入环境变量"
      fi
    fi
  done
else
  ok "无活跃恶意进程"
fi

# ============================================================
# 段 D：已装包（含状态变量，供段 E 使用）
# ============================================================
sec "D" "已装包检测"
AGENT_INSTALLED=0
ACE_HASH_MATCH=0

if pm list packages 2>/dev/null | grep -Fqx "package:$PKG_AGENT"; then
  AGENT_INSTALLED=1
  apath=$(pm path "$PKG_AGENT" 2>/dev/null | sed -n 's/^package://p' | head -n1)
  hit "已装 $PKG_AGENT -> ${apath:-未知}"
  sus "已装主控包 $PKG_AGENT（专属包名，几乎可确证）"
  if have dumpsys; then
    comp=$(dumpsys package "$PKG_AGENT" 2>/dev/null | grep -E 'WakeReceiver|AgentService' | head -n4)
    if [ -n "$comp" ]; then
      printf '%s\n' "$comp" | while read -r l; do printf '         %s\n' "$l"; done
      sus "已装包含 .WakeReceiver/.AgentService 组件（报告明确）"
    fi
  fi
else
  ok "未装 $PKG_AGENT"
fi

if pm list packages 2>/dev/null | grep -Fqx "package:$PKG_ACE"; then
  apath=$(pm path "$PKG_ACE" 2>/dev/null | sed -n 's/^package://p' | head -n1)
  apk=${apath#package:}
  if [ -n "$apk" ]; then
    check_hash "$apk" "$HASH_ACE"; rc=$?
    if [ "$rc" = "0" ]; then
      ACE_HASH_MATCH=1
      hit "已装 ACE 且 hash 匹配 -> $apath"
      conf "ACE APK hash 匹配: $PKG_ACE"
    elif [ "$rc" = "1" ]; then
      info "已装 $PKG_ACE，但 hash 不匹配 ACE 样本（可能是正常应用，不处理）"
    fi
  fi
else
  ok "未装 $PKG_ACE"
fi

# ============================================================
# 段 E：系统设置篡改（只读）
# ============================================================
sec "E" "系统设置篡改（accessibility / deviceidle / stay_on / appops）"

AC=$(settings get secure enabled_accessibility_services 2>/dev/null)
AC_EN=$(settings get secure accessibility_enabled 2>/dev/null)
case "$AC" in
  *"$ACE_COMP"*)
    hit "无障碍注入: $ACE_COMP"
    if [ "$ACE_HASH_MATCH" = "1" ]; then
      conf "无障碍服务被注入 ACE 组件（且 ACE hash 已确诊）"
    else
      info "无障碍服务含 $ACE_COMP，但 ACE hash 未匹配样本（可能是同名正常应用）"
    fi
    [ "$AC_EN" = "1" ] && sus "accessibility_enabled=1（服务实际启用）" \
                        || info "accessibility_enabled=$AC_EN（服务开关未开）"
    ;;
  *) ok "无障碍未含 ACE";;
esac

DW=$(dumpsys deviceidle whitelist 2>/dev/null | grep -iE 'devicehub|mycompany')
if [ -n "$DW" ]; then
  printf '%s\n' "$DW" | while read -r l; do hit "白名单: $l"; done
  sus "deviceidle 白名单含 devicehub/mycompany"
else
  ok "白名单未含目标"
fi

SW=$(settings get global stay_on_while_plugged_in 2>/dev/null)
case "$SW" in
  -1|3|7) hit "屏幕常亮被篡改: $SW"
          res "stay_on_while_plugged_in=$SW（木马或用户偏好均可能）";;
  *) ok "屏幕常亮正常 (=$SW)";;
esac

if [ "$AGENT_INSTALLED" = "1" ]; then
  AOP=""
  if have appops; then
    AOP=$(appops get "$PKG_AGENT" 2>/dev/null)
  elif have cmd; then
    AOP=$(cmd appops get "$PKG_AGENT" 2>/dev/null)
  fi
  if [ -n "$AOP" ]; then
    AHIT=$(printf '%s\n' "$AOP" | grep -iE "$APPOP_KEYS" | grep -iE 'allow')
    if [ -n "$AHIT" ]; then
      printf '%s\n' "$AHIT" | while read -r l; do hit "appops: $l"; done
      sus "appops 含报告所列七项权限（被授权）"
    else
      ok "appops 未发现七项被授权"
    fi
  else
    info "appops 不可读（无权限或版本差异）"
  fi
else
  info "跳过 appops（$PKG_AGENT 未安装）"
fi

# ============================================================
# 段 F：网络与本地后门
# ============================================================
sec "F" "网络连接与 8080 回环后门"

NB=""
for cf in /proc/[0-9]*/cmdline; do
  [ -r "$cf" ] || continue
  grep -qa "$C2_DOMAIN" "$cf" 2>/dev/null || continue
  pid=${cf#/proc/}; pid=${pid%/cmdline}
  c=$(tr '\0' ' ' < "$cf" 2>/dev/null | tr -d '\r\n')
  NB="$NB PID=$pid:$c"
done
if [ -n "$NB" ]; then
  hit "cmdline 含 $C2_DOMAIN:$NB"
  sus "进程 cmdline 出现 $C2_DOMAIN（辅助证据）"
else
  ok "cmdline 未含 $C2_DOMAIN"
fi

if have ss; then
  NL=$(ss -tnp 2>/dev/null | grep -i 'devicehub')
elif have netstat; then
  NL=$(netstat -anp 2>/dev/null | grep -i 'devicehub')
else
  NL=""
fi
if [ -n "$NL" ]; then
  printf '%s\n' "$NL" | while read -r l; do hit "连接: $l"; done
  res "存在 devicehub 相关连接"
else
  ok "无 devicehub 相关连接"
fi

# 不主動查詢 DNS：C2_DOMAIN 來源尚未充分驗證，避免檢測時產生外部 DNS 請求。
info "C2 網域僅做本機進程命令列字串比對；不執行 DNS 查詢"

if [ -r /proc/net/tcp ] && awk '$2=="0100007F:1F90" && $4=="0A"{f=1} END{exit !f}' /proc/net/tcp 2>/dev/null; then
  hit "IPv4 回环后门 127.0.0.1:8080 LISTEN"
  conf "本地后门监听: 127.0.0.1:8080"
else
  ok "无 IPv4 127.0.0.1:8080"
fi
if [ -r /proc/net/tcp6 ] && awk '$2=="00000000000000000000000001000000:1F90" && $4=="0A"{f=1} END{exit !f}' /proc/net/tcp6 2>/dev/null; then
  hit "IPv6 回环后门 [::1]:8080 LISTEN"
  conf "本地后门监听: [::1]:8080"
else
  ok "无 IPv6 [::1]:8080"
fi

# ============================================================
# 段 G：SELinux
# ============================================================
sec "G" "SELinux 状态"
S=$(getenforce 2>/dev/null)
[ -z "$S" ] && S=$(cat /sys/fs/selinux/enforce 2>/dev/null | sed 's/^1$/Enforcing/;s/^0$/Permissive/')
case "$S" in
  Permissive|0) hit "SELinux=Permissive"
                sus "SELinux=Permissive（可能被篡改，也可能是开发配置）";;
  Enforcing|1)  ok "SELinux=Enforcing";;
  *)            info "SELinux 状态未知";;
esac

# ============================================================
# 段 H：系统分区残留
# ============================================================
sec "H" "系统分区残留（rm 无法根治）"
SYS_HIT=0
for f in $SYS_SUSPECT; do
  if [ -e "$f" ] || [ -L "$f" ]; then
    SYS_HIT=1
    hit "系统分区: $f"
    conf "系统分区存在 devicehub: $f（必须刷官方固件对应分区）"
  fi
done
if [ "$SYS_HIT" = "0" ]; then ok "系统分区未见 devicehub*"; fi

# ============================================================
# 判定结论
# ============================================================
printf '\n%b' "$M"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                        检测结论                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
printf '%b' "$R"

printf '  确诊指标 : %d 项\n' "$C_CONF"
printf '  疑似指标 : %d 项\n' "$C_SUS"
printf '  残留指标 : %d 项\n' "$C_RES"

if [ "$C_CONF" -gt 0 ]; then
  printf '\n%b>>> 结论：已确诊感染 DeviceHub / 平安远控木马 <<<%b\n' "$E" "$R"
  printf '%b确诊依据:%b%s\n' "$E" "$R" "$R_CONF"
  cat <<'ADV'

处置建议（需 root，按序执行）：
  1. 立即断网（飞行模式 + 关 WiFi/移动数据），阻止 C2 下发新指令
  2. 备份重要数据到外部存储（照片、文档、聊天记录）
  3. 按序清除：
     ① 删 /data/adb/service.d/devicehub-agent*.sh（先断持久化）
     ② SIGSTOP 冻结恶意进程，chmod 000 主 ELF，再 SIGKILL
     ③ pm uninstall com.devicehub.agent
     ④ 恢复无障碍/appops/deviceidle/stay_on 设置
     ⑤ 不要直接執行通配符 rm -rf；先備份並逐項人工核對命中路徑，再決定處置方式
  4. 若段 H 报告系统分区存在 —— rm 无法根治，必须刷官方固件对应分区
  5. 若段 C 报告 sh/app_process 寄宿进程 —— 木马利用解释器寄生，需重启后复查
  6. 清除后重启，重新跑本检测确认干净

强烈建议：因该木马具备远程 shell、拍照、短信、无障碍注入、root 托管更新等
完整 RAT 能力，处置后应立刻修改微信/QQ/支付宝/银行账号密码。
ADV
  RC=2

elif [ "$C_SUS" -gt 0 ]; then
  printf '\n%b>>> 结论：高度疑似感染（需人工确认）<<<%b\n' "$Y" "$R"
  printf '%b疑似依据:%b%s\n' "$Y" "$R" "$R_SUS"
  cat <<'ADV'

处置建议：
  1. 逐条核对上述疑似项，确认是否为你主动安装/配置
     - com.devicehub.agent 若确实装过（极不可能），卸载即可
     - 无障碍含 com.mycompany.myapp.a：确认是你的应用还是陌生应用
       （若段 D 已报 ACE hash 匹配，则直接按确诊处理）
     - SELinux=Permissive：确认是否你手动设置过
     - appops 七项：确认是否为该包主动申请且你授权
  2. 复查精确 IOC 文件是否散落在其他位置
  3. 建议同时检查：最近安装应用列表、电池耗电排行、无障碍服务列表
  4. 若无法解释上述疑似项，按"确诊"流程处置
ADV
  RC=1

elif [ "$C_RES" -gt 0 ]; then
  printf '\n%b>>> 结论：可疑残留（历史感染痕迹）<<<%b\n' "$Y" "$R"
  printf '%b残留依据:%b%s\n' "$Y" "$R" "$R_RES"
  cat <<'ADV'

处置建议：
  1. 残留说明木马曾运行过但已被部分清除，或已被其他工具清理
  2. 检查 /data/system/devicehub 是否为空目录（空目录可安全删除）
  3. 若仅 stay_on_while_plugged_in 命中，可能只是用户偏好，无需处理
  4. 若段 H 报告系统分区存在，务必刷官方固件对应分区
  5. 重启后重跑本检测，若无残留且无活跃进程，视为已清理
ADV
  RC=1

else
  printf '\n%b>>> 结论：未发现 DeviceHub / 平安远控 感染痕迹 <<<%b\n' "$G" "$R"
  cat <<'ADV'

无需处理。若仍有安全顾虑，可：
  1. 确认最近未安装来源不明的 APK
  2. 检查无障碍服务列表中是否有陌生组件
  3. 定期审查 /data/adb/service.d（root 用户）下是否有陌生自启脚本
ADV
  RC=0
fi

exit $RC
__DEVICEHUB_SCAN_EOF__
)


# =================================================================
# 系統主選單迴圈 (已置於最底部，保證所有函數都已提前載入)
# =================================================================
while true; do
    show_header
    show_system_status
    echo -e "${YELLOW}[  網絡情報與快速小抄 ]${NC}"
    echo -e " 1)  傳送門：打開 Telegram 官方發布源頭 (紙飛機群)"
    echo -e " 2)  查指令：查看 PC 端免 Root 隔空提取/雙分區刷入"
    echo -e " 3)  保命區：高通 / 天璣字庫與基帶備份還原小抄"
    echo ""
    echo -e "${YELLOW}[  系統增強與檢測軟體區 ]${NC}"
    echo -e " 4)  進入：手機常用工具組 (Android_Phone_Utilities)"
    echo -e " 5)  進入：手機視角傳電腦端 (Mobile phone to computer software)"
    echo -e " 6)  進入：環境檢測工具防線 (Environment_Check_Apps)"
    echo ""
    echo -e "${YELLOW}[  高階大師控端專區 ]${NC}"
    echo -e " 7）  進入：四大 Root 面具大本營 (阿爾法/SK/KSU/AP)"
    echo -e " 8)  進入：高級 Magisk / KSU 玩機模組分類庫"
    echo -e " 9)  進入：硬核玩機 Root_Tools_Pack 工具箱"
    echo -e " 10) 綜合安全檢測（Inte.ko + 遠控病毒）"
    echo -e " 11) shell腳本混淆"
    echo -e " 12) 安全退出工具箱"
    echo "-------------------------------------------------"
    echo -n "請輸入數字 (1-12): "
    read main_choice

    main_choice=$(echo "$main_choice" | tr -d '\r\n\t ')

    case "$main_choice" in
        1) tg_channels ;;
        2) show_header; echo -e "# =========================================
# 秒解 BL 鎖指令
fastboot flashing unlock 
# 如果以上指令不行請嘗試換這行
fastboot oem unlock
# =========================================
# 【解 BL 后、无 Root 权限】电脑端一键隔空提取原厂镜像
# =========================================

# 现代新机型提取指令：
fastboot fetch init_boot init_boot.img

# 老机型提取指令：
fastboot fetch boot boot.img
# =========================================
# 现代 Android 机型（init_boot 架构）面具刷入指令
# =========================================
# 1. 先進入 Fastboot 模式
adb reboot bootloader

# 2. 确认手机与电脑正常连接
fastboot devices

# 3. 刷入修补后的面具文件（建议双分区同时刷入，防止 Slot 错乱）
fastboot flash init_boot_a patched_init_boot.img
fastboot flash init_boot_b patched_init_boot.img

# 4. 刷回原厂文件（用于拔除 Root 或救砖）
fastboot flash init_boot_a init_boot.img
fastboot flash init_boot_b init_boot.img

# 5. 重启进入系统
fastboot reboot

# =========================================
# 老機型（boot 架构）刷入指令
# =========================================

# 老机型但是双分区
# 1. 先進入 Fastboot 模式
adb reboot bootloader

# 2. 确认连接
fastboot devices

# 3. 刷入修补后的面具 boot 镜像（两面都刷，防止 Slot 错乱）
fastboot flash boot_a patched_boot.img
fastboot flash boot_b patched_boot.img

# 4. 刷回原厂 boot 镜像（用于拔除 Root 或救砖）
fastboot flash boot_a boot.img
fastboot flash boot_b boot.img

# 5. 重启系统
fastboot reboot

# 老机型单分区
# 1. 先進入 Fastboot 模式
adb reboot bootloader

# 2. 确认连接
fastboot devices

# 3. 直接刷入修补后的面具 boot 镜像
fastboot flash boot patched_boot.img

# 4. 直接刷回原厂 boot 镜像（救砖）
fastboot flash boot boot.img

# 5. 重启系统
fastboot reboot
"; echo "-------------------------------------------------"; echo -n "按任意鍵返回..."; read -n 1 ;;
        3) show_header; echo -e "# =========================================
# 高通驍龍（Snapdragon）核心字庫保命還原指令
# =========================================
#擷取字庫指令（手機端 Termux 執行）

#先進入超級使用者模式
su

#在輸入以下指令

dd if=/dev/block/by-name/modemst1 of=/sdcard/modemst1.img
dd if=/dev/block/by-name/modemst2 of=/sdcard/modemst2.img
dd if=/dev/block/by-name/fsg of=/sdcard/fsg.img
dd if=/dev/block/by-name/fsc of=/sdcard/fsc.img
dd if=/dev/block/by-name/persist of=/sdcard/persist_snapdragon.img
dd if=/dev/block/by-name/devinfo of=/sdcard/devinfo.img
dd if=/dev/block/by-name/modem_a of=/sdcard/modem_a.img
dd if=/dev/block/by-name/modem_b of=/sdcard/modem_b.img

# 刷入基帶跟字庫（電腦端執行） 
# 1.【關鍵】先從一般 Fastboot 切換進入 Userspace Fastbootd 模式（解除寫入保護）
#先執行這個
adb reboot bootloader
#再執行這個
fastboot reboot fastboot

# 2. 依序還原閃存基頻與感測器分區
fastboot flash modemst1 modemst1.img
fastboot flash modemst2 modemst2.img
fastboot flash fsg fsg.img
fastboot flash fsc fsc.img
fastboot flash persist persist_snapdragon.img
fastboot flash devinfo devinfo.img
fastboot flash modem_a modem_a.img
fastboot flash modem_b modem_b.img

# 3.重啟進入系統
fastboot reboot

# =========================================
# 天璣（MTK）字庫指令
# =========================================
# 提取基帶跟字庫（手机端 Termux 执行）
su

dd if=/dev/block/by-name/nvram of=/sdcard/nvram.img
dd if=/dev/block/by-name/nvdata of=/sdcard/nvdata.img
dd if=/dev/block/by-name/nvcfg of=/sdcard/nvcfg.img
dd if=/dev/block/by-name/persist of=/sdcard/persist.img
dd if=/dev/block/by-name/protect1 of=/sdcard/protect1.img
dd if=/dev/block/by-name/protect2 of=/sdcard/protect2.img
dd if=/dev/block/by-name/seccfg of=/sdcard/seccfg.img
dd if=/dev/block/by-name/md_sec of=/sdcard/md_sec.img
dd if=/dev/block/by-name/modem_a of=/sdcard/modem_a.img
dd if=/dev/block/by-name/modem_b of=/sdcard/modem_b.img
dd if=/dev/block/mmcblk0boot0 of=/sdcard/preloader_boot0.img
dd if=/dev/block/mmcblk0boot1 of=/sdcard/preloader_boot1.img


刷入基帶跟字庫（电脑端执行）
1. 【关键】先切换进入 Userspace Fastbootd 模式（解除写入保护）

adb reboot bootloader
fastboot reboot fastboot


2. 依次閃存還原分區（若為單一分割槽或自動識別）

fastboot flash nvram nvram.img
fastboot flash nvdata nvdata.img
fastboot flash nvcfg nvcfg.img
fastboot flash persist persist.img
fastboot flash protect1 protect1.img
fastboot flash protect2 protect2.img
fastboot flash seccfg seccfg.img
fastboot flash md_sec md_sec.img
fastboot flash modem_a modem_a.img
fastboot flash modem_b modem_b.img


如果電腦提示：cannot find partition，那麼請換這一行：
fastboot flash nvram nvram.img
fastboot flash nvdata nvdata.img
fastboot flash nvcfg nvcfg.img
fastboot flash persist persist.img
fastboot flash protect1 protect1.img
fastboot flash protect2 protect2.img
fastboot flash seccfg seccfg.img
fastboot flash md_sec md_sec.img
fastboot flash modem_a modem_a.img
fastboot flash modem_b modem_b.img
fastboot flash preloader_a preloader_boot0.img
fastboot flash preloader_b preloader_boot1.img

3. 重启进入系统
fastboot reboot
"
echo "-------------------------------------------------"
echo -n "按任意鍵返回..."
read -n 1
;;
           4) scan_and_install "Android_Phone_Utilities/" ;;
           5) scan_and_install "Android_Phone_Utilities/Mobile phone to computer software/" ;;
           6) scan_and_install "Environment_Check_Apps/" ;;
           7) root_mask_menu ;;
           8) advanced_modules_menu ;;
           9) root_tools_pack_menu ;;
          10) run_security_scans ;;
          11) shell_obfuscation;;
          12) echo "已安全退出頂級搞機軍火庫。"; exit 0 ;;
*) echo -e "${RED}無效輸入！您的輸入為: [$main_choice]${NC}" ; sleep 1.5 ;;
esac
done
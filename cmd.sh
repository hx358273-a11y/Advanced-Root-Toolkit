#!/system/bin/sh

# =================================================================
#               Top Root Arsenal - Interactive Panel
#                 開發者：抖音user哥 (TikTok user_Bro)
# =================================================================

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

# 顏色定義
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
PURPLE='\e[1;35m'
CYAN='\e[1;36m'
NC='\e[0m'

# Zygisk Next (zn-daemon) 進程狀態即時監測
check_zygisk_status() {
    if pgrep -f "zn-daemon" >/dev/null 2>&1; then
        echo -e "${GREEN}[核心狀態] Zygisk Next (zn-daemon) 已成功注入執行中！${NC}"
    elif pgrep -f "zygisk" >/dev/null 2>&1; then
        echo -e "${YELLOW}[核心狀態] 偵測到舊版 Zygisk 守護進程。${NC}"
    else
        echo -e "${RED}[核心狀態] 未偵測到 Zygisk 環境 (可能需要重啟或處於非隱蔽狀態)${NC}"
    fi
}

show_header() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${GREEN}             頂級搞機軍火庫 (互動面板)           ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e " 開發者：抖音user哥"
    check_zygisk_status
    echo ""
}

# 智慧一加檢測指令直達攔截器
run_oneplus_bypass() {
    local target_path="$BASE_DIR/Root_Tools_Pack/OnePlus Integrity & Anti-Cheat Bypass"
    
    show_header
    echo -e "${YELLOW}⚠️ [ 頂級特種兵防線 - 智慧攔截提示 ]${NC}"
    echo -e "${CYAN}此目錄為硬核指令專區，內含一加內核解密與反作弊偵測腳本。${NC}"
    echo "-------------------------------------------------"
    echo -ne "${PURPLE}是否立刻載入並執行一加核心完整性 (Inte.ko) 檢測腳本？(y/n): ${NC}"
    read op_confirm
    op_confirm=$(echo "$op_confirm" | tr -d '\r\n\t ')
    
    if [ "$op_confirm" = "y" ] || [ "$op_confirm" = "Y" ]; then
        if [ ! -d "$target_path" ]; then
            echo -e "${RED}錯誤: 找不到檢測路徑！請確認目錄存在。${NC}"
            sleep 2
            return
        fi
        
        cd "$target_path" || return
        local found_sh=0
        for sh_file in *.sh; do
            if [ -f "$sh_file" ]; then
                found_sh=1
                echo -e "${GREEN}\n[執行中] 正在呼叫內核解密：$sh_file ...${NC}"
                chmod +x "$sh_file"
                sh "$sh_file"
                echo "-------------------------------------------------"
            fi
        done
        
        if [ "$found_sh" -eq 0 ]; then
            echo -e "${RED}\n提示：該資料夾內目前沒有發現任何可執行的 .sh 腳本。${NC}"
        fi
        echo -n "指令執行流程結束，按任意鍵返回..."
        read -n 1
    else
        echo -e "${YELLOW}\n操作已取消，正在安全退回主面板...${NC}"
        sleep 1
    fi
}

# 掃描與安裝核心函數
scan_and_install() {
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
                cp "$apk" /data/local/tmp/runtime_temp_mask.apk
                chmod 777 /data/local/tmp/runtime_temp_mask.apk
                
                if pm install -r /data/local/tmp/runtime_temp_mask.apk >/dev/null 2>&1; then
                    echo -e "[ ${GREEN}成功${NC} ]"
                else
                    echo -e "[ ${RED}失敗：請檢查簽名或版本${NC} ]"
                fi
                rm -f /data/local/tmp/runtime_temp_mask.apk
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
                cp "$target_apk" /data/local/tmp/runtime_temp_mask.apk
                chmod 777 /data/local/tmp/runtime_temp_mask.apk
                
                if pm install -r /data/local/tmp/runtime_temp_mask.apk; then
                    echo -e "${GREEN} [成功] 安裝流程執行完畢！${NC}"
                else
                    echo -e "${RED} [失敗] 安裝終止，可能是裝置已存在衝突簽名或不允許版本降級。${NC}"
                fi
                rm -f /data/local/tmp/runtime_temp_mask.apk
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
}

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
        echo -e " 4)  ⚡直達：一加內核防護與反作弊檢測 (OnePlus Integrity & Bypass)"
        echo -e " 5)  進入：硬核玩機高權限軟體 (Root-Required Apps)"
        echo -e " 6)  進入：Shizuku 免 Root 權限大師專區 (Shizuku & Root Power Users)"
        echo -e " 0)  返回主選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-6): "
        read tool_pack_choice
        tool_pack_choice=$(echo "$tool_pack_choice" | tr -d '\r\n\t ')
        
        case "$tool_pack_choice" in
            0|"") break ;;
            1) scan_and_install "Root_Tools_Pack/HyperOS Zone/" ;;
            2) scan_and_install "Root_Tools_Pack/Jailbreak Hub/" ;;
            3) scan_and_install "Root_Tools_Pack/Must-Have LSPosed Modules/" ;;
            4) run_oneplus_bypass ;; 
            5) scan_and_install "Root_Tools_Pack/Root-Required Apps/" ;;
        5) scan_and_install "Root_Tools_Pack/Root-Required Apps/" ;;
        6) scan_and_install "Root_Tools_Pack/Shizuku & Root Power Users Zone/" ;;
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
        echo -e " 7)  ReSuKISU (上游炸了停更版)"
        echo -e " 8)  Sukisu Ultra (內含 AK3.zip)"
        echo -e " 9)  進入：Wild_KSU 專區"
        echo -e " 10) ZySU 專區 (⚠️不支援 4.x & 5.x 內核)"
        echo -e " 11) 直達 KernelSU 基礎主目錄"
        echo -e " 0)  返回上級選單"
        echo "-------------------------------------------------"
        echo -n "請輸入編號 (0-11): "
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
                    echo -e "${BLUE}>> KernelSU-Next 分流面板${NC}"
                    echo -e " 1) KernelSU-Next 原版目錄"
                    echo -e " 2) 隨機包名隱蔽混淆版"
                    echo -e " 0) 返回 KSU 選單"
                    echo "-------------------------------------------------"
                    echo -n "請選擇: "
                    read next_choice
                    next_choice=$(echo "$next_choice" | tr -d '\r\n\t ')
                    case "$next_choice" in
                        0|"") break ;;
                        1) scan_and_install "$R/kernelSU-Next/" ;;
                        2) scan_and_install "$R/kernelSU-Next/Package name obfuscation version/" ;;
                        *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            5) scan_and_install "$R/Ksu Jailbreak/" ;;
            6) scan_and_install "$R/MizuSU/" ;;
            7) scan_and_install "$R/ReSuKISU (Broken upstream, unable to update)/" ;;
            8) scan_and_install "$R/Sukisu Ultra (AK3.zip included)/" ;;
            9) 
                while true; do
                    show_header
                    echo -e "${BLUE}>> Wild_KSU 分流面板${NC}"
                    echo -e " 1) Wild_KSU 原版目錄"
                    echo -e " 2) 隨機包名隱蔽混淆版"
                    echo -e " 0) 返回 KSU 選單"
                    echo "-------------------------------------------------"
                    echo -n "請選擇: "
                    read wild_choice
                    wild_choice=$(echo "$wild_choice" | tr -d '\r\n\t ')
                    case "$wild_choice" in
                        0|"") break ;;
                        1) scan_and_install "$R/Wild_KSU/" ;;
                        2) scan_and_install "$R/Wild_KSU/Package name obfuscation version/" ;;
                        *) echo -e "${RED}輸入錯誤！${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            10) scan_and_install "$R/ZySU (Unsupported on Kernel v4.x & v5.x !!!)/" ;;
            11) scan_and_install "$R/" ;;
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

# =================================================================
# 系統主選單迴圈 (已置於最底部，保證所有函數都已提前載入)
# =================================================================
while true; do
    show_header
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
    echo -e " 10) 安全退出工具箱"
    echo "-------------------------------------------------"
    echo -n "請輸入數字 (1-10): "
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
# 高通骁龙（Snapdragon）核心字库保命还原指令
# =========================================
# 提取字库指令（手机端 Termux 执行）

# 先進入超級使用者模式
su

# 再輸入以下指令
dd if=/dev/block/by-name/modemst1 of=/sdcard/modemst1.img
dd if=/dev/block/by-name/modemst2 of=/sdcard/modemst2.img
dd if=/dev/block/by-name/fsg of=/sdcard/fsg.img
dd if=/dev/block/by-name/persist of=/sdcard/persist_snapdragon.img
dd if=/dev/block/by-name/devinfo of=/sdcard/devinfo.img

# 刷入基帶跟字庫（电脑端执行）
# 1. 【关键】先从普通 Fastboot 切换进入 Userspace Fastbootd 模式（解除写入保护）
adb reboot bootloader
fastboot reboot fastboot

# 2. 依次闪存还原基带与传感器分区
fastboot flash modemst1 modemst1.img
fastboot flash modemst2 modemst2.img
fastboot flash fsg fsg.img
fastboot flash persist persist_snapdragon.img
fastboot flash devinfo devinfo.img

# 3. 重启进入系统
fastboot reboot

# =========================================
# 天璣（MTK）字庫指令
# =========================================
# 提取基帶跟字庫（手机端 Termux 执行）
su

dd if=/dev/block/by-name/nvram    of=/sdcard/nvram.img
dd if=/dev/block/by-name/nvdata   of=/sdcard/nvdata.img
dd if=/dev/block/by-name/persist  of=/sdcard/persist.img
dd if=/dev/block/by-name/protect1 of=/sdcard/protect1.img
dd if=/dev/block/by-name/protect2 of=/sdcard/protect2.img
dd if=/dev/block/by-name/seccfg   of=/sdcard/seccfg.img
dd if=/dev/block/by-name/preloader of=/sdcard/preloader.img

刷入基帶跟字庫（电脑端执行）
1. 【关键】先切换进入 Userspace Fastbootd 模式（解除写入保护）

adb reboot bootloader
fastboot reboot fastboot

2. 依次閃存還原分區
fastboot flash nvram nvram.img
fastboot flash nvdata nvdata.img
fastboot flash persist persist.img
fastboot flash protect1 protect1.img
fastboot flash protect2 protect2.img
fastboot flash seccfg seccfg.img
fastboot flash preloader preloader.img

如果電腦提示：cannot find partition，那麼請換這一行：
fastboot flash nvram nvram.img
fastboot flash nvdata nvdata.img
fastboot flash persist persist.img
fastboot flash protect1 protect1.img
fastboot flash protect2 protect2.img
fastboot flash preloader_a preloader.img
fastboot flash preloader_b preloader.img
fastboot flash seccfg seccfg.img
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
          10) echo "已安全退出頂級搞機軍火庫。"; exit 0 ;;
*) echo -e "${RED}無效輸入！您的輸入為: [$main_choice]${NC}" ; sleep 1.5 ;;
esac
done

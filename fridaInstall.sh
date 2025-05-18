#!/usr/bin/env bash
# Author: Lautaro D. Villarreal Culic'
# https://lautarovculic.com

## Colors ------------------------------------------------------------------------------
green="\e[1;32m"; red="\e[1;31m"; blue="\e[1;34m"; yel="\e[1;33m"; end="\e[0m"

## Ctrl-C ------------------------------------------------------------------------------
trap 'echo -e "\n${red}[*] Exit${end}\n"; exit 1' INT

## Util --------------------------------------------------------------------------------
err() { echo -e "${red}[!] $*${end}"; }
ok () { echo -e "${green}[✓] $*${end}"; }
inf() { echo -e "${blue}[*] $*${end}"; }

need_bin() { command -v "$1" >/dev/null || { err "$1 required"; exit 1; }; }

## Checks ------------------------------------------------------------------------------
need_bin adb
need_bin curl
need_bin jq

## Device Select -----------------------------------------------------------------------
select_device() {
    inf "Searching devices…"

    mapfile -t devs < <(adb devices | awk '$2=="device"{print $1}')

    [[ ${#devs[@]} -eq 0 ]] && { err "No devices detected. Plase, connect via USB or launch your Genymotion"; exit 1; }

    if [[ ${#devs[@]} -gt 1 ]]; then
        printf "${yel}Select device:${end}\n"
        for i in "${!devs[@]}"; do printf "  [%d] %s\n" "$((i+1))" "${devs[i]}"; done
        read -rp " > " idx
        device="${devs[$((idx-1))]}"
    else
        device="${devs[0]}"
    fi
    ok "Device: $device"
}

## Detect Arch -------------------------------------------------------------------------
detect_arch() {
    abi=$(adb -s "$device" shell getprop ro.product.cpu.abi | tr -d '\r')
    case "$abi" in
        arm64-v8a) arch="android-arm64";;
        armeabi-v7a) arch="android-arm";;
        x86)         arch="android-x86";;
        x86_64)      arch="android-x86_64";;
        *) err "Unknown ABI: $abi"; exit 1;;
    esac
    ok "ABI $abi mapped to asset $arch"
}

## Download latest frida-server --------------------------------------------------------
download_frida() {
    inf "Resolving latest version…"
    tag=$(curl -s https://api.github.com/repos/frida/frida/releases/latest | jq -r .tag_name)
    [[ "$tag" == "null" || -z "$tag" ]] && { err "Error obtaining version"; exit 1; }

    asset="frida-server-${tag#v}-${arch}.xz"
    url="https://github.com/frida/frida/releases/download/${tag}/${asset}"
    inf "Downloading $asset"
    curl -L "$url" -o "$asset" || { err "Download failed"; exit 1; }

    inf "Unzipping…"
    xz -d "$asset"                        # drop frida-server-*-arch
    bin="${asset%.xz}"                    # name without .xz
    chmod +x "$bin"
}

## Push & Run --------------------------------------------------------------------------
deploy_frida() {
    inf "Sending binary…"
    adb -s "$device" push "$bin" /data/local/tmp/ >/dev/null

    inf "Setting perms & killing previous instances…"
    adb -s "$device" shell "su -c 'chmod 755 /data/local/tmp/$bin && pkill -f $bin || true'"

    inf "Launching frida-server in background…"
    adb -s "$device" shell "su -c '/data/local/tmp/$bin &'" && sleep 1

    adb -s "$device" shell "su -c 'pgrep -f $bin'" >/dev/null \
        && ok "frida-server running..." \
        || err "Not started; check SELinux or root"
}

########################################################################################
select_device
detect_arch
download_frida
deploy_frida

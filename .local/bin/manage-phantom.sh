#!/data/data/com.termux/files/usr/bin/bash

program_name="$(basename $0)"

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ESC=255}

function cleanup_and_exit() {
	clear
	adb kill-server
	echo "Dibatalkan. Interupsi Keyboard CTRL+C"; exit 0
}
trap cleanup SIGINT SIGTERM

function input_ip_address() {
    local msg="Enter IP address"
    while true; do
        ip_address=$(dialog --backtitle "$program_name" --title "$@" \
        	--inputbox "$msg" 0 0 --stdout)

        exit_code=$?
        clear
        case $exit_code in
			$DIALOG_CANCEL) echo "Cancel is pressed, exiting the program $program_name"; exit 0 ;;
			$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
		esac

        if [[ -z "$ip_address" ]]; then
           local  msg="The IP column cannot be empty! Example: 192.168.1.255"
        # Regex sederhana untuk validasi format IP (angka.angka.angka.angka)
        elif [[ ! "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
           local  msg="Incorrect IP format! Example: 192.168.1.255"
        else
            break
        fi
    done
}

function input_port() {
    local msg="Enter Port number"
    while true; do
        port=$(dialog --backtitle "$program_name" --title "$@" \
            --inputbox "$msg" 0 0 --stdout)

        exit_code=$?
        clear
        case $exit_code in
			$DIALOG_CANCEL) echo "Cancel is pressed, exiting the program $program_name"; exit 0 ;;
			$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
		esac

        if [[ -z "$port" ]]; then
           local msg="The port column cannot be empty! Example: 12345"
        elif [[ ! "$port" =~ ^[0-9]+$ ]]; then
           local msg="Port must be numeric! Example: 12345"
        else
            break
        fi
    done
}

function input_pairing_code() {
	local msg="Enter the Pairing Code number"
	while true; do
		pairing_code=$(dialog --cancel-label "Exit" --backtitle "$program_name" --title "$@" \
			 --inputbox "$msg" 0 0 --stdout)

        exit_code=$?
        clear
        case $exit_code in
			$DIALOG_CANCEL) echo "Cancel is pressed, exiting the program $program_name"; exit 0 ;;
			$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
		esac

        if [[ -z "$pairing_code" ]]; then
            local msg="The pairing code column cannot be empty! Example: 12345"
        elif [[ ! "$pairing_code" =~ ^[0-9]+$ ]]; then
            local msg=" Pairing Code must be a number! Example: 12345"
        else
            break
        fi
    done
}

function adb_check() {
    if [[ -z "$(adb devices | grep -v 'List of devices attached' | grep 'device')" ]]; then
        dialog --backtitle "$program_name" --title "ADB Devices" \
            --msgbox "No devices connected on adb! \
                \nPlease run adb pair and connect first." 7 50

		exit_code=$?
		clear
		case $exit_code in
			$DIALOG_OK) main_course ;;
			$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
		esac
    fi
}

function adb_pair_and_connect() {
    while true; do
        CHOISE=$(dialog --backtitle "$program_name" --title "Android Debug Bridge (ADB)" \
            --extra-button --extra-label "Main Course" \
            --menu "Please select the adb command option below:" 11 50 3 \
            "1" "ADB Pair" \
            "2" "ADB Connect" \
            "3" "ADB Devices" \
            --stdout)

        exit_code=$?
        clear
        case $exit_code in
			$DIALOG_CANCEL) echo "Cancel is pressed, exiting the program $program_name"; exit 0 ;;
			$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
			$DIALOG_EXTRA) main_course ;;
		esac

        case "$CHOISE" in
            1)
                input_ip_address "ADB Pair"
                input_port "ADB Pair"
                input_pairing_code "ADB Pair"
                dialog --backtitle "$program_name" --prgbox "ADB Pair" \
                    "adb pair $ip_address:$port $pairing_code" 10 85;;
            2)
                input_ip_address "ADB Connect"
                input_port "ADB Connect"
                dialog --backtitle "$program_name" --prgbox "ADB Connect" \
                    "adb connect $ip_address:$port && adb devices" 15 70;;
            3)
                dialog --backtitle "$program_name" --prgbox "ADB Devices" "adb devices" 15 70;;
        esac
    done
}

function show_status() {
    local android_version="$(adb shell getprop ro.build.version.release)"

    if [[ "$android_version" -gt 12 ]]; then
        local action_sync="get_sync_disabled_for_tests"
    else
        local action_sync="is_sync_disabled_for_tests"
    fi

    local max=$(adb shell "/system/bin/device_config get activity_manager max_phantom_processes")
    local sync=$(adb shell "/system/bin/device_config $action_sync")
    local monitor=$(adb shell "settings get global settings_enable_monitor_phantom_procs")

    if [[ -z "$max" || "$max" == "null" ]]; then
        max="$max/32 (Default)"
    fi

    dialog --backtitle "$program_name" --title "Current Status:" \
        --msgbox \
        "Max Phantom Processes : $max \
        \nSync Disabled         : $sync \
        \nMonitor Enabled       : $monitor" 0 0

	exit_code=$?
    clear
    case $exit_code in
    	$DIALOG_OK) main_course ;;
		$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
	esac
}

function optimize() {
    adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
    adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
    adb shell "settings put global settings_enable_monitor_phantom_procs false"
}

function restore() {
    adb shell "/system/bin/device_config delete activity_manager max_phantom_processes"
    adb shell "/system/bin/device_config set_sync_disabled_for_tests none"
    adb shell "settings put global settings_enable_monitor_phantom_procs true"
}

function main_course() {
    CHOICE=$(dialog --backtitle "$program_name" --title "Android Phantom Process Manager" \
        --menu "Please select the command menu option below:" 8 55 0 \
            "1" "Check Status" \
            "2" "Turn off Phantom Killer (Optimization)" \
            "3" "Reactivate Phantom Killer (Restore)" \
            "4" "ADB Pair and Connect" \
            --stdout)

	exit_code=$?
	clear
	case $exit_code in
		$DIALOG_CANCEL) echo "Cancel is pressed, exiting the program $program_name"; exit 0 ;;
		$DIALOG_ESC) echo "ESC is pressed, exiting the program $program_name"; exit 0 ;;
	esac

    case "$CHOICE" in
        1) adb_check; show_status ;;
        2) adb_check; optimize &>/dev/null && show_status ;;
        3) adb_check; restore &>/dev/null && show_status ;;
        4) adb_pair_and_connect;;
    esac
}

adb start-server
main_course

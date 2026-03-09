#!/data/data/com.termux/files/usr/bin/bash
set -u

TERMUX__ROOTFS_DIR="/data/data/com.termux/files"
program_name=$(basename "$0")
backup_storage="/sdcard"
timestamp=$(date "+%Y-%m-%d_%H%M%S")
backup_directory="$backup_storage/termux"
excludes=()

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_ESC=255}

# Trap untuk hapus file sisa jika skrip di stop paksa (Ctrl+C)
function cleanup() {
	clear
    echo "Dibatalkan. Interupsi Keyboard CTRL+C"
    [[ -f "${backup_file:-}" ]] && shred -zuf "$backup_file"
    # Cari dan Hapus direktori backup (/sdcard/termux) yang dibuat jika kosong
    find "$backup_storage/" -maxdepth 1 -type d -name termux -empty -delete
    exit
}; trap cleanup SIGINT SIGTERM

function check_storage_and_directory() {
if [[ -d "$backup_storage" ]]; then
    if [[ ! -w "$backup_storage" ]]; then
        echo "Izin penyimpanan ditolak!"
        echo "Jalankan termux-setup-storage terlebih dahulu."
        exit 1
    fi
    [[ ! -d "$backup_directory" ]] && mkdir "$backup_directory"
else
    echo "$program_name: Error: Direktori penyimpanan $backup_storage tidak ada!"
    exit 2
fi
}

function option_selection() {
    CHOISE=$(dialog --backtitle "$program_name" --title "Pilih target pencadangan" \
            --menu "Tips Gunakan ~/exclude.list untuk mengabaikan file atau direktori" 9 60 0 \
            "1"     "HOME/Pengguna ($HOME)" \
            "2"     "PREFIX/Sistem ($PREFIX)" \
            "3"     "Seluruhnya (\$PREFIX dan \$HOME)" \
            --stdout)
    exit_code=$?
    clear

    case $exit_code in
        $DIALOG_CANCEL) echo "Cancel ditekan, keluar dari program $program_name."; exit ;;
        $DIALOG_ESC) echo "ESC ditekan, keluar dari program $program_name."; exit ;;
        $DIALOG_OK)
			if [[ -n $CHOISE ]]; then
				case $CHOISE in
		    		1) target=("home"); suffix="home"; excludes+=("--exclude=usr") ;;
		    		2) target=("usr"); suffix="usr"; excludes+=("--exclude=home") ;;
		        	3) target=("usr" "home"); suffix="all" ;;
		    	esac
		    fi
		;;
	esac
}

function backup_process() {
    if [[ -f ~/exclude.list ]]; then
        excludes+=("--exclude-from=$HOME/exclude.list" "--exclude=exclude.list")
    fi

    backup_filename="backup-termux-${suffix}-${timestamp}.tar.gz"
    backup_file="$backup_directory/$backup_filename"

    if ! tar --verbose -czf "$backup_file" -C "$TERMUX__ROOTFS_DIR" "${excludes[@]}" "${target[@]}"; then
        echo "$program_name: Gagal membuat cadangan!"
        shred -zuf "$backup_file"
        exit 3
    fi
}

function encrypt_process() {
    backup_file_encrypted="${backup_file}.enc"

    while true; do
        local pass=$(dialog --backtitle "$program_name" --title "Enkripsi OpenSSL" --no-cancel \
            --insecure --passwordbox "Masukkan kata sandi enkripsi AES-256-CBC:" 8 55 --stdout)

        local pass_confirm=$(dialog --backtitle "$program_name" --title "Enkripsi OpenSSL" --no-cancel \
            --insecure --passwordbox "Memverifikasi - masukkan kembali kata sandi enkripsi AES-256-CBC:" 8 55 --stdout)

        if [[ "$pass" == "$pass_confirm" && -n "$pass" ]]; then
            clear
            echo "Mengenkripsi $backup_file..."
            if ! openssl enc -e -v -pbkdf2 -salt -aes-256-cbc -in "$backup_file" -out "$backup_file_encrypted" -pass fd:3 3<<< "$pass"; then
                dialog --backtitle "$program_name" --title "Error" \
                    --msgbox "Gagal melakukan enkripsi. Coba lagi." 6 50
            else
                break
            fi
        else
            dialog --backtitle "$program_name" --title "Error" \
                --msgbox "Kata sandi tidak cocok atau kosong! Silakan ulangi." 6 50
        fi
    done
}

function main() {
    check_storage_and_directory
    option_selection
    backup_process

    dialog --backtitle "$program_name" --title "Enkripsi OpenSSL" \
        --yesno "Apakah ingin mengenkripsi file cadangan?" 0 0

    exit_code=$?
    clear

    if [[ $exit_code -eq $DIALOG_CANCEL || $exit_code -eq $DIALOG_ESC ]]; then
        echo "File cadangan tidak terenkripsi berhasil dibuat:"
        ls -lFh "$backup_file"
    elif [[ $exit_code -eq $DIALOG_OK ]]; then
        encrypt_process

        echo "Menghapus file cadangan tidak terenkripsi (shred)..."
        shred -zuf "$backup_file" && echo "Selesai!"

        echo "File hasil cadangan terenkripsi:"
        ls -lFh "$backup_file_encrypted"
    fi

    echo "Pencadangan Selesai!"
}

# Eksekusi Utama
main

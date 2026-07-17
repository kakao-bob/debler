#!/bin/bash

# DebLer - .deb installer for non-debian distros.
VERSION="1.1.0"
HELP="Usage:\n\tdebler -S <file.deb>  (install debian package)\n\tdebler -R <package> (remove installed package)\n\tdebler -Q (show all installed packages)\n\tdebler -h (show help)"

# install debian package
_debler_install() {

    # Первый аргумент всегда считаем путем к файлу
    FILE_PATH="$1"
    shift # Сдвигаем аргументы

    #root check
    if [[ $EUID -ne 0 ]]; then
    echo "[-] ERROR: Must be run as root."
    exit 1
    fi

    WORK_FOLDER="/tmp/debler_$(date +%s)"
    LOG_FILE="$WORK_FOLDER/debler.log"
    echo "[*] DebLer v$VERSION"
    echo "[*] Log: $LOG_FILE"
    echo ""

    echo "[+] Extracting package into /tmp/.."
    mkdir $WORK_FOLDER
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Strarting extracting.." >> "$LOG_FILE"
    ar x $FILE_PATH --output=$WORK_FOLDER/
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ok" >> "$LOG_FILE"


    echo "[+] Extracting control.."
    mkdir "$WORK_FOLDER/control_tar/"
    files=($WORK_FOLDER/control.tar.*)

    if [ -e "${files[0]}" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - control file: ${files[0]}" >> $LOG_FILE
        tar -xvf "${files[0]}" -C $WORK_FOLDER/control_tar/ > /dev/null 2>&1
    else
        echo "[-] ERROR: Corrupted package! No control.tar found"
        exit 1
    fi

    MS_POSTINST=0
    MS_PREINST=0

    # CHECKING maintscripts
    for file in $WORK_FOLDER/control_tar/*; do
        # Проверяем, существует ли файл
        [ -e "$file" ] || continue

        echo "$(date '+%Y-%m-%d %H:%M:%S') - CMS file found: $file" >> "$LOG_FILE"

        case $(basename $file) in
            "postinst")
                MS_POSTINST=1
                ;;
            "preinst")
                MS_PREINST=1
                ;;
            *)
                # default
                ;;
        esac
    done

    echo "----------------------"
    cat "$WORK_FOLDER/control_tar/control"
    echo "----------------------"

    read -p "[?] Install package? [Y/n]: " response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if [[ -z "$response" || "$response" == "y" || "$response" == "yes" ]]; then
        echo "ok..."

    else
        echo "[-] Cancelled."
        exit 0
    fi

    # preinst
    if [ $MS_PREINST -eq 1 ]; then

        read -p "[?] PREINST script found ($WORK_FOLDER/control_tar/preinst). Run it? [Y/n]: " answer
        if [[ -z "$answer" || "$answer" =~ ^[Yy] ]]; then
            echo "[+] Running preinst..."
            "$WORK_FOLDER/control_tar/preinst"
            echo "[*] Done."
        fi

    fi

    echo "[+] Extracting data.."
    mkdir "$WORK_FOLDER/data_tar/"
    files=($WORK_FOLDER/data.tar.*)

    if [ -e "${files[0]}" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - data file: ${files[0]}" >> $LOG_FILE
        tar -xvf "${files[0]}" -C $WORK_FOLDER/data_tar/ > /dev/null 2>&1
    else
        echo "[-] ERROR: Corrupted package! No data.tar found"
        exit 1
    fi


    # checking folders..
    for folder in "$WORK_FOLDER"/data_tar/*; do
        if [ -d "$folder" ]; then
            folder_bn=$(basename "$folder")
            echo "$(date '+%Y-%m-%d %H:%M:%S') - CF found: $folder_bn" >> $LOG_FILE


            if [[ ! "$folder_bn" =~ ^(usr|opt|etc|var)$ ]]; then
                echo "[-] ERROR: /$folder_bn is not a standard part of a .deb package."
                echo "This .deb file may be malware or formatted incorrectly. Cancelling install!"

                # logging
                echo "$(date '+%Y-%m-%d %H:%M:%S') - CRITICAL: Suspicious folder /$folder_bn found. Aborting." >> "$LOG_FILE"

                exit 1
            fi
        fi
    done

    echo "[+] Copying data to system.."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Copying data to /.." >> "$LOG_FILE"
    rsync -aHAXx --info=progress2 "$WORK_FOLDER"/data_tar/ /


    # postinst
    if [ $MS_POSTINST -eq 1 ]; then

        read -p "[?] POSTINST script found ("$WORK_FOLDER"/control_tar/postinst). Run it? [Y/n]: " answer
        if [[ -z "$answer" || "$answer" =~ ^[Yy] ]]; then
            echo "[+] Running postinst..."
            "$WORK_FOLDER/control_tar/postinst" configure
            echo "[*] Done."
        fi

    fi

    echo "[+] Cleanup.."
    rm -rf "$WORK_FOLDER"

    echo ""
    echo "---"
    echo "[*] Package installed successfully."
    exit 0

}


# checking for args
if [ $# -eq 0 ]; then
    echo "[-] Error: no arguments provided!"
    echo -e $HELP
    exit 1
fi

ACTION=$1
shift


_debler_install "123"
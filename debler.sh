#!/bin/bash

# DebLer - .deb installer for non-debian distros.
VERSION="1.1.0"
HELP="Usage:\n\tdebler -S <file.deb>  (install debian package)\n\tdebler -R <package> (remove installed package)\n\tdebler -Q (show all installed packages)\n\t├── debler -Q <search> (show requested packages)\n\t└── [--raw/--name] (formatting)\n\tdebler -h (show help)"
DB_ROOT="/var/lib/debler/local"

_check_root() {
    #root check
    if [[ $EUID -ne 0 ]]; then
        echo "[-] ERROR: Must be run as root."
        exit 1
    fi
}

# show installed packages
_debler_query() {
    mkdir -p "$DB_ROOT"

    for package_ in $(find "$DB_ROOT" -type d -name "$1*" -exec basename {} \;); do
        if [[ "$package_" == "local" ]]; then
            continue
        fi

        name="${package_%%-*}" # left part
        ver="${package_#*-}" # right part
        case $2 in
            "--raw")
                echo $package_
                ;;
            "--name")
                echo $name
                ;;
            *)
                # default
                echo "$name ($ver)"
                ;;
        esac

    done
}

# install debian package
_debler_install() {

    # Первый аргумент всегда считаем путем к файлу
    FILE_PATH="$1"
    shift # Сдвигаем аргументы

    if [ ! -e $FILE_PATH ]; then
        echo "[-] ERROR: File not exist."
        exit 1
    fi

    _check_root

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

    control_file="$WORK_FOLDER/control_tar/control"
    PKG_NAME=$(grep "Package: " $control_file | cut -c 10-)
    PKG_VERSION=$(grep "Version: " $control_file | cut -c 10-)

    echo "----------------------"
    cat $control_file
    echo "----------------------"

    # if already installed
    exist_=$(_debler_query "$PKG_NAME")
    if [ ! -z "$exist_" ]; then
        echo "[!] Package $PKG_NAME already installed!"
        read -p "[?] Remove '$exist_' and install '$PKG_NAME ($PKG_VERSION)'? [Y/n]: " response
    else
        read -p "[?] Install package '$PKG_NAME-$PKG_VERSION'? [Y/n]: " response
    fi

    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if [[ -z "$response" || "$response" == "y" || "$response" == "yes" ]]; then
        echo "ok..."

    else
        echo "[-] Cancelled."
        exit 0
    fi

    if [ ! -z "$exist_" ]; then
        _debler_remove $PKG_NAME "ok"
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

    # database
    echo "[+] Updating database.."
    DB_FOLDER="$DB_ROOT/$PKG_NAME-$PKG_VERSION/"
    mkdir -p "$DB_FOLDER"

    find "$WORK_FOLDER/data_tar/" -type f > "$DB_FOLDER/files" # finding all files which installed
    sed -i "s|$WORK_FOLDER/data_tar||g" "$DB_FOLDER/files" # removing substring
    cp "$WORK_FOLDER/control_tar/postrm" "$DB_FOLDER/postrm" 2>/dev/null # copying MS if exist
    cp "$WORK_FOLDER/control_tar/prerm" "$DB_FOLDER/prerm" 2>/dev/null


    echo "[+] Cleanup.."
    rm -rf "$WORK_FOLDER"

    echo ""
    echo "---"
    echo "[*] Package installed successfully."
    exit 0

}

_debler_remove() {
    exist_rm=$(_debler_query "$1" "--raw")


    if [ -z "$exist_rm" ]; then
        echo "[-] Error: package '$1' not installed."
        exit 1
    fi


    _check_root

    DB_FOLDER_RM="$DB_ROOT/$exist_rm"

    echo "[!] Next files will be deleted:"
    echo "----------------------"
    cat "$DB_FOLDER_RM/files"
    echo "----------------------"

    read -p "[?] Okay [Y/n]? " answer
    if [[ -z "$answer" || "$answer" =~ ^[Yy] ]]; then
        echo "ok.."
    else
        echo "[-] Cancelled."
        exit 1
    fi


    MS_PRERM=0
    MS_POSTRM=0
    # CHECKING maintscripts
    for file in $DB_FOLDER_RM/*; do
        # Проверяем, существует ли файл
        [ -e "$file" ] || continue

        case $(basename $file) in
            "prerm")
                MS_PRERM=1
                ;;
            "postrm")
                MS_POSTRM=1
                ;;
            *)
                # default
                ;;
        esac
    done

    # pre remove MS
    if [ $MS_PRERM -eq 1 ]; then
        read -p "[?] PRERM script found ($DB_FOLDER_RM/prerm). Run it? [Y/n]: " answer
        if [[ -z "$answer" || "$answer" =~ ^[Yy] ]]; then
            echo "[+] Running prerm..."
            "$DB_FOLDER_RM/prerm" remove
            echo "[*] Done."
        fi
    fi

    ## Deleting files
    for file in $(cat "$DB_FOLDER_RM/files"); do
        if [ -z "$file" ]; then
            continue
        fi
        if [[ "$file" == "/etc/*" ]]; then
            continue # do NOT touching etc configs
        fi

        echo "rm: $file"
        rm "$file"
    done

    # pre remove MS
    if [ $MS_POSTRM -eq 1 ]; then
        read -p "[?] POSTRM script found ($DB_FOLDER_RM/postrm). Run it? [Y/n]: " answer
        if [[ -z "$answer" || "$answer" =~ ^[Yy] ]]; then
            echo "[+] Running postrm..."
            "$DB_FOLDER_RM/postrm" remove
            echo "[*] Done."
        fi
    fi

    echo "[+] Updating database.."
    rm -rf "$DB_FOLDER_RM"

    echo "[+] '$1' removed."
}

_check_arg() {
    if [ -z "$1" ]; then
        echo "[-] Error: a required argument ($2) was not provided!"
        exit 1
    fi
}

# checking for args
if [ $# -eq 0 ]; then
    echo "[-] Error: no arguments provided!"
    echo -e $HELP
    exit 1
fi

ACTION=$1
shift

case $ACTION in
    "-S")
        _check_arg "$1" "<file.deb>"
        _debler_install $1
        ;;
    "-R")
        _check_arg "$1" "<package>"
        _debler_remove "$1"
        ;;
    "-Q")
        _debler_query "$1" "$2"
        ;;
    "-h")
        echo -e $HELP
        ;;
    *)
        # default
        echo "[-] Error: Wrong action."
        echo -e $HELP
        ;;
esac

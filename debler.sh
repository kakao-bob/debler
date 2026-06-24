#!/bin/bash

# DebLer - .deb installer for non-debian distros.
VERSION="0.1.0"

# checking for args
if [ $# -eq 0 ]; then
    echo "[-] Error: no arguments provided!"
    echo "Use: debler <file.deb>"
    exit 1
fi

# Первый аргумент всегда считаем путем к файлу
FILE_PATH="$1"
shift # Сдвигаем аргументы, чтобы обрабатывать флаги дальше


# root check
# if [[ $EUID -ne 0 ]]; then
#    echo "[-] ERROR: Must be run as root."
#    exit 1
# fi

WORK_FOLDER="/tmp/debler_$(date +%s)"
LOG_FILE="$WORK_FOLDER/debler.log"
echo "[*] DebLer v$VERSION"
echo "[*] Log: $LOG_FILE"
echo ""

echo "[+] Extracting package into /tmp/.."
mkdir $WORK_FOLDER
ar x $FILE_PATH --output=$WORK_FOLDER/


echo "[+] Extracting control.."
mkdir $WORK_FOLDER/control_tar/
files=($WORK_FOLDER/control.tar.*)

if [ -e "${files[0]}" ]; then
    echo "Первый найденный файл control: ${files[0]}" > $LOG_FILE
    tar -xvf "${files[0]}" -C $WORK_FOLDER/control_tar/ > /dev/null 2>&1
else
    echo "[-] ERROR: Corrupted package! No control.tar found"
    exit 1
fi

echo "----------------------"
cat $WORK_FOLDER/control_tar/control
echo "----------------------"



# echo "[+] Extracting data.."
# mkdir $WORK_FOLDER/data_tar/
# files=($WORK_FOLDER/data.tar.*)

# if [ -e "${files[0]}" ]; then
#     echo "Первый найденный файл data: ${files[0]}" > $LOG_FILE
#     tar -xvf "${files[0]}" -C $WORK_FOLDER/data_tar/ > /dev/null 2>&1
# else
#     echo "[-] ERROR: Corrupted package! No data.tar found"
#     exit 1
# fi

echo ""
echo "---"
echo "[*] Package installed successfully."
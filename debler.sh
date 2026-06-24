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
#    echo "[-] Must be run as root."
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
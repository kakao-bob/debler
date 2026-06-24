# DebLer
Installer for `.deb`-packages for non-debian Linux distros.

## Install

1. Make sure you have `rsync` installed.
2. Run:
```bash
sudo curl -SL "https://raw.githubusercontent.com/kakao-bob/debler/master/debler.sh" -o /usr/local/bin/debler && sudo chmod +x /usr/local/bin/debler
```

## Use
```bash
debler my_package.deb
```
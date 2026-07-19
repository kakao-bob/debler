# DebLer
Installer for `.deb` packages on non-Debian-based GNU/Linux distros.

[![Latest version](https://img.shields.io/static/v1?label=version&message=v1.1.0&color=64B5F6&style=flat)](#)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff)](#)
[![Linux](https://img.shields.io/badge/GNU/Linux-FCC624?logo=linux&logoColor=black)](#)
[![License](https://img.shields.io/badge/license-ISC-2B6DBE.svg?style=flat)](/LICENSE)

---

## Install / Update

1. Make sure you have `rsync` installed.
2. Run:
```bash
sudo curl -SL "https://raw.githubusercontent.com/kakao-bob/debler/master/debler.sh" -o /usr/local/bin/debler && sudo chmod +x /usr/local/bin/debler
```

## Use

 - Install `.deb`:
```bash
sudo debler -S <my_package.deb>
```
 - Remove installed package:
```bash
sudo debler -R <package>
```

 - Info about installed packages:
```bash
debler -Q <search>* [--raw/--name]*
```
 - List of installed files of package:
```bash
debler -Ql <package>
```
 - Help:
```bash
debler -h
```
`*` - optional parameter

## License
This repository is licensed under the ISC License. Read more: [LICENSE](/LICENSE)

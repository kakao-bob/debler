# DebLer
Installer for `.deb` packages on non-Debian-based GNU/Linux distros.

[![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=fff)](#)
[![Linux](https://img.shields.io/badge/GNU/Linux-FCC624?logo=linux&logoColor=black)](#)
[![Latest version](https://img.shields.io/static/v1?label=version&message=v1.0.0&color=64B5F6&style=flat)](#)
[![License](https://img.shields.io/badge/license-ISC-2B6DBE.svg?style=flat)](/LICENSE)

---

## Install / Update

1. Make sure you have `rsync` installed.
2. Run:
```bash
sudo curl -SL "https://raw.githubusercontent.com/kakao-bob/debler/master/debler.sh" -o /usr/local/bin/debler && sudo chmod +x /usr/local/bin/debler
```

## Use
```bash
sudo debler -S my_package.deb
```

## License
This repository is licensed under the ISC License. Read more: [LICENSE](/LICENSE)

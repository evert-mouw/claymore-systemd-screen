# claymore-systemd-screen/readme

## About

The [Claymore](https://github.com/nanopool/Claymore-Dual-Miner/releases) miner does not come with startup scripts for Linux. A few scripts are provided here.

Tested on an Arch Linux rig mining Ethereum (ETH).

## Scripts and files

`claymore.sh` starts or stops the claymore miner in a [screen](https://www.gnu.org/software/screen/) session. Use one of the following arguments: `start | stop | status | help`

`claymore.service` is a [systemd](https://www.freedesktop.org/wiki/Software/systemd/) service file. It makes use of `claymore.sh` 

The `intel-video` folder contains a configuration file for Xorg to help you attaching a monitor to your rig without disrupting the mining GPUs. Read `intel-for-xorg.md`.

## Version

- 2017-12-11 Evert Mouw <post@evert.net>

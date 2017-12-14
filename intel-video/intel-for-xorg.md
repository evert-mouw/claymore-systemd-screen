# Avoid mining GPUs for Xorg

If you use AMD of Nvidia GPUs for mining, and you have an Intel video chip in your mobo or CPU, then you probably want to use the Intel chipset when attaching a monitor. Starting Xorg will be dangerous; it will probe all graphics devices. Such did freeze my computer as I already was mining before manually starting X.

Solution: specify the devices section in the xorg.conf.

	cp 20-intel.conf to /etc/X11/xorg.conf.d/

Unfortunately we need the old xf86-video-intel driver to specify a driver, because otherwise modesetting will be used. More information:

https://wiki.archlinux.org/index.php/intel_graphics

Let's go then. On Arch, that would mean:

	pacman -S xf86-video-intel

And you probably also want:

	pacman -S mesa mesa-demos

Anyway although the driver is older, at least while using XFCE4 now Chromium respects the "reserve space" of the panel settings again.

Evert Mouw <post@evert.net>

2017-12-11


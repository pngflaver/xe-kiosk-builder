# Knowledge Base

This document explains the technologies utilized in the Jumpbox Kiosk project and how they integrate to provide a seamless diskless boot experience.

## Network Booting (PXE, TFTP, DHCP)

- **PXE (Preboot eXecution Environment)**: A client/server interface that allows networked computers to boot from an OS located on the network instead of local storage. The client's BIOS/UEFI is configured to boot via PXE.
- **DHCP (Dynamic Host Configuration Protocol)**: When the client powers on, it broadcasts a DHCP request. The DHCP server assigns it an IP address and provides the `next-server` (IP of the TFTP server) and the boot filename.
- **TFTP (Trivial File Transfer Protocol)**: Used to download the initial bootloader (usually an iPXE or grub binary) from the server to the client. Once the bootloader is running, it can fetch the larger OS image (the ISO) via HTTP or other protocols, which is much faster than TFTP.

## Network Infrastructure (STP)

- **Spanning Tree Protocol (STP)**: Prevents network loops in switches. A common issue encountered during PXE boot is STP delay: standard STP takes ~30 seconds to transition a port from blocking to forwarding. This delay can cause the client's early PXE DHCP requests to timeout. 
  - **Solution**: Configure `PortFast` or `RSTP` (Rapid Spanning Tree Protocol) on the switch port connected to the client to ensure the port transitions to forwarding immediately. The custom ISO also incorporates network retry loops (`ethdevice-timeout=60`) to handle delays effectively.

## Operating System & Build Tools

- **Debian live-build**: A set of scripts used to build custom Debian Live system images. `live-build` is used to generate the custom ISO, ensuring it includes necessary firmware (like `firmware-realtek`) and kiosk configurations. This solves missing driver issues common with generic live images.

## Desktop Environment & Window Management

- **LightDM**: A lightweight, cross-desktop display manager. It handles the initial user login. In the kiosk configuration, it's set to automatically log in the `user` account without prompting for a password (`autologin-user=user`).
- **Openbox**: A highly configurable, lightweight, next-generation window manager for X11. It is used instead of a full desktop environment to save resources. Its configuration is stripped down (no right-click menus, no keybindings) to prevent users from escaping the kiosk application.

## Remote Access

- **KasmVNC**: A modern VNC server that renders the desktop and serves it directly over HTTPS/WebSockets to a web browser. The kiosk client boots, automatically opens a fullscreen browser, and connects to the KasmVNC instance hosted centrally. This architecture ensures that no data or state is stored on the physical client hardware.

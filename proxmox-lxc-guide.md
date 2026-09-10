# Proxmox LXC Setup

This document details an example configuration for hosting the Jumpbox Kiosk backend using LXC containers in Proxmox.

## CT 1: KasmVNC Jumpbox

This container serves as the actual jumpbox environment that users connect to. It runs a full desktop environment accessible via a web browser.

### Key Components:
- **KasmVNC**: Provides the web-based remote desktop server. It is configured to serve the desktop over HTTPS/WSS.
- **Desktop Environment**: A lightweight desktop environment (like XFCE or Openbox) is installed to provide the UI.
- **Nginx (Optional/Reverse Proxy)**: If Nginx is used for SSL termination or routing, it proxies WebSocket traffic to the KasmVNC backend.
- **Authentication**: KasmVNC is configured with read-only or specific user credentials. Since it's a kiosk, it can be set to allow seamless login or use basic auth depending on security requirements.

### Setup Steps:
1. Create a standard Debian/Ubuntu LXC container in Proxmox.
2. Install the target desktop environment.
3. Install KasmVNC following the official documentation.
4. Configure `/etc/kasmvnc/kasmvnc.yaml` to set the port, TLS certificates, and authentication.
5. Start the KasmVNC service and ensure it runs on boot via systemd.

## CT 2: iVentoy PXE Server

This container handles the PXE booting process for the diskless client devices.

### Key Components:
- **iVentoy**: An enhanced version of Ventoy designed for PXE booting. It serves ISO files directly over the network.
- **DHCP/TFTP**: iVentoy acts as a proxy DHCP server or full DHCP server, providing the initial PXE bootloader (ipxe) to the client.
- **ISO Storage**: The custom Debian Kiosk ISO built using the project scripts is uploaded to the iVentoy storage directory.

### Setup Steps:
1. Create a Debian/Ubuntu LXC container.
2. Download and extract the latest iVentoy release.
3. Copy the custom `live-image-amd64.hybrid.iso` to the `iso` directory within iVentoy.
4. Start the iVentoy service.
5. Access the iVentoy web interface and start the PXE service. Ensure the DHCP configuration matches the network segment of the diskless clients.

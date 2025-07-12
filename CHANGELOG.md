# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-12-19

### Added
- Complete MikroTik VLESS VPN setup for hAP lite (RB941-2nD)
- Comprehensive RouterOS configuration script (`vless_mikrotik_setup.rsc`)
- VLESS URL parser (`utils/parse_vless.py`) with full parameter extraction
- Step-by-step README with beginner-friendly instructions
- Automatic VPN reconnection every 6 seconds
- VLESS key update functionality
- User management (create "outline" user, disable "admin")
- WiFi configuration (SSID: outline360, Password: outline)
- Container deployment for Xray and hev-socks5-tunnel
- Security hardening and firewall rules
- DHCP server configuration
- Routing and NAT setup

### Features
- **Hardware Support**: Optimized for MikroTik hAP lite (smips architecture)
- **Container-based**: Uses Docker containers for VPN services
- **Automatic Recovery**: Self-healing VPN connection with 6-second monitoring
- **Easy Updates**: Simple command to update VLESS configuration
- **Security**: Disabled default admin, custom user, WiFi security
- **Beginner-friendly**: Detailed instructions and warnings

### Technical Details
- **RouterOS Version**: Requires v7.14 or higher
- **Architecture**: smips (MIPSBE) for hAP lite
- **Container Images**: 
  - Xray: `snegowiki/vless-mikrotik`
  - hev-socks5-tunnel: `ghcr.io/netchx/netch-hev-socks5-tunnel:latest`
- **Network**: 192.168.88.0/24 LAN, 172.17.0.0/24 containers
- **WiFi**: 2.4GHz b/g/n, WPA2-PSK

### Known Limitations
- Limited performance on hAP lite due to hardware constraints
- Some Docker images may not be compatible with smips architecture
- Requires USB storage for container data
- Complete router reset required for initial setup 
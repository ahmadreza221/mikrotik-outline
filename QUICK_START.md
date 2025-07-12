# Quick Start Guide

## ⚡ Fast Setup (5 minutes)

### Prerequisites Check
1. **Router**: MikroTik hAP lite (RB941-2nD)
2. **RouterOS**: v7.14 or higher
3. **USB Drive**: 1GB+ formatted as ext4
4. **Container Package**: Installed from MikroTik extras

### Quick Steps

1. **Reset Router** (⚠️ Backup first!)
   ```
   /system reset-configuration no-defaults=yes keep-users=no skip-backup=yes
   ```

2. **Create User** (Prevent lockout)
   ```
   /user add name=outline password=outline group=full
   ```

3. **Import Script**
   - Upload `vless_mikrotik_setup.rsc` via Winbox
   - Run: `/import vless_mikrotik_setup.rsc`

4. **Update VLESS Key**
   ```
   /update_vless_key "your-vless-url-here"
   ```

### Login Details
- **Router IP**: 192.168.88.1
- **Username**: outline
- **Password**: outline
- **WiFi SSID**: outline360
- **WiFi Password**: outline

### Commands
- **Check VPN Status**: `/container print`
- **Update VLESS**: `/update_vpn_key "new-url"`
- **View Logs**: `/log print`

## 🚨 Important Notes
- Change default passwords after setup
- Monitor performance on hAP lite (limited resources)
- Some Docker images may not work on smips architecture
- Full instructions in README.md 
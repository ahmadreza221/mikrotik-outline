# MikroTik VLESS VPN Setup

Automated VLESS VPN configuration for MikroTik hAP lite using RouterOS and containers. Beginner-friendly guide included.

## ⚠️ IMPORTANT WARNINGS

- **Data Loss Risk**: This setup requires a complete router reset. Backup your current configuration first!
- **Lockout Risk**: The script disables the default "admin" user. Make sure you can access the router after setup.
- **Hardware Limitations**: hAP lite has limited resources. VPN performance may be slower than expected.
- **Architecture Compatibility**: Some Docker images may not work on hAP lite's smips architecture.

## 📋 Prerequisites

### Hardware Requirements
- MikroTik hAP lite router (RB941-2nD)
- USB flash drive (at least 1GB, formatted as ext4)
- Computer with Winbox installed

### Software Requirements
- RouterOS v7.14 or higher
- Container package installed
- Internet connection for downloading packages

## 🔧 Pre-Installation Setup

### Step 1: Update RouterOS (if needed)

**Check your current version:**
```
/system resource print
```

**If version is below 7.14:**

1. Download latest RouterOS from [mikrotik.com/download](https://mikrotik.com/download)
2. Open Winbox and connect to your router (default IP: 192.168.88.1)
3. Go to Files → Upload the .npk file
4. Go to System → Packages → Install the uploaded package
5. Reboot the router

**If update fails, use Netinstall:**
- Download Netinstall from mikrotik.com
- Follow guide: [wiki.mikrotik.com/wiki/Manual:Netinstall](https://wiki.mikrotik.com/wiki/Manual:Netinstall)

### Step 2: Install Container Package

1. Download container package for smips architecture from mikrotik.com
2. Upload via Winbox → Files
3. Install: `/system package install container`

### Step 3: Prepare USB Drive

1. Insert USB drive into router
2. Format as ext4: `/disk format usb1 fs=ext4`
3. Wait for format to complete

### Step 4: Reset Router (⚠️ BACKUP FIRST!)

**IMPORTANT**: This erases all settings. Backup your config first!

1. Connect via Winbox (IP: 192.168.88.1, user: admin, no password)
2. Run reset command:
```
/system reset-configuration no-defaults=yes keep-users=no skip-backup=yes
```
3. Wait for router to reboot
4. Reconnect via Winbox

### Step 5: Create New User (Prevent Lockout)

After reset, immediately create the new user:

1. Connect via Winbox
2. Run: `/user add name=outline password=outline group=full`
3. Test login with "outline"/"outline"
4. **Only then** proceed with the script

## 🚀 Installation

### Step 1: Configure Container Registry

```
/container config set registry-url=https://registry-1.docker.io tmpdir=usb1/tmp
```

### Step 2: Import Configuration Script

1. Download `vless_mikrotik_setup.rsc` to your computer
2. Upload to router via Winbox → Files
3. Import the script:
```
/import vless_mikrotik_setup.rsc
```

### Step 3: Update VLESS Configuration

1. Get your VLESS URL from your VPN provider
2. Use the update script:
```
/update_vless_key "your-vless-url-here"
```

## 🔧 Configuration Details

### Network Setup
- **WAN**: Ether4 (internet connection)
- **LAN**: Ether1, Ether2, Ether3 + WiFi
- **LAN IP**: 192.168.88.1/24
- **DHCP Pool**: 192.168.88.10-254
- **WiFi SSID**: outline360
- **WiFi Password**: outline

### Container Setup
- **Xray Container**: VLESS client (172.17.0.2)
- **hev-socks5-tunnel**: TUN interface routing (172.17.0.3)
- **Bridge**: 172.17.0.1/24

### Routing
- All LAN traffic routed through VPN
- WAN traffic bypasses VPN
- Automatic reconnection every 6 seconds

## 🔍 Troubleshooting

### Common Issues

**1. Container won't start**
- Check if container package is installed
- Verify USB drive is properly formatted
- Check available disk space

**2. Architecture compatibility issues**
- hAP lite uses smips architecture
- Some images may not be compatible
- Consider building custom images or using different router

**3. Performance issues**
- hAP lite has limited CPU/RAM
- VPN speed may be slower than direct connection
- Consider upgrading to more powerful router

**4. Locked out of router**
- Use Netinstall to reset if you can't access
- Always test new user before disabling admin

**5. WiFi not working**
- Check if WiFi is enabled
- Verify security profile is applied
- Try rebooting router

### Performance Tips

- Monitor CPU usage: `/system resource cpu print`
- Check memory usage: `/system resource print`
- Monitor container status: `/container print`

## 🔄 Updating VLESS Configuration

To update your VLESS settings:

```
/update_vless_key "vless://new-uuid@new-host:port?type=tcp&security=reality&pbk=new-key&fp=chrome&sni=new-sni&sid=new-sid&spx=/path#comment"
```

The script will:
1. Parse the new VLESS URL
2. Update Xray container environment variables
3. Restart the container
4. Test connectivity

## 📁 Files

- `vless_mikrotik_setup.rsc` - Main configuration script
- `utils/parse_vless.py` - VLESS URL parser
- `README.md` - This documentation

## 🔒 Security Notes

- Default WiFi password is "outline" - change it after setup
- Default admin user is "outline" with password "outline" - change immediately
- Consider changing default IP range for additional security
- Regularly update RouterOS and container images

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Check MikroTik forums for similar issues
4. Consider using a more powerful router for better performance

## 📄 License

This project is provided as-is for educational purposes. Use at your own risk. 
# MikroTik VLESS VPN - One Click Setup
# Complete automated setup for hAP lite
# Just run: /import one_click_setup.rsc

# ============================================================================
# SECTION 1: INITIAL SETUP AND VERSION CHECK
# ============================================================================

:log info "Starting One-Click VLESS VPN Setup..."

# Check RouterOS version and update if needed
:local current_version [/system resource get version]
:log info ("Current RouterOS version: " . $current_version)

:if ([:pick $current_version 0 3] < "7.1") do={
    :log warning "RouterOS version below 7.14 detected. Updating..."
    /tool fetch url="https://download.mikrotik.com/routeros/7.14/routeros-mipsbe-7.14.npk" dst-path=routeros-update.npk
    :if ([:len [/file find name=routeros-update.npk]] > 0) do={
        /system package install routeros-update.npk
        :log warning "RouterOS update installed. Rebooting in 10 seconds..."
        :delay 10s
        /system reboot
    }
}

# ============================================================================
# SECTION 2: CONTAINER PACKAGE INSTALLATION
# ============================================================================

:if ([:len [/system package find name=container]] = 0) do={
    :log info "Installing container package..."
    /tool fetch url="https://download.mikrotik.com/routeros/7.14/container-mipsbe-7.14.npk" dst-path=container-package.npk
    :if ([:len [/file find name=container-package.npk]] > 0) do={
        /system package install container-package.npk
        :log info "Container package installed."
    }
}

# ============================================================================
# SECTION 3: USER MANAGEMENT
# ============================================================================

# Remove existing users except admin temporarily
/user remove [find name=outline]
/user disable [find name=admin]

# Create new user
/user add name=outline password=outline group=full

:log info "User management completed"

# ============================================================================
# SECTION 4: INTERFACE AND NETWORK SETUP
# ============================================================================

# Reset interfaces
/interface reset-numbers

# Configure interfaces
/interface ethernet set [find name=ether4] name=ether4-wan
/interface ethernet set [find name=ether1] name=ether1-lan
/interface ethernet set [find name=ether2] name=ether2-lan
/interface ethernet set [find name=ether3] name=ether3-lan

# Create bridges
/interface bridge add name=bridge-lan
/interface bridge add name=bridge-containers

# Add interfaces to bridges
/interface bridge port add bridge=bridge-lan interface=ether1-lan
/interface bridge port add bridge=bridge-lan interface=ether2-lan
/interface bridge port add bridge=bridge-lan interface=ether3-lan

# WiFi setup
/interface wireless security-profiles add name=outline-profile mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=outline
/interface wireless set [find default-name=wlan1] mode=ap-bridge band=2ghz-b/g/n ssid=outline360 security-profile=outline-profile disabled=no
/interface bridge port add bridge=bridge-lan interface=wlan1

# IP configuration
/ip dhcp-client add interface=ether4-wan disabled=no
/ip address add address=192.168.88.1/24 interface=bridge-lan
/ip address add address=172.17.0.1/24 interface=bridge-containers

# DHCP server
/ip dhcp-server setup interface=bridge-lan name=dhcp-lan
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4
/ip pool add name=dhcp-pool ranges=192.168.88.10-192.168.88.254
/ip dhcp-server set [find name=dhcp-lan] address-pool=dhcp-pool

# DNS
/ip dns set servers=8.8.8.8,8.8.4.4

:log info "Network configuration completed"

# ============================================================================
# SECTION 5: FIREWALL AND SECURITY
# ============================================================================

# Firewall rules
/ip firewall filter add chain=input connection-state=established,related
/ip firewall filter add chain=forward connection-state=established,related
/ip firewall filter add chain=input protocol=icmp
/ip firewall filter add chain=input protocol=tcp dst-port=22
/ip firewall filter add chain=input protocol=tcp dst-port=8291
/ip firewall filter add chain=input protocol=tcp dst-port=80
/ip firewall filter add chain=input action=drop

:log info "Firewall configuration completed"

# ============================================================================
# SECTION 6: CONTAINER NETWORK SETUP
# ============================================================================

# Container configuration
/container config set registry-url=https://registry-1.docker.io tmpdir=usb1/tmp

# Virtual ethernet interfaces
/interface veth add name=veth-xray address=172.17.0.2/24 gateway=172.17.0.1
/interface veth add name=veth-tun address=172.17.0.3/24 gateway=172.17.0.1

# Add to bridge
/interface bridge port add bridge=bridge-containers interface=veth-xray
/interface bridge port add bridge=bridge-containers interface=veth-tun

:log info "Container network setup completed"

# ============================================================================
# SECTION 7: ROUTING CONFIGURATION
# ============================================================================

# Interface lists
/interface list add name=WAN
/interface list add name=LAN

# Add interfaces to lists
/interface list member add list=WAN interface=ether4-wan
/interface list member add list=LAN interface=bridge-lan
/interface list member add list=LAN interface=bridge-containers

# Routing table
/routing table add name=vpn-mark fib

# Mangle rule
/ip firewall mangle add chain=prerouting src-address=192.168.88.0/24 action=mark-routing new-routing-mark=vpn-mark

# Route
/ip route add dst-address=0.0.0.0/0 gateway=172.17.0.3 routing-table=vpn-mark

# NAT
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade

:log info "Routing configuration completed"

# ============================================================================
# SECTION 8: CONTAINER DEPLOYMENT
# ============================================================================

# Deploy Xray container
/container add interface=veth-xray root-dir=usb1/xray logging=yes start-on-boot=yes image=snegowiki/vless-mikrotik envlist=UUID=e73c748e-19fa-4618-a4d9-c7dfb22c66e7,HOST=threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link,PORT=443,TYPE=tcp,SECURITY=reality,PBK=fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU,FP=chrome,SNI=yahoo.com,SID=ad2e,SPX=/,COMMENT=🇩🇪3-50.00GB-246175259-LK

# Deploy hev-socks5-tunnel container
/container add interface=veth-tun root-dir=usb1/hev-tunnel logging=yes start-on-boot=yes image=ghcr.io/netchx/netch-hev-socks5-tunnel:latest cmdline="--tun-address '172.17.0.3 255.255.255.0' --tun-name tun0 --tun-gw '172.17.0.1' --socks5-address '172.17.0.2:1080' --log-level silent"

:log info "Container deployment completed"

# ============================================================================
# SECTION 9: VPN MONITORING SCRIPTS
# ============================================================================

# VPN check script
/system script add name=check_vpn source={
    :local ping_result [/ping 8.8.8.8 count=1 routing-table=vpn-mark]
    :if ($ping_result = 0) do={
        /container stop [find name~"xray"]
        /container stop [find name~"hev-tunnel"]
        :delay 1s
        /container start [find name~"xray"]
        /container start [find name~"hev-tunnel"]
        :log warning "VPN containers restarted due to connectivity failure"
    }
}

# VLESS update script
/system script add name=update_vless_key source={
    :local new_url [:pick $1 0 [:len $1]]
    :local url_start [:find $new_url "vless://"]
    :if ($url_start = 0) do={
        :local url_without_prefix [:pick $new_url 8 [:len $new_url]]
        :local at_pos [:find $url_without_prefix "@"]
        :if ($at_pos > 0) do={
            :local uuid [:pick $url_without_prefix 0 $at_pos]
            :local rest [:pick $url_without_prefix ($at_pos + 1) [:len $url_without_prefix]]
            :local colon_pos [:find $rest ":"]
            :local question_pos [:find $rest "?"]
            :if ($colon_pos > 0) do={
                :local host [:pick $rest 0 $colon_pos]
                :if ($question_pos > 0) do={
                    :local port [:pick $rest ($colon_pos + 1) $question_pos]
                } else={
                    :local port [:pick $rest ($colon_pos + 1) [:len $rest]]
                }
            } else={
                :if ($question_pos > 0) do={
                    :local host [:pick $rest 0 $question_pos]
                    :local port "443"
                } else={
                    :local host $rest
                    :local port "443"
                }
            }
            /container set [find name~"xray"] envlist=("UUID=" . $uuid . ",HOST=" . $host . ",PORT=" . $port)
            /container stop [find name~"xray"]
            :delay 1s
            /container start [find name~"xray"]
            :log info ("VLESS configuration updated: " . $host . ":" . $port)
        } else={
            :log error "Invalid VLESS URL format"
        }
    } else={
        :log error "URL must start with vless://"
    }
}

# Scheduler
/system scheduler add name=vpn-monitor interval=6s on-event=check_vpn start-time=startup

:log info "VPN monitoring scripts created"

# ============================================================================
# SECTION 10: FINAL SETUP
# ============================================================================

# Enable services
/ip dhcp-server enable [find name=dhcp-lan]

# Start containers
/container start [find name~"xray"]
/container start [find name~"hev-tunnel"]

# Clean up
/file remove routeros-update.npk
/file remove container-package.npk

# ============================================================================
# SECTION 11: COMPLETION MESSAGE
# ============================================================================

:log info "=========================================="
:log info "🎉 ONE-CLICK VLESS VPN SETUP COMPLETED!"
:log info "=========================================="
:log info "📱 Login: outline / outline"
:log info "🌐 Router IP: 192.168.88.1"
:log info "📶 WiFi: outline360 / outline"
:log info "🔄 Update VLESS: /update_vless_key \"your-url\""
:log info "📊 Check Status: /container print"
:log info "==========================================" 
# MikroTik VLESS VPN Setup Script
# For hAP lite (RB941-2nD) with RouterOS v7.14+
# 
# WARNING: This script will reset your router configuration!
# Make sure to backup your current config before running this script.
# After running, login with user "outline" and password "outline"

# ============================================================================
# SECTION 1: USER MANAGEMENT
# ============================================================================

# Create new user "outline" with full access
/user add name=outline password=outline group=full

# Disable default admin user for security
/user disable [find name=admin]

# ============================================================================
# SECTION 2: INTERFACE CONFIGURATION
# ============================================================================

# Reset all interfaces to default state
/interface reset-numbers

# Configure WAN interface (Ether4 - receives internet)
/interface ethernet set [find name=ether4] name=ether4-wan

# Configure LAN interfaces (Ether1, Ether2, Ether3)
/interface ethernet set [find name=ether1] name=ether1-lan
/interface ethernet set [find name=ether2] name=ether2-lan
/interface ethernet set [find name=ether3] name=ether3-lan

# ============================================================================
# SECTION 3: BRIDGE CONFIGURATION
# ============================================================================

# Create bridge for LAN interfaces
/interface bridge add name=bridge-lan
/interface bridge port add bridge=bridge-lan interface=ether1-lan
/interface bridge port add bridge=bridge-lan interface=ether2-lan
/interface bridge port add bridge=bridge-lan interface=ether3-lan

# Create bridge for containers
/interface bridge add name=bridge-containers

# ============================================================================
# SECTION 4: WIFI CONFIGURATION
# ============================================================================

# Create WiFi security profile
/interface wireless security-profiles add name=outline-profile mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=outline

# Configure WiFi interface
/interface wireless set [find default-name=wlan1] mode=ap-bridge band=2ghz-b/g/n ssid=outline360 security-profile=outline-profile disabled=no

# Add WiFi to LAN bridge
/interface bridge port add bridge=bridge-lan interface=wlan1

# ============================================================================
# SECTION 5: IP ADDRESS CONFIGURATION
# ============================================================================

# Configure WAN interface (DHCP client)
/ip dhcp-client add interface=ether4-wan disabled=no

# Configure LAN bridge IP
/ip address add address=192.168.88.1/24 interface=bridge-lan

# Configure container bridge IP
/ip address add address=172.17.0.1/24 interface=bridge-containers

# ============================================================================
# SECTION 6: DHCP SERVER CONFIGURATION
# ============================================================================

# Configure DHCP server for LAN
/ip dhcp-server setup interface=bridge-lan name=dhcp-lan
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4
/ip dhcp-server set [find name=dhcp-lan] address-pool=dhcp-pool

# Create DHCP address pool
/ip pool add name=dhcp-pool ranges=192.168.88.10-192.168.88.254

# ============================================================================
# SECTION 7: DNS CONFIGURATION
# ============================================================================

# Configure DNS servers
/ip dns set servers=8.8.8.8,8.8.4.4

# ============================================================================
# SECTION 8: BASIC FIREWALL RULES
# ============================================================================

# Allow established connections
/ip firewall filter add chain=input connection-state=established,related
/ip firewall filter add chain=forward connection-state=established,related

# Allow ICMP (ping)
/ip firewall filter add chain=input protocol=icmp

# Allow SSH, Winbox, and HTTP
/ip firewall filter add chain=input protocol=tcp dst-port=22
/ip firewall filter add chain=input protocol=tcp dst-port=8291
/ip firewall filter add chain=input protocol=tcp dst-port=80

# Drop everything else on input
/ip firewall filter add chain=input action=drop

# ============================================================================
# SECTION 9: CONTAINER CONFIGURATION
# ============================================================================

# Configure container registry and storage
/container config set registry-url=https://registry-1.docker.io tmpdir=usb1/tmp

# Create virtual ethernet interfaces for containers
/interface veth add name=veth-xray address=172.17.0.2/24 gateway=172.17.0.1
/interface veth add name=veth-tun address=172.17.0.3/24 gateway=172.17.0.1

# Add veth interfaces to container bridge
/interface bridge port add bridge=bridge-containers interface=veth-xray
/interface bridge port add bridge=bridge-containers interface=veth-tun

# ============================================================================
# SECTION 10: ROUTING CONFIGURATION
# ============================================================================

# Create interface lists
/interface list add name=WAN
/interface list add name=LAN

# Add interfaces to lists
/interface list member add list=WAN interface=ether4-wan
/interface list member add list=LAN interface=bridge-lan
/interface list member add list=LAN interface=bridge-containers

# Create routing table for VPN traffic
/routing table add name=vpn-mark fib

# Create mangle rule to mark LAN traffic
/ip firewall mangle add chain=prerouting src-address=192.168.88.0/24 action=mark-routing new-routing-mark=vpn-mark

# Add route for VPN traffic
/ip route add dst-address=0.0.0.0/0 gateway=172.17.0.3 routing-table=vpn-mark

# ============================================================================
# SECTION 11: NAT CONFIGURATION
# ============================================================================

# Masquerade for LAN and container subnets
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade

# ============================================================================
# SECTION 12: CONTAINER DEPLOYMENT
# ============================================================================

# Deploy Xray container
/container add interface=veth-xray root-dir=usb1/xray logging=yes start-on-boot=yes image=snegowiki/vless-mikrotik envlist=UUID=e73c748e-19fa-4618-a4d9-c7dfb22c66e7,HOST=threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link,PORT=443,TYPE=tcp,SECURITY=reality,PBK=fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU,FP=chrome,SNI=yahoo.com,SID=ad2e,SPX=/,COMMENT=🇩🇪3-50.00GB-246175259-LK

# Deploy hev-socks5-tunnel container
/container add interface=veth-tun root-dir=usb1/hev-tunnel logging=yes start-on-boot=yes image=ghcr.io/netchx/netch-hev-socks5-tunnel:latest cmdline="--tun-address '172.17.0.3 255.255.255.0' --tun-name tun0 --tun-gw '172.17.0.1' --socks5-address '172.17.0.2:1080' --log-level silent"

# ============================================================================
# SECTION 13: VPN RECONNECTION SCRIPT
# ============================================================================

# Create script to check VPN connectivity and restart containers if needed
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

# ============================================================================
# SECTION 14: SCHEDULER FOR VPN MONITORING
# ============================================================================

# Create scheduler to run VPN check every 6 seconds
/system scheduler add name=vpn-monitor interval=6s on-event=check_vpn start-time=startup

# ============================================================================
# SECTION 15: VLESS KEY UPDATE SCRIPT
# ============================================================================

# Create script to update VLESS configuration
/system script add name=update_vless_key source={
    :local new_url [:pick $1 0 [:len $1]]
    
    # Parse VLESS URL (basic parsing - for full parsing use external Python script)
    :local url_start [:find $new_url "vless://"]
    :if ($url_start = 0) do={
        :local url_without_prefix [:pick $new_url 8 [:len $new_url]]
        :local at_pos [:find $url_without_prefix "@"]
        :if ($at_pos > 0) do={
            :local uuid [:pick $url_without_prefix 0 $at_pos]
            :local rest [:pick $url_without_prefix ($at_pos + 1) [:len $url_without_prefix]]
            
            # Extract host and port
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
            
            # Update container environment variables
            /container set [find name~"xray"] envlist=("UUID=" . $uuid . ",HOST=" . $host . ",PORT=" . $port)
            
            # Restart Xray container
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

# ============================================================================
# SECTION 16: FINAL CONFIGURATION
# ============================================================================

# Enable all services
/ip dhcp-server enable [find name=dhcp-lan]

# Start containers
/container start [find name~"xray"]
/container start [find name~"hev-tunnel"]

# Log completion
:log info "MikroTik VLESS VPN setup completed successfully"
:log info "Login with user: outline, password: outline"
:log info "WiFi SSID: outline360, Password: outline"
:log info "LAN IP: 192.168.88.1"
:log info "Use /update_vless_key \"your-vless-url\" to update configuration" 
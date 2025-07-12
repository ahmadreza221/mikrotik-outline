# Simple VLESS VPN Setup - Fixed Version
# Run: /tool fetch url="https://raw.githubusercontent.com/ahmadreza221/mikrotik-outline/main/simple_setup_fixed.rsc" dst-path=setup.rsc; /import setup.rsc

# Check RouterOS version
:local ver [/system resource get version]
:if ([:pick $ver 0 3] < "7.1") do={
    /tool fetch url="https://download.mikrotik.com/routeros/7.14/routeros-mipsbe-7.14.npk" dst-path=update.npk
    :if ([:len [/file find name=update.npk]] > 0) do={
        /system package install update.npk
        :delay 10s
        /system reboot
    }
}

# Install container package
:if ([:len [/system package find name=container]] = 0) do={
    /tool fetch url="https://download.mikrotik.com/routeros/7.14/container-mipsbe-7.14.npk" dst-path=container.npk
    :if ([:len [/file find name=container.npk]] > 0) do={
        /system package install container.npk
    }
}

# User setup
/user remove [find name=outline]
/user disable [find name=admin]
/user add name=outline password=outline group=full

# Network setup
/interface reset-numbers
/interface ethernet set [find name=ether4] name=wan
/interface ethernet set [find name=ether1] name=lan1
/interface ethernet set [find name=ether2] name=lan2
/interface ethernet set [find name=ether3] name=lan3

# Bridges
/interface bridge add name=lan
/interface bridge add name=containers
/interface bridge port add bridge=lan interface=lan1
/interface bridge port add bridge=lan interface=lan2
/interface bridge port add bridge=lan interface=lan3

# WiFi
/interface wireless security-profiles add name=wifi mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=outline
/interface wireless set [find default-name=wlan1] mode=ap-bridge band=2ghz-b/g/n ssid=outline360 security-profile=wifi disabled=no
/interface bridge port add bridge=lan interface=wlan1

# IP setup
/ip dhcp-client add interface=wan disabled=no
/ip address add address=192.168.88.1/24 interface=lan
/ip address add address=172.17.0.1/24 interface=containers

# DHCP
/ip dhcp-server setup interface=lan name=dhcp
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4
/ip pool add name=pool ranges=192.168.88.10-192.168.88.254
/ip dhcp-server set [find name=dhcp] address-pool=pool

# DNS
/ip dns set servers=8.8.8.8,8.8.4.4

# Firewall
/ip firewall filter add chain=input connection-state=established,related
/ip firewall filter add chain=forward connection-state=established,related
/ip firewall filter add chain=input protocol=icmp
/ip firewall filter add chain=input protocol=tcp dst-port=22
/ip firewall filter add chain=input protocol=tcp dst-port=8291
/ip firewall filter add chain=input protocol=tcp dst-port=80
/ip firewall filter add chain=input action=drop

# Container setup
/container config set registry-url=https://registry-1.docker.io tmpdir=usb1/tmp
/interface veth add name=veth-xray address=172.17.0.2/24 gateway=172.17.0.1
/interface veth add name=veth-tun address=172.17.0.3/24 gateway=172.17.0.1
/interface bridge port add bridge=containers interface=veth-xray
/interface bridge port add bridge=containers interface=veth-tun

# Routing
/interface list add name=WAN
/interface list add name=LAN
/interface list member add list=WAN interface=wan
/interface list member add list=LAN interface=lan
/interface list member add list=LAN interface=containers
/routing table add name=vpn fib
/ip firewall mangle add chain=prerouting src-address=192.168.88.0/24 action=mark-routing new-routing-mark=vpn
/ip route add dst-address=0.0.0.0/0 gateway=172.17.0.3 routing-table=vpn
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade

# Containers with your VLESS key
/container add interface=veth-xray root-dir=usb1/xray logging=yes start-on-boot=yes image=snegowiki/vless-mikrotik envlist=UUID=e73c748e-19fa-4618-a4d9-c7dfb22c66e7,HOST=threegermaoneojhhnweoidsjcdsvhbascbwiuhvhbajgermtree.asdir.link,PORT=443,TYPE=tcp,SECURITY=reality,PBK=fv0Zz9FtroOmuK1Tsn0u98gXSq8XepZKtbdH3lDg9EU,FP=chrome,SNI=yahoo.com,SID=ad2e,SPX=%2F,COMMENT=🇩🇪3-50.00GB-246175259-LK
/container add interface=veth-tun root-dir=usb1/hev-tunnel logging=yes start-on-boot=yes image=ghcr.io/netchx/netch-hev-socks5-tunnel:latest cmdline="--tun-address '172.17.0.3 255.255.255.0' --tun-name tun0 --tun-gw '172.17.0.1' --socks5-address '172.17.0.2:1080' --log-level silent"

# Simple VPN check script
/system script add name=check_vpn source={
    :local ping_result [/ping 8.8.8.8 count=1 routing-table=vpn]
    :if ($ping_result = 0) do={
        /container stop [find name~"xray"]
        /container stop [find name~"hev-tunnel"]
        :delay 1s
        /container start [find name~"xray"]
        /container start [find name~"hev-tunnel"]
        :log warning "VPN restarted"
    }
}

# Simple update script
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
            :log info ("Updated: " . $host . ":" . $port)
        }
    }
}

# Scheduler
/system scheduler add name=vpn-monitor interval=6s on-event=check_vpn start-time=startup

# Start everything
/ip dhcp-server enable [find name=dhcp]
/container start [find name~"xray"]
/container start [find name~"hev-tunnel"]

# Cleanup
/file remove update.npk
/file remove container.npk

# Success message
:log info "VLESS VPN READY! Login: outline/outline, WiFi: outline360/outline, IP: 192.168.88.1" 
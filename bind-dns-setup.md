# BIND DNS Server Configuration Guide

**Author:** Deba Protim Dey  
**Date:** July 22, 2025  
**Last Updated:** July 22, 2025  

A comprehensive guide for setting up Authoritative-only DNS servers primary and secondary using BIND9 servers on Ubuntu/Debian systems.

## Overview

This guide covers the complete setup of a BIND DNS infrastructure with:
- Primary DNS server (172.28.1.213)
- Secondary DNS server (172.28.1.214)
- Forward and reverse DNS zones
- Security configurations and logging

## Network Configuration

- **Primary DNS**: 172.28.1.213 (dns1.example.com)
- **Secondary DNS**: 172.28.1.214 (dns2.example.com)
- **Domain**: example.com
- **VLANs**: 
  - 172.28.1.0/24 (VLAN 228)
  - 172.24.1.0/24 (VLAN 224)

## Installation

### Install BIND9 and utilities

```bash
sudo apt update
sudo apt install bind9 bind9utils -y
```

### Start and enable BIND service

```bash
systemctl status named
systemctl start named
systemctl enable --now named
```

### Configure BIND defaults

```bash
sudo vi /etc/default/named
```

Add the following lines:
```
RESOLVCONF=no
OPTIONS="-u bind -4"  # If using IPv4 only
```

### Create necessary directories

```bash
sudo mkdir -p /var/log/named
sudo mkdir -p /etc/bind/zones
sudo chown bind:bind /var/log/named
sudo chown bind:bind /etc/bind/zones
```

## Security Configuration

For security, BIND is configured to not disclose version, server ID, and hostname information. You can test this configuration using:

```bash
dig @172.28.1.213 version.bind chaos txt
dig @172.28.1.213 id.server chaos txt
dig @172.28.1.213 hostname.bind chaos txt
```

## Primary DNS Server Configuration

### 1. Configure `/etc/bind/named.conf.options`
# Edit the file using your preferred text editor
```bash
vi /etc/bind/named.conf.options
```

```bind
// ACL Definitions - Define trusted networks and servers
acl "trusted-networks" {
    127.0.0.1;
    172.28.1.0/24; //VLAN 228
    172.24.1.0/24; //VLAN 224
};

acl "slave-servers" {
    172.28.1.214;
};

// Logging Configuration
logging {
    // General logs (startup, shutdown, errors)
    channel general_log {
        file "/var/log/named/general.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };

    // Config parsing errors or warnings
    channel config_log {
        file "/var/log/named/config.log" versions 3 size 2m;
        severity warning;
        print-time yes;
        print-severity yes;
        print-category yes;
    };

    // Notifications (for master to notify slaves)
    channel notify_log {
        file "/var/log/named/notify.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };

    // Incoming zone transfers (slave)
    channel transfer_log {
        file "/var/log/named/transfer.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };

    // Assign channels to categories
    category default        { general_log; };
    category general        { general_log; };
    category config         { config_log; };
    category notify         { notify_log; };
    category xfer-in        { transfer_log; };
    category xfer-out       { transfer_log; };
};

options {
    directory "/var/cache/bind";
    recursion no; // for authoritative server
    allow-query { trusted-networks; };
    listen-on { 127.0.0.1; 172.28.1.213; };
    allow-transfer { none; };  # Disable transfers by default
    // Security settings
    version "Not Disclosed";
    hostname "Not Disclosed";
    server-id "Not Disclosed";

    //========================================================================
    // If BIND logs error messages about the root key being expired,
    // you will need to update your keys.  See https://www.isc.org/bind-keys
    //========================================================================
    dnssec-validation auto;

    listen-on-v6 { ::1; };  // allow localhost IPv6

    // rate-limiting to prevent DNS amplification attacks,
    rate-limit {
    responses-per-second 10;
    window 5;
    };
};
```

### 2. Validate configuration

```bash
named-checkconf /etc/bind/named.conf.options
```

### 3. Configure `/etc/bind/named.conf.local`

```bash
vi /etc/bind/named.conf.local
```

```bind
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

// Forward zones
zone "example.com" {
    type primary;
    file "/etc/bind/zones/db.example.com";
    allow-transfer { slave-servers; };
};

zone "1.28.172.in-addr.arpa" {
    type primary;
    file "/etc/bind/zones/db.172.28";
    allow-transfer { slave-servers; };
};

zone "1.24.172.in-addr.arpa" {
    type primary;
    file "/etc/bind/zones/db.172.24";
    allow-transfer { slave-servers; };
};
```

### 4. Create zone files

#### Forward zone file: `/etc/bind/zones/db.example.com`

```bind
;
; BIND data file for example.com domain
;
$TTL    604800        ; Default TTL for all records 7 days
@   IN  SOA dns1.example.com. admin.example.com. (
     2025072108     ; Serial number - increment when making changes YYYYMMDDNN
         604800     ; Refresh interval - how often slaves check for updates  
          86400     ; Retry interval - retry failed transfers after this time
        2419200     ; Expire time - slaves stop answering after this period
         604800 )   ; Negative cache TTL - cache NXDOMAIN responses
;

; ===== NAME SERVER RECORDS =====
; Define authoritative DNS servers for this zone

@       IN      NS      dns1.example.com.
@       IN      NS      dns2.example.com.

; A record for the domain root (example.com)
@       IN      A       172.28.1.213

; A records for hosts
dns1    IN      A       172.28.1.213
dns2    IN      A       172.28.1.214
pc1     IN      A       172.24.1.221
```

#### Reverse zone file for 172.28.1.x: `/etc/bind/zones/db.172.28`

```bind
;
; BIND reverse data file for 172.28.1.x
;
$TTL    604800
@   IN  SOA dns1.example.com. admin.example.com. (
     2025072108     ; Serial  ;YYYYMMDDNN
         604800     ; Refresh
          86400     ; Retry
        2419200     ; Expire
         604800 )   ; Negative Cache TTL

; NS records for this zone
@    IN    NS    dns1.example.com.
@    IN    NS    dns2.example.com.

; PTR records
213    IN    PTR    dns1.example.com. ; 172.28.1.213
214    IN    PTR    dns2.example.com. ; 172.28.1.214
```

#### Reverse zone file for 172.24.1.x: `/etc/bind/zones/db.172.24`

```bind
;
; BIND reverse data file for 172.24.1.x
;
$TTL    604800
@   IN  SOA dns1.example.com. admin.example.com. (
     2025072108     ; Serial  ;YYYYMMDDNN
         604800     ; Refresh
          86400     ; Retry
        2419200     ; Expire
         604800 )   ; Negative Cache TTL

; NS records for this zone
@    IN    NS    dns1.example.com.
@    IN    NS    dns2.example.com.

; PTR records for 172.24.1.0/24
221    IN    PTR    pc1.example.com. ; 172.24.1.221
```

### 5. Validate zone files

```bash
# Check forward zone
named-checkzone example.com /etc/bind/zones/db.example.com

# Check reverse zones
named-checkzone 1.28.172.in-addr.arpa /etc/bind/zones/db.172.28
named-checkzone 1.24.172.in-addr.arpa /etc/bind/zones/db.172.24
```

## Secondary DNS Server Configuration

### 1. Configure `/etc/bind/named.conf.options`
Use the same configuration as the primary server, but change the `listen-on` directive to use the secondary server's IP address (172.28.1.214).

### 2. Create log directories
```bash
sudo mkdir -p /var/log/named
sudo chown bind:bind /var/log/named
```

### 3. Configure `/etc/bind/named.conf.local`

```bind
//include "/etc/bind/zones.rfc1918";

// Forward zones
zone "example.com" {
    type secondary;
    file "db.example.com";
    primaries { 172.28.1.213; };
};

zone "1.28.172.in-addr.arpa" {
    type secondary;
    file "db.172.28";
    primaries { 172.28.1.213; };
};

zone "1.24.172.in-addr.arpa" {
    type secondary;
    file "db.172.24";
    primaries { 172.28.1.213; };
};
```

### 4. Zone transfer files location
After configuration, transferred zone files will be located at:
```
/var/cache/bind/
├── db.172.24
├── db.172.28
├── db.example.com
├── managed-keys.bind
└── managed-keys.bind.jnl
```

## System DNS Configuration

### Option 1: Using systemd-resolved

```bash
sudo vi /etc/systemd/resolved.conf
```

Add in the `[Resolve]` section:
```
DNS=127.0.0.1
```

Apply changes:
```bash
systemctl restart systemd-resolved
systemd-resolve --status
```

### Option 2: Using Netplan

```bash
ls /etc/netplan/
sudo vi /etc/netplan/01-netcfg.yaml
```

Configure nameservers:
```yaml
network:
  version: 2
  ethernets:
    <interface-name>:
      nameservers:
        search: [example.com]
        addresses:
          - 127.0.0.1
          - 8.8.8.8
          - 1.1.1.1
```

Apply changes:
```bash
sudo netplan apply
```

## Service Management

### Restart BIND service
```bash
systemctl restart bind9
```

### Reload configuration
```bash
rndc reload
```

**Note**: Always reload the primary server first, then the secondary server.

## Testing and Verification

### Test forward DNS resolution

```bash
# Test against primary server
dig example.com @172.28.1.213
dig dns1.example.com @172.28.1.213
dig pc1.example.com @172.28.1.213

# Test against secondary server
dig example.com @172.28.1.214
dig dns2.example.com @172.28.1.214
```

### Test reverse DNS resolution

```bash
# Test against primary server
dig -x 172.28.1.213 @172.28.1.213
dig -x 172.24.1.221 @172.28.1.213

# Test against secondary server
dig -x 172.28.1.214 @172.28.1.214
```

### Test DNS security (should return "Not Disclosed")

```bash
dig @172.28.1.213 version.bind chaos txt
dig @172.28.1.213 id.server chaos txt
dig @172.28.1.213 hostname.bind chaos txt
```

## Log Files

Monitor DNS operations through log files:
- **General logs**: `/var/log/named/general.log`
- **Configuration logs**: `/var/log/named/config.log`
- **Notification logs**: `/var/log/named/notify.log`
- **Transfer logs**: `/var/log/named/transfer.log`

## Troubleshooting

### Common commands for troubleshooting

```bash
# Check BIND status
systemctl status bind9

# Check configuration syntax
named-checkconf

# View recent logs
tail -f /var/log/named/general.log

# Test zone transfers
dig @172.28.1.213 example.com AXFR
```

### Important notes

1. Always increment the serial number in SOA records when making changes to zone files
2. Restart the primary server before the secondary server
3. Use `rndc reload` after configuration changes
4. Ensure firewall rules allow DNS traffic (port 53 TCP/UDP)

## Security Considerations

- DNS server information is hidden from external queries
- Access is restricted to trusted networks only
- Zone transfers are limited to authorized secondary servers
- DNSSEC validation is enabled for enhanced security

## License

This configuration guide is provided as-is for educational and production use.

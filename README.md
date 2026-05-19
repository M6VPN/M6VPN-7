# M6VPN-7
AX.25 Packet Node configuration and tools for M6VPN-7/M6VPN-1

## About

This repo holds configuration files, tools, and BBS doors/applications for the M6VPN-7 packet node and M6VPN-1 BPQ BBS.

BPQ applications (external) are configured first in linbpq/bpq32.cfg:

```
  CMDPORT 63030 63031 63032 63033
```

Corresponding to applications configured with `HOST #`:

```
APPLICATION 1,BBS,,M6VPN-1,VPNBBS,255
APPLICATION 2,CHAT,,M6VPN-4,NCLCHT,25
APPLICATION 3,WX,C 10 HOST 0 S
APPLICATION 4,ZORK,C 10 HOST 1 S
APPLICATION 5,STAT,C 10 HOST 2 S
APPLICATION 6,PROP,C 10 HOST 3 S
```

Then systemd files are created for the sockets and services, e.g. `bpq-wx.socket` and `bpq-wx@.service` for port 63030 (WX).


## Directory structure

### pi/

- .				/home/pi on live system
- bpq-apps/			Applications / 'doors' for the BPQ BBS
- bpq-apps/prop.sh		Propagation data from NOAA/SWPC
- bpq-apps/stat.sh		System info / statistics
- bpq-apps/sysinfo.pl		A terminal-based sysinfo script (unused by stat.sh)
- bpq-apps/update-prop-cache.py	Grap NOAA/SWPC data and cache it
- bpq-apps/wx.sh		Retrieve weather data
- bpq-apps/zork.sh		Zork game launcher
- bpq-cache			Cached data for bpq-apps
- direwolf.ic2350.conf		Dire Wolf TNC Configuration
- linbpq/bpq32.cfg		LinBPQ configuration for M6VPN-7/M6VPN-1

### systemd/

- .
- bpq-prop@.service
- bpq-prop.socket
- bpq-stat@.service
- bpq-stat.socket
- bpq-wx@.service
- bpq-wx.socket
- bpq-zork@.service
- bpq-zork.socket
- direwolf-ic2350.service
- linbpq.service
- prop-cache-update.service
- prop-cache-update.timer


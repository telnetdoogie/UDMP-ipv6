# IPv6 via tunnelbroker on a UDMP, with Unifi Firewall Rules

This set of scripts is intended to help you automate and setup a Hurricane Electric / TunnelBroker ipv6 tunnel on your UDMP. It also allows you to use the ipv6 firewall rules as you normally would and will ensure those rules are applied to the tunnel (otherwise by default your HE tunnel will be wide open)

[![Commits](https://img.shields.io/github/last-commit/telnetdoogie/UDMP-ipv6/main)](https://github.com/telnetdoogie/UDMP-ipv6/commits/main)
[![Issues](https://img.shields.io/github/issues/telnetdoogie/UDMP-ipv6)](https://github.com/telnetdoogie/UDMP-ipv6/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr-raw/telnetdoogie/UDMP-ipv6)](https://github.com/telnetdoogie/UDMP-ipv6/pulls)

# Prerequisites

This collection of scripts depends on the `on_boot.d` from [unifi-utilities](https://github.com/unifi-utilities/unifios-utilities/blob/main/on-boot-script-2.x/README.md). That must be set up and running before you can use these scripts.

You must first have an account set up with [tunnelbroker](https://tunnelbroker.net/) and a tunnel to use. Hurricane Electric will require that your UDMP be pingable from tunnelbroker's IP when you initially provide your IPv4 address, and that connectivity will need to continue if you're using something like ddclient or inadyn to update your IP with tunnelbroker dynamically.

This is my port forward rule for allowing HE to ping my UDMP from the internet (not needed if you're already allowing ping from the internet as a general rule) - tunnelbroker's IP that the pings will come from is `66.220.2.74` at time of writing.

<p align="center">
 <img src="https://user-images.githubusercontent.com/17893990/162670587-27812c6c-3259-4eaf-a1a4-19284b65957b.png" width="50%">
</p>

# Caveat Emptor

This script is not 'supported' in any way by Ubiquiti, and, based on the way the firewall rules are applied, you **MUST** disable ipv6 from your WAN interfaces before you set this up. In order to 'transpose' the Unifi Firewall rules over to the tunnel interface, the method I'm using here takes the ipv6 rules from your default WAN interface and removes them, applying them instead to your new tunnel interface. This is not a problem if you do not have ipv6 working from your ISP, but in the case where (without the tunnel) your WAN interface does have a valid ipv6 address already (perhaps you're just wanting to use a HE tunnel for a static ipv6 network), the firewall configuration script will leave your WAN exposed to ipv6 traffic. So, set your "IPv6 Connection" from your internet connection to `DISABLED` before you proceed.

This set of scripts is intended for the user that is using a HE tunnel in order to get IPv6 connectivity on a single interface. Currently, if you have multiple WANs in a load-balanced setup, OR if your WAN fails over to a secondary WAN, this set of scripts isn't yet robust enough to handle those situations. (See [Issue #1](https://github.com/telnetdoogie/UDMP-ipv6/issues/1))

# Setting up the files

* Add the two files [41-enable-he-ipv6.sh](data/on_boot.d/41-enable-he-ipv6.sh) and [99-add-cronjobs.sh](data/on_boot.d/99-add-cronjobs.sh) to `/data/on_boot.d/`
* Make both of those files executable:
  * `chmod +x /data/on_boot.d/41-enable-he-ipv6.sh`
  * `chmod +x /data/on_boot.d/99-add-cronjobs.sh`
* Create a folder, `mkdir /data/cronjobs/` and put the file [update_ipv6_chains](data/cronjobs/update_ipv6_chains) in that folder.
* Create a folder, `mkdir /data/ipv6/` and drop both files [enable-he-ipv6.sh](/data/ipv6/enable-he-ipv6.sh) and [configure-he-ipv6-chains.sh](/data/ipv6/configure-he-ipv6-chains.sh) in that folder.
* Make both of those files executable:
  * `chmod +x /data/ipv6/enable-he-ipv6.sh`
  * `chmod +x /data/ipv6/configure-he-ipv6-chains.sh`
* Edit the file [/data/ipv6/enable-he-ipv6.sh](/data/ipv6/enable-he-ipv6.sh) and change the two properties `REMOTE_ENDPOINT` and `LOCAL_IPV6` to match the values from `Server IPv4 Address` and `Client IPv6 Address` respectively
  * those values can be found on tunnelbroker.net in your **tunnel details** page

You can either reboot your UDMP at this point, or run `/data/on_boot.d/41-enable-he-ipv6.sh` and `/data/on_boot.d/99-add-cronjobs.sh`.

Log entries related to scripts running will show in `/var/log/messages` with a prefix of `user.info`

# Testing things out

To confirm that ipv6 is working, while logged into the UDMP and after all scripts are installed and have been executed, run `ping6 2600::` and look for valid response:
```
# ping6 2600::
PING 2600:: (2600::): 56 data bytes
64 bytes from 2600::: seq=0 ttl=53 time=32.721 ms
64 bytes from 2600::: seq=1 ttl=53 time=32.720 ms
64 bytes from 2600::: seq=2 ttl=53 time=45.699 ms
64 bytes from 2600::: seq=3 ttl=53 time=32.905 ms
64 bytes from 2600::: seq=4 ttl=53 time=32.579 ms
^C
--- 2600:: ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max = 32.579/35.324/45.699 ms
```

To confirm that your firewall rules are being applied to the `he-ipv6` interface, run `ip6tables-save | grep he-ipv6`
You should see entries similar to this:
```
# ip6tables-save | grep he-ipv6
-A UBIOS_FORWARD_IN_USER -i he-ipv6 -m comment --comment 00000001095216663483 -j UBIOS_WAN2_PF_IN_USER
-A UBIOS_FORWARD_IN_USER -i he-ipv6 -m comment --comment 00000001095216663484 -j UBIOS_WAN_IN_USER
-A UBIOS_FORWARD_OUT_USER -o he-ipv6 -m comment --comment 00000001095216663483 -j UBIOS_WAN2_PF_OUT_USER
-A UBIOS_FORWARD_OUT_USER -o he-ipv6 -m comment --comment 00000001095216663484 -j UBIOS_WAN_OUT_USER
-A UBIOS_FWD_IN_GEOIP_PRECHK -i he-ipv6 -j UBIOS_IN_GEOIP
-A UBIOS_FWD_OUT_GEOIP_PRECHK -o he-ipv6 -j UBIOS_OUT_GEOIP
-A UBIOS_INPUT_GEOIP_PRECHK -i he-ipv6 -j UBIOS_IN_GEOIP
-A UBIOS_INPUT_USER_HOOK -i he-ipv6 -m comment --comment 00000001095216663482 -j UBIOS_WAN_LOCAL_USER
```
...changing rules in the UDMP UI / Admin interface will have the side-effect of wiping firewall / iptables rules and re-applying them to `eth8` and `eth9`. The cron job will scrape the new rules and will re-apply them back to the `he-ipv6` interface if they have been removed. In the cronjob provided, this will occur as often as every minute (if the rules have indeed been changed) - so there may be a slight lag (1 minute or less) between changing firewall rules, and those rules being re-applied to the `he-ipv6` interface.

You can test that the rules are continuing to be updated by the cron job by making a change somewhere in the UI / Admin interface and observing the return of the iptables entries:

```
# ip6tables-save | grep he-ipv6
-A UBIOS_FORWARD_IN_USER -i he-ipv6 -m comment --comment 00000001095216663483 -j UBIOS_WAN2_PF_IN_USER
-A UBIOS_FORWARD_IN_USER -i he-ipv6 -m comment --comment 00000001095216663484 -j UBIOS_WAN_IN_USER
-A UBIOS_FORWARD_OUT_USER -o he-ipv6 -m comment --comment 00000001095216663483 -j UBIOS_WAN2_PF_OUT_USER
-A UBIOS_FORWARD_OUT_USER -o he-ipv6 -m comment --comment 00000001095216663484 -j UBIOS_WAN_OUT_USER
-A UBIOS_FWD_IN_GEOIP_PRECHK -i he-ipv6 -j UBIOS_IN_GEOIP
-A UBIOS_FWD_OUT_GEOIP_PRECHK -o he-ipv6 -j UBIOS_OUT_GEOIP
-A UBIOS_INPUT_GEOIP_PRECHK -i he-ipv6 -j UBIOS_IN_GEOIP
-A UBIOS_INPUT_USER_HOOK -i he-ipv6 -m comment --comment 00000001095216663482 -j UBIOS_WAN_LOCAL_USER

( Admin / UI change made here, rules disappear )

# ip6tables-save | grep he-ipv6
# ip6tables-save | grep he-ipv6

( Wait a while here, rules should return after ~1 minute thanks to cron )

# ip6tables-save | grep he-ipv6
-A UBIOS_FORWARD_IN_USER -i he-ipv6 -m comment --comment 00000001095216663483 -j UBIOS_WAN2_PF_IN_USER
-A UBIOS_FORWARD_IN_USER -i he-ipv6 -m comment --comment 00000001095216663484 -j UBIOS_WAN_IN_USER
-A UBIOS_FORWARD_OUT_USER -o he-ipv6 -m comment --comment 00000001095216663483 -j UBIOS_WAN2_PF_OUT_USER
-A UBIOS_FORWARD_OUT_USER -o he-ipv6 -m comment --comment 00000001095216663484 -j UBIOS_WAN_OUT_USER
-A UBIOS_FWD_IN_GEOIP_PRECHK -i he-ipv6 -j UBIOS_IN_GEOIP
-A UBIOS_FWD_OUT_GEOIP_PRECHK -o he-ipv6 -j UBIOS_OUT_GEOIP
-A UBIOS_INPUT_GEOIP_PRECHK -i he-ipv6 -j UBIOS_IN_GEOIP
-A UBIOS_INPUT_USER_HOOK -i he-ipv6 -m comment --comment 00000001095216663482 -j UBIOS_WAN_LOCAL_USER

```

# Assigning IPv6 Address to your LAN clients

To assign IPv6 addresses to your LAN, you should request a routed /48 from tunnelbroker. You can now manually partition your /48 into as many /64s as you need, and use the "static" assignments on each LAN you want to serve IPv6 addresses to via DHCP.

For example, if your /48 was `2000:ffff:1234::/48`, you could assign `2000:ffff:1234:1::1/64` as your VLAN1's "**IPv6 Gateway/Subnet**" (giving the UDMP itself an address of `2000:ffff:1234:1::1` on that VLAN) and use the range `2000:ffff:1234:1::3` to `2000:ffff:1234:1::7d1` as the DHCP range for that network. That would allow you to have VLANs with address ranges like `2000:ffff:1234:1::/64`, `2000:ffff:1234:2::/64`, `2000:ffff:1234:3::/64` etc etc., although you can partition the /48 however you'd like. My example uses /64s.

In the UDMP Network page that would look like this:

<p align="center">
<img src="https://user-images.githubusercontent.com/17893990/162674285-a84787d6-853e-4b5d-94d4-8d26065d517a.png" width="50%">
</p>

It's a good idea once your LAN clients have received an IPv6 address to ensure that your firewall rules are working as you intend. I use [this](http://www.ipv6scanner.com/cgi-bin/main.py) IPv6 capable port scanner to ensure that my expected rules are working correctly.

# Updating your dynamic IP with TunnelBroker using inadyn

Here is an example `inadyn.conf` entry for tunnelbroker:

```bash
# he.net tunnelbroker
provider default@tunnelbroker.net {
        checkip-server = default
        username = {your_tunnelbroker_login_id}
        password = {your_tunnel_update_key}            # from the advanced tab in tunnel details
        hostname = tunnel{tunnelid}.tunnelbroker.net   # the 'tid' number from the tunnel details page URL
}
```

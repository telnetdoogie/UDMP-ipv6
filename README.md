# IPv6 via tunnelbroker on a UDMP

These script depends on [boostchicken's on_boot utility](https://github.com/boostchicken-dev/udm-utilities/blob/master/on-boot-script/README.md). That must be set up and running before you can use these scripts.

You must first have an account set up with tunnelbroker and a tunnel to use. That will require that your UDMP can be pingable from tunnelbroker's IP especially if using something like ddclient or inadyn to update the IP dynamically.

This is my port forward rule for allowing HE to ping my UDMP from the internet (not needed if you're allowing ping from the internet as a general rule)

![image](https://user-images.githubusercontent.com/17893990/162670587-27812c6c-3259-4eaf-a1a4-19284b65957b.png)

# Setting up the files

* Add the two files [41-enable-he-ipv6.sh](mnt/data/on_boot.d/41-enable-he-ipv6.sh) and [99-add-cronjobs.sh](mnt/data/on_boot.d/99-add-cronjobs.sh) to `/mnt/data/on_boot.d` 
  * (both of these files should be executable with `chmod +x {filename}`
* Add a folder, `/mnt/data/cronjobs` and put the file [update_ipv6_chains](mnt/data/cronjobs/update_ipv6_chains) in that folder.
* Add a folder, `/mnt/data/ipv6` and drop both files [enable-he-ipv6.sh](/mnt/data/ipv6/enable-he-ipv6.sh) and [configure-he-ipv6-chains.sh](/mnt/data/ipv6/configure-he-ipv6-chains.sh) in that folder.
* Edit the file [/mnt/data/ipv6/enable-he-ipv6.sh](/mnt/data/ipv6/enable-he-ipv6.sh) and change the two properties `REMOTE_ENDPOINT` and `LOCAL_IPV6` to match the values from `Server IPv4 Address` and `Client IPv6 Address` respectively
  * those values can be found on tunnelbroker.net in your **tunnel details** page

You can either reboot your UDMP at this point, or run `/mnt/data/on_boot.d/41-enable-he-ipv6.sh` and `/mnt/data/on_boot.d/99-add-cronjobs.sh`. 

Log entries related to scripts running will show in `/var/log/messages` with a prefix of `user.info`

# Testing things out

To confirm that ipv6 is working, while logged into the UDMP and after all scripts are installed and have been executed, run `ping6 2600::` and look for responses.

To confirm that your firewall rules are being applied to the `he-ipv6` interface, run `ip6tables-save | grep he-ipv6`. You should see entries similar to this:
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

...changing rules in the UDMP admin interface will remove firewall / iptables rules and re-apply them to `eth8` and `eth9`. The cron job should re-apply any old and new rules back to the `he-ipv6` interface within each minute, if they have been removed.

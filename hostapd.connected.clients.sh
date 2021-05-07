#!/bin/sh
 
INFO="
# Get the most info from Hostapd, like connected since, ip en mac address, signal levels, etc
#
# For console use : /etc/hostapd/clients.connected.sh
#
# Optional change the SLEEPTIME below
#
#"

####################################################################################################################################
	
# Time for repeated sensor reading, in seconds
SLEEPTIME="5"

####################################################################################################################################

# Copy the dhcpd.conf from other host, for mac and ip address, add reservations first.
rsync anskeuken:/etc/dhcp/dhcpd.conf /tmp


# Going into the loop, so you will have to run it once, change SLEEPTIME above
while true; do

	clear	
	echo "$INFO"
	echo ""
	echo "Connected since\t\tIP address\tMAC Address\t\tSignal\tInAct\tRX/TX MiB\tName"
	echo ""
	# Current date
	CURDATE=`/bin/date --date 'today' '+%d-%m-%y %H:%M:%S'`

	# list all wireless network interfaces 
	# (for MAC80211 driver; see wiki article for alternative commands)
	for interface in `iw dev | grep Interface | cut -f 2 -s -d" "`
		do	
			channelnr=`hostapd_cli status | grep channel | awk 'NR==1 {print; exit}' | grep -o '[[:digit:]]*'`
			channelfreq=`hostapd_cli status | grep freq | cut -c6-`
			ssid=`hostapd_cli status | grep ssid | awk 'NR==2 {print; exit}' | awk '{ print $1 }' | cut -c9-`
			ssidmac=`hostapd_cli status | grep bssid | awk 'NR==1 {print; exit}' | cut -c10-`
			rxonwlan=`ifconfig $interface | grep RX | awk 'NR==1 {print; exit}' | xargs | cut -c4-`
			txonwlan=`ifconfig $interface | grep TX | awk 'NR==1 {print; exit}' | xargs | cut -c4-`
			txpower=`iw dev $interface info | grep txpower | xargs | cut -c9-`


			# for each interface, get mac addresses of connected stations/clients
			maclist=`iw dev $interface station dump | grep Station | cut -f 2 -s -d" "`
			# for each mac address in that list...
			for mac in $maclist
				do
					ip=`cat /tmp/dhcpd.conf | egrep "fixed-address|host|hardware|\}" | grep -i -B 1 -A 2 $mac | grep fixed-address | awk '{ print $2 }' | sed 's/.$//'`
					host=`cat /tmp/dhcpd.conf | egrep "fixed-address|host|hardware|\}" | grep -i -B 1 -A 2 $mac | grep host | awk '{ print $2 }'`
					signal=`iw dev $interface station dump | grep -A 7 $mac | grep signal | awk '{ print $2 }'`
					connectedsince=`hostapd_cli all_sta | grep -i -A 17 $mac | grep connected_time= | grep -o '[[:digit:]]*'`
					clientrxbytes=`hostapd_cli all_sta | grep -A 17 $mac | grep rx_bytes | grep -o '[[:digit:]]*' | awk '{ foo = $1 / 1024 / 1024 ; print foo }' | cut -c1-5`
					clienttxbytes=`hostapd_cli all_sta | grep -A 17 $mac | grep tx_bytes | grep -o '[[:digit:]]*' | awk '{ foo = $1 / 1024 / 1024 ; print foo }' | cut -c1-5`
					inactivetime=`hostapd_cli all_sta | grep -A 17 94:ce:2c:8d:42:2d | grep inactive_msec | grep -o '[[:digit:]]*' | awk '{ foo = $1 / 1000 ; print foo }'`
					eval "echo -n $(date -ud "@$connectedsince" +'$((%s/3600/24)) days %H:%M:%S')"
					echo "\t\t$ip\t$mac\t$signal\t"$inactivetime"s\t$clientrxbytes/$clienttxbytes\t$host"
					
					
				done
		
		echo ""
		echo ""
		echo "# Hostapd Accesspoint information"
		echo ""
		echo "Adapter   : $interface"
		echo "Channel   : $channelnr"
		echo "Frequency : $channelfreq GHz"
		echo "SSID      : $ssid"
		echo "MAC       : $ssidmac"
		echo "TX Power  : $txpower"
		echo "Received  : $rxonwlan"
		echo "Transmit  : $txonwlan"
		echo ""
		echo "Refreshtime $SLEEPTIME Seconds $CURDATE Created by ILoveIOT 2021" 
		done
	sleep $SLEEPTIME
done

	
	
	
	
#EOF



	
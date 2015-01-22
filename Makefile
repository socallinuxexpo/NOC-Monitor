all:
	grep host_name /etc/icinga/objects/hosts.cfg | grep -- '-ap' | grep -v '#' | awk '{ print $2 }' | sort > aps.txt

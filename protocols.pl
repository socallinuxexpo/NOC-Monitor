#!/usr/bin/perl

#
# protocols.pl - get in and out byte counters, make rrd graphs
#
# Copyright 2014 by David Newman
#
# todo:
# DONE 1. Use Net::SNMP instead of a system call to get values
# 2. Align max/avg/current legend for "Out" counters
# 3. Learn to aggregate data from multiple interfaces

use strict;
use warnings;

use Data::Dumper;
use Net::SNMP;
use RRDs;

# define location of rrdtool databases
my $rrd = '/home/jhoblitt/apwatch/rrd';
# define location of images
my $img = '/home/jhoblitt/apwatch/images';
my $ERR = RRDs::error;

my $hostname = 'gateway-2.expo.socallinuxexpo.org';
my $community = 'OnlyIdiotsUsePublic';
my $version = '2c';
my $show = "SCaLE 12x";

# use values from OIDs
# these will get concatenated onto name and byte OIDs
my @interfaces = ('10');

# OID strings for ifDescr, ifHCInOctets, and ifHCOutOctets
# byte counters are 64-bit versions of non-HC counters
# these require @interface values appended to form complete OIDs
my $ifDescr = '1.3.6.1.2.1.2.2.1.2.';
my $in = '1.3.6.1.2.1.31.1.1.1.6.';
my $out = '1.3.6.1.2.1.31.1.1.1.10.';

foreach my $interface (@interfaces) {
	# concatenate to create OIDs
	my @ifDescr = $ifDescr . $interface;
	my @in = $in . $interface;
	my @out = $out . $interface;

	# open SNMP session and get OID values
	my ($session, $error) = Net::SNMP->session(Hostname => $hostname,
Community => $community, Version => $version,);

	die "session error: $error" unless ($session);

	# temp storage of values in $x, $y, $z
	# to avoid reuse of variable names
	# the next six stanzas are very repetitive;
	# could this be looped?

	my $x = $session->get_request(
		-varbindlist => \@ifDescr,
	);

	my $y = $session->get_request(
		-varbindlist => \@in,
	);

	my $z = $session->get_request(
		-varbindlist => \@out,
	);

	# now put temp values back where they belong
	while( my ($k, $v) = each %$x) {
		$ifDescr = $v;
	}
	while( my ($k, $v) = each %$y) {
		$in = $v;
	}
	while( my ($k, $v) = each %$z) {
		$out = $v;
	}

	die 'request error: '. $session->error unless (defined $ifDescr) &&
(defined $in) && (defined $out);

	$session->close;

	# if rrd database doesn't exist, create it
	if (! -e "$rrd/$hostname-ipv6-$interface.rrd") {
		print "creating rrd ipv6 database(s)...\n";
		RRDs::create "$rrd/$hostname-ipv6-$interface.rrd",
			"-s 300",
			"DS:in:COUNTER:600:0:125000000",
			"DS:out:COUNTER:600:0:125000000",
			"RRA:AVERAGE:0.5:1:2016" # 7 Days of 5 Min.
	}

	# insert values into rrd
	RRDs::update "$rrd/$hostname-ipv6-$interface.rrd",
		"-t", "in:out",
		"N:$in:$out";

	# make graphs
    # &RRDGraph($interface, "day", $ifDescr);
	# &RRDGraph($interface, "week", $ifDescr);
	# &RRDGraph($interface, "month", $ifDescr);
	# &RRDGraph($interface, "year", $ifDescr);
}

# make IPv4 graphs
#&RRDGraph(2, 10, "day");
#&RRDGraph(2, 10, "week");

sub RRDGraph {
# creates graph
# inputs: $_[0]: IPv4 interface index (e.g., 2) 
#	  $_[1]: IPv6 interface index (e.g., 10)
#	  $_[2]: period (e.g., day, week, month, year)

	RRDs::graph "$img/$hostname-protocols-$_[2]-live.png",
		"-s -1$_[2]",
		"-S 60",
        "--color=BACK#000000",
		"--color=CANVAS#000000",
		"--color=FONT#FFFFFF",
		"--color=GRID#FFFFFF",
		"--color=MGRID#FFFFFF",
		# "-t $show Internet traffic",
#		"--lazy",
		"--full-size-mode",
        "--border", "0",
		"-h", "450", "-w", "900",
		"-l 0",
		"-a", "PNG",
		"-v bit/s",
		"DEF:in_2=$rrd/$hostname-$_[0].rrd:in:AVERAGE",
		"DEF:in_10=$rrd/$hostname-ipv6-$_[1].rrd:in:AVERAGE",
		"DEF:out_2=$rrd/$hostname-$_[0].rrd:out:AVERAGE",
		"DEF:out_10=$rrd/$hostname-ipv6-$_[1].rrd:out:AVERAGE",
		"CDEF:ipv4in=in_2,in_10,-",
		"CDEF:ipv4out=out_2,out_10,-",
        # convert in and out bytes to bits
		"CDEF:ipv4inbits=ipv4in,8,*",
		"CDEF:ipv4outbits=ipv4out,8,*",
		"CDEF:ipv6inbits=in_10,8,*",
		"CDEF:ipv6outbits=out_10,8,*",
		"CDEF:ipv4outbits_neg=ipv4outbits,-1,*",
		"CDEF:ipv6outbits_neg=ipv6outbits,-1,*",
		"TEXTALIGN:left",
#"AREA:ipv4inbits#FF0000: IPv4 in",
		"LINE:ipv4inbits#FF0000:IPv4 in",
		"LINE2:ipv4inbits#FF0000",
		"GPRINT:ipv4inbits:MAX:  Maximum\\: %5.1lf %S",
		"GPRINT:ipv4inbits:AVERAGE: Average\\: %5.1lf %S",
		"GPRINT:ipv4inbits:LAST: Current\\: %5.1lf %Sbit/s",
		"COMMENT:\\n",
#"AREA:ipv6inbits#00FF00: IPv6 in",
		"LINE:ipv6inbits#00FF00:IPv6 in",
		"LINE2:ipv6inbits#00FF00",
		"GPRINT:ipv6inbits:MAX:  Maximum\\: %5.1lf %S",
		"GPRINT:ipv6inbits:AVERAGE: Average\\: %5.1lf %S",
		"GPRINT:ipv6inbits:LAST: Current\\: %5.1lf %Sbit/s",
		"COMMENT:\\n",
#"AREA:ipv4outbits_neg#0000FF:IPv4 out",
		"LINE:ipv4outbits_neg#0000FF:IPv4 out",
		"LINE2:ipv4outbits_neg#0000FF",
		"GPRINT:ipv4outbits:MAX:  Maximum\\: %5.1lf",
		"GPRINT:ipv4outbits:AVERAGE: Average\\: %5.1lf",
		"GPRINT:ipv4outbits:LAST: Current\\: %5.1lf %Sbit/s",
		"COMMENT:\\n",
#"AREA:ipv6outbits_neg#FFFF00:IPv6 out",
		"LINE:ipv6outbits_neg#FFFF00:IPv6 out",
		"LINE2:ipv6outbits_neg#FFFF00",
		"GPRINT:ipv6outbits:MAX:  Maximum\\: %5.1lf",
		"GPRINT:ipv6outbits:AVERAGE: Average\\: %5.1lf",
		"GPRINT:ipv6outbits:LAST: Current\\: %5.1lf %Sbit/s",
		"HRULE:0#000000";
		if ($ERR = RRDs::error) {
			print "$0: unable to create graph $img/$hostname-$_[0]-$_[1].png:
$ERR\n";
		}
}



# --x-grid HOUR:1:DAY:1:HOUR:6:0:'%A %H%p' -s '06:00 02/21/14' 

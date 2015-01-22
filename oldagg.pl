#!/usr/bin/perl

#
# aggregate.pl - get in and out byte counters, make rrd graphs
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
my $rrd = '/home/jhoblitt/apwatch.bak/rrd';
# define location of images
my $img = '/home/jhoblitt/apwatch/images';
my $ERR = RRDs::error;

my $hostname = 'gateway-2.expo.socallinuxexpo.org';
my $community = 'OnlyIdiotsUsePublic';
my $version = '2c';
my $show = "SCaLE 12x";

# use values from OIDs
# these will get concatenated onto name and byte OIDs
my @interfaces = ('2');

# OID strings for ifDescr, ifHCInOctets, and ifHCOutOctets
# byte counters are 64-bit versions of non-HC counters
# these require @interface values appended to form complete OIDs
my $ifDescr = '1.3.6.1.2.1.2.2.1.2.';
my $in = '1.3.6.1.2.1.31.1.1.1.6.';
my $out = '1.3.6.1.2.1.31.1.1.1.10.';

# foreach my $interface (@interfaces) {
# 	# concatenate to create OIDs
# 	my @ifDescr = $ifDescr . $interface;
# 	my @in = $in . $interface;
# 	my @out = $out . $interface;
# 
# 	# open SNMP session and get OID values
# 	my ($session, $error) = Net::SNMP->session(Hostname => $hostname,
# Community => $community, Version => $version,);
# 
# 	die "session error: $error" unless ($session);
# 
# 	# temp storage of values in $x, $y, $z
# 	# to avoid reuse of variable names
# 	# the next six stanzas are very repetitive;
# 	# could this be looped?
# 
# 	my $x = $session->get_request(
# 		-varbindlist => \@ifDescr,
# 	);
# 
# 	my $y = $session->get_request(
# 		-varbindlist => \@in,
# 	);
# 
# 	my $z = $session->get_request(
# 		-varbindlist => \@out,
# 	);
# 
# 	# now put temp values back where they belong
# 	while( my ($k, $v) = each %$x) {
# 		$ifDescr = $v;
# 	}
# 	while( my ($k, $v) = each %$y) {
# 		$in = $v;
# 	}
# 	while( my ($k, $v) = each %$z) {
# 		$out = $v;
# 	}
# 
# 	die 'request error: '. $session->error unless (defined $ifDescr) &&
# (defined $in) && (defined $out);
# 
# 	$session->close;
# 
# 	# if rrd database doesn't exist, create it
# 	if (! -e "$rrd/$hostname-$interface.rrd") {
# 		print "creating rrd database for $hostname $ifDescr...\n";
# 		RRDs::create "$rrd/$hostname-$interface.rrd",
# 			"-s 300",
# 			"DS:in:COUNTER:600:0:125000000",
# 			"DS:out:COUNTER:600:0:125000000",
# 			"RRA:AVERAGE:0.5:1:2016" # 7 Days of 5 Min.
# 	}
# 
# 	# insert values into rrd
# 	RRDs::update "$rrd/$hostname-$interface.rrd",
# 		"-t", "in:out",
# 		"N:$in:$out";
# 
	# make graphs
&RRDGraph("year");
&RRDGraph("month");

sub RRDGraph {
# creates graph
#	  $_[0]: period (e.g., day, week, month, year)
#	  $_[2]: ifDescr (e.g., GigabitEthernet1/0/1)

	RRDs::graph "$img/aggregate_aps-$_[0].png",
		"-s -1$_[0]",
		"--color=BACK#000000",
		"--color=CANVAS#000000",
		"--color=FONT#FFFFFF",
		"--color=GRID#FFFFFF",
		"--color=MGRID#FFFFFF",
		# "-t Current associations",
#		"--lazy",
		"--full-size-mode",
                "-h", "450", "-w", "900",
		"-l 0",
		"-a", "PNG",
		"-v Current associations",
		"DEF:classroom=$rrd/aggregate.rrd:classroom:AVERAGE",
		"DEF:scale24=$rrd/aggregate.rrd:scale24:AVERAGE",
		"DEF:scale5=$rrd/aggregate.rrd:scale5:AVERAGE",
		"DEF:steve=$rrd/aggregate.rrd:steve:AVERAGE",
		"DEF:steve5=$rrd/aggregate.rrd:steve5:AVERAGE",
		"TEXTALIGN:left",
        #"AREA:aggregate#32CD32: In",
		"LINE1:classroom#336600",
		"LINE2:scale24#446600",
		"LINE3:scale5#556600",
		"LINE4:steve#666600",
		"LINE5:steve5#776600",
        #"GPRINT:aggregate:MAX:  Maximum\\: %5.1lf %S",
		"GPRINT:classroom:AVERAGE: classroom\\: %5.1lf %S",
		"GPRINT:scale24:AVERAGE: scale24\\: %5.1lf %S",
		"GPRINT:scale5:AVERAGE: scale5\\: %5.1lf %S",
		"GPRINT:steve:AVERAGE: steve\\: %5.1lf %S",
		"GPRINT:steve5:AVERAGE: steve5\\: %5.1lf %S",
        #"GPRINT:aggregate:LAST: Current\\: %5.1lf %Sbit/s",
		"COMMENT:\\n",
		"HRULE:0#000000";
		if ($ERR = RRDs::error) {
			print "$0: unable to create graph $img/aggregate_aps-$_[0].png:
$ERR\n";
		}
}


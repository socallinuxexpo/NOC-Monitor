#!/usr/bin/perl

#
# sums.pl - make rrd graphs of band distribution of 802.11 clients
#
# Copyright 2014 by David Newman
#

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

# make graphs
&RRDGraph("day");
&RRDGraph("week");

sub RRDGraph {
# creates graph
#	  $_[0]: period (e.g., day, week, month, year)
#	  $_[2]: ifDescr (e.g., GigabitEthernet1/0/1)

	RRDs::graph "$img/sums-6hourly-live.png",
		"-S 60",
        "-s -1$_[0]",
        "--color=BACK#000000",
        "--color=CANVAS#000000",
        "--color=FONT#FFFFFF",
        "--color=GRID#FFFFFF",
        "--color=MGRID#FFFFFF",
		# "-t Total associations",
#		"--lazy",
		"--full-size-mode",
        "--border", "0",
        "-h", "450", "-w", "900",
		"-l 0",
		"-a", "PNG",
		"-v Total sums associations",
		"DEF:all=$rrd/sums.rrd:all:AVERAGE",
		"DEF:freq_24=$rrd/sums.rrd:freq_24:AVERAGE",
		"DEF:freq_5=$rrd/sums.rrd:freq_5:AVERAGE",
		"TEXTALIGN:left",
		"LINE2:all#336600",
		"LINE2:freq_24#446600",
		"LINE2:freq_5#556600",
		"GPRINT:all:AVERAGE: All\\: %5.1lf %S",
		"GPRINT:freq_24:AVERAGE: 2.4 GHz\\: %5.1lf %S",
		"GPRINT:freq_5:AVERAGE: 5 GHz\\: %5.1lf %S",
		"COMMENT:\\n",
		"HRULE:0#000000";
		if ($ERR = RRDs::error) {
			print "$0: unable to create graph $img/sums-6hourly.png:
$ERR\n";
		}
}


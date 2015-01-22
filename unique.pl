#!/usr/bin/perl

#
# unique.pl - make rrd graphs of total # of AP associations
#
# Copyright 2014 by David Newman
#
# todo:
# DONE 1. Use Net::SNMP instead of a system call to get values
# 2. Align max/avg/current legend for "Out" counters
# 3. Learn to unique data from multiple interfaces

use strict;
use warnings;

use Data::Dumper;

# define location of rrdtool databases
my $rrd = '/home/jhoblitt/apwatch/rrd';
# define location of images
my $img = '/home/jhoblitt/apwatch/images';



system("rrdtool graph $img/unique-6hourly-live.png --x-grid HOUR:1:DAY:1:HOUR:6:0:'%A %H%p' -s '06:00 02/21/14' -S 600 --color=BACK#000000 --color=CANVAS#000000 --color=FONT#FFFFFF --color=GRID#7F7F7F --color=MGRID#FFFFFF -t 'Total associations' --full-size-mode --border 0 -h 450 -w 900 -l 0 -a PNG -v 'Total unique associations' DEF:unique_mac=$rrd/unique.rrd:unique_mac:AVERAGE TEXTALIGN:left LINE2:unique_mac#00FF00 AREA:unique_mac#00FF00:'Total unique Wi-Fi MACs : ' GPRINT:unique_mac:LAST:%5.1lf HRULE:0#000000")



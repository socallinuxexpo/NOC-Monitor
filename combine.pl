#!/usr/bin/perl

use strict;
use warnings;
use RRDs;

# combined.pl - graph aggregate traffic from show floor switches (as seen on switch-1 ports 21-22)
# copyright 2014 by David Newman

my $hostname = 'switch-1.expo.socallinuxexpo.org';
# define location of rrdtool databases
my $rrd = '/home/jhoblitt/apwatch/rrd';
# define location of images
my $img = '/home/jhoblitt/apwatch/images';
my $ERR = RRDs::error;
my $showname = "SCaLE 12x";
my $interface = 0;


system("rrdtool graph $img/combined-day.png --x-grid HOUR:1:DAY:1:HOUR:6:0:'%A %H%p' -s '06:00 02/21/14' --color=BACK#000000 --color=CANVAS#000000 --color=FONT#FFFFFF --color=GRID#7F7F7F --color=MGRID#FFFFFF --full-size-mode --border 0 -h 450 -w 900 -l 0 -a PNG -v bit/s DEF:in21=$rrd/$hostname-21.rrd:out:AVERAGE DEF:in22=$rrd/$hostname-22.rrd:out:AVERAGE DEF:out21=$rrd/$hostname-21.rrd:in:AVERAGE DEF:out22=$rrd/$hostname-22.rrd:in:AVERAGE CDEF:in=in21,in22,+ CDEF:out=out21,out22,+ CDEF:inbits=in,8,* CDEF:outbits=out,8,* CDEF:out_neg=outbits,-1,* TEXTALIGN:left AREA:inbits#32CD32:In GPRINT:inbits:'MAX:  Maximum\\: %5.1lf %S' GPRINT:inbits:'AVERAGE: Average\\: %5.1lf %S' GPRINT:inbits:'LAST: Current\\: %5.1lf %Sbit/s' COMMENT:'\\n' AREA:out_neg#4169E1:Out GPRINT:outbits:'MAX:  Maximum\\: %5.1lf %S' GPRINT:outbits:'AVERAGE: Average\\: %5.1lf %S' GPRINT:outbits:'LAST: Current\\: %5.1lf %Sbit/s' HRULE:0#000000");

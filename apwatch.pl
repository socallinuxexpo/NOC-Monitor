#!/usr/bin/env perl

# Copyright 2012 Joshua C Hoblitt

use strict;
use warnings;

use Net::SNMP;
use RRD::Simple ();
use DateTime;

use FindBin qw($Bin);
use Getopt::Long qw( GetOptions );
use Data::Dumper;

my $image_path  = "${Bin}/images";
my $rrd_path    = "${Bin}/rrd";
my $public      = 'OnlyIdiotsUsePublic';

my $OID_sysLocation = '1.3.6.1.2.1.1.6.0';

my %oids = (
    '1.3.6.1.4.1.2021.8.1.101.2' => 'scale-slow',
    '1.3.6.1.4.1.2021.8.1.101.3' => 'steve-slow',
    '1.3.6.1.4.1.2021.8.1.101.5' => 'scale',
    '1.3.6.1.4.1.2021.8.1.101.6' => 'steve',
);

my $debug   = 0;
my $ap_list = "${Bin}/aps.txt";
GetOptions(
    'ap_list=s' => \$ap_list,
    'debug|d'   => \$debug,
) or die "failed to parse options";

my @aps;
open(my $file, $ap_list) or die "can not open file: $!";
foreach my $line (<$file>) {
    next if $line =~ /\s*\#/;
    chomp $line;
    print "parsed line as: $line\n" if $debug;
    push @aps, $line;
}
close($file) or die "can not close file: $!";

my %aggregate;
# init aggregate values in case no AP is up/function with that ssid
foreach my $ssid (values %oids) {
    $aggregate{$ssid} = 0;
}

AP: foreach my $ap (@aps) {
    my $ap_name;
    my %data;
    OID: foreach my $oid (keys %oids) {
        my ($session, $error) = Net::SNMP->session(
          -hostname  => $ap,
          -community => $public,
          -timeout   => 1,
        );

        if (!defined $session) {
            printf "ERROR: %s.\n", $error;
            # completely give up on polling this device
            next AP;
        }

        my $result = $session->get_request(-varbindlist => [ $oid, $OID_sysLocation ],);

        if (!defined $result) {
            printf "ERROR: %s.\n", $session->error();
            $session->close();
            # completely give up on polling this device
            next AP;
        }

        my $r = $result->{$oid};
        unless ($r =~ /^\d+$/) {
            print "$ap - $oid: ";
            print "response was not numeric: $r\n";
            # maybe just this one OID was bad, keep trying other OIDs on this
            # AP
            next OID;
        }

        # it appears that snmp is giving us strings back and feeding these into
        # rrdtool gives us nans
        $r = int $r;

        $aggregate{$oids{$oid}} += $r;
        $data{$oids{$oid}} = $r;

        # yes, we're inefficent setting this every time we check a different
        # ssid/oid per ap
        $ap_name = $result->{$OID_sysLocation};
    }

    if (keys %data) {
        update_rrd($ap, $ap_name, \%data);
    }
}

if (keys %aggregate) {
    update_rrd("aggregate", "aggregate", \%aggregate);
}

my %sums = (
	'freq_24' => int($aggregate{'scale-slow'} + $aggregate{'steve-slow'}),
	'steve' => int($aggregate{'steve-slow'} + $aggregate{'steve'}),
	'freq_5' => int($aggregate{'scale'} + $aggregate{'steve'}),
	'scale' => int($aggregate{'scale-slow'} + $aggregate{'scale'}),
	'all' => int($aggregate{'steve-slow'} + $aggregate{'steve'} + $aggregate{'scale-slow'} + $aggregate{'scale'}),
);

update_rrd("sums", "sums", \%sums);

# grep clients-wlan /var/log/messages | perl -ne 'print $1,"\n" if $_ =~ /(..:..:..:..:..:..)/' | sort -u | wc -l

my %macs;
open(my $logfile, "cat /var/log/messages /var/log/messages.1 |") or die "can not open file: $!";
foreach my $line (<$logfile>) {
    if ($line =~ /(..:..:..:..:..:..)/) {
        $macs{$1}++;
    }
}
close($logfile) or die "can not close: $!";

my $umacs = keys %macs;

update_rrd("unique", "unique", { unique_mac => int $umacs});

# flush out a file of unique mac addresses
open(my $macfile, '>', "${Bin}/macs.txt") or die "can not open file: $!";
foreach my $m (sort keys %macs) {
    print $macfile $m, "\n";
}
close($macfile) or die "can not close: $!";

my @plot_aps;
opendir(my $rrddir, $rrd_path) or die "$!";
while((my $filename = readdir($rrddir))){
    next unless $filename =~ /\.rrd$/;
    print "found rrd file: $filename\n" if $debug;
    $filename =~ /^(.+)\.rrd/;
    push @plot_aps, $1;
}
closedir($rrddir) or die "$!";

@plot_aps = grep { !/sums|aggregate|unique/ } sort @plot_aps;
my $all_aps = ['sums', 'aggregate', 'unique', @plot_aps];
generate_index_page('hourly', $all_aps);
generate_index_page('6hourly', $all_aps);
generate_index_page('12hourly', $all_aps);
generate_index_page('daily', $all_aps);
generate_index_page('weekly', $all_aps);

{
    my $index_path = $image_path . "/" . "index.html";
    unless (-e $index_path) {
        symlink("hourly.html", $index_path);
    }
}

sub update_rrd {
    my ($ap, $ap_name, $data) = @_;

    print DateTime->now->iso8601, ", $ap, $ap_name";
    foreach my $key (keys %$data) {
      print ", $key => $data->{$key}";
    }
    print "\n";

    my $rrdfile = $rrd_path . "/" . "$ap.rrd";
    #$RRD::Simple::DEBUG=1;
    #$Carp::Verbose=1;
    my $rrd = RRD::Simple->new(
        file => $rrdfile,
        default_dstype => "GAUGE",
        on_missing_ds => "add",
    );

    #print Dumper($data);
    if (! -e $rrdfile) {
        $rrd->create($rrdfile, 'month', map { $_ => 'GAUGE' } keys %{$data});
    } else {
    	$rrd->update(%{$data});
    }

    my $periods = [ qw(hour 6hour 12hour day week) ];
#    $rrd->{cf} = 'MAX';
    my %rtn = $rrd->graph($rrdfile,
        destination => $image_path,
        basename => $ap,
        timestamp => "rrd", # graph, rrd, both or none
#       periods => [ qw(hour day week month year) ], # omit to generate all graphs
        periods => $periods, # omit to generate all graphs
        sources => [ keys %$data ],
    #   source_colors => [ qw(ff0000 aa3333 000000) ],
        source_labels => [ keys %$data],
    #   source_drawtypes => [ qw(LINE1 AREA LINE) ],
        line_thickness => 2,
        extended_legend => 1,
        title => $ap_name,
        vertical_label => 'associations',
    );

my $html =<<END;
<html>
<head>
    <meta http-equiv="refresh" content="30"> 
</head>
<body>
END

    foreach my $p (@{$periods}) {
        # the name of the day graph is "daily" instead of "dayly"
        if ($p eq "day") { $p = "dai"; }
        $html .= "<img src=\"./${ap}-${p}ly.png\">\n";
    }

    $html .= "</body>\n";
    $html .= "</html>\n";

    my $index_file = $image_path . "/" . "$ap.html";
    open(my $fh, ">$index_file") or return undef;
    print $fh $html;
    close($fh);

    return 1;
}

sub generate_index_page {
    my ($graph_name, $ap_list) = @_;

my $html =<<END;
<html>
<head>
    <meta http-equiv="refresh" content="30"> 
</head>
<body>
END

    foreach my $ap (@{$ap_list}) {
        $html .= "<a href=\"${ap}.html\"><img src=\"./${ap}-${graph_name}.png\"></a>\n";
    }

    $html .= "</body>\n";
    $html .= "</html>\n";

    my $index_file = $image_path . "/" . "${graph_name}.html";
    open(my $fh, ">$index_file") or return undef;
    print $fh $html;
    close($fh);
}

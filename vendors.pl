#!/usr/bin/env perl

# Copyright (c) 2012 Joshua Hoblitt

use strict;
use warnings;

use Net::MAC::Vendor;

use Data::Dumper;

Net::MAC::Vendor::load_cache();

my %vendors;
foreach my $mac (<>) {
    chomp $mac;
    my $oui = Net::MAC::Vendor::fetch_oui_from_cache( $mac );
    my $v = @$oui[0];
    if ((not defined($v)) or $v =~ /^\s+$/) {
        $v = '[unknown]';
    } else {
        $v = lc($v);
    }
    if ($v =~ /apple/) { $v = "apple, inc" };
    if ($v =~ /samsung/) { $v = "samsung electronics co,ltd" };
    if ($v =~ /azurewave/) { $v = "azurewave technologies, inc" };
    if ($v =~ /intel/) { $v = "intel corporation" };
    if ($v =~ /hon hai/) { $v = "hon hai precision ind. co.,ltd." };
    if ($v =~ /motorola/) { $v = "motorola mobility, inc." };
    if ($v =~ /liteon/) { $v = "liteon technology corporation" };
    if ($v =~ /askey/) { $v = "askey computer corp" };
    if ($v =~ /rim/) { $v = "research in motion" };
    if ($v =~ /lite-on technology corp./) { $v = "liteon technology corporation" };
    $vendors{$v}++;
}

sub hashValueDescendingNum {
   $vendors{$b} <=> $vendors{$a};
}

foreach my $key (sort hashValueDescendingNum (keys(%vendors))) {
   print "$vendors{$key} \t $key\n";
}
#print Dumper(\%vendors);

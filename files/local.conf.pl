#!/bin/env perl

use strict;
use warnings;

my $prefix = "PX_CONF_";

my @vars = `env | grep "^$prefix"`;
foreach my $var (@vars) {
    chomp($var); # remove last \n

    my @pair = split(/=/, $var, 2);
    # print "$pair[0] = $pair[1]";
    my $name = substr($pair[0], length($prefix));
    my $val  = $pair[1];
    print "$name=\"$val\"\n";
}

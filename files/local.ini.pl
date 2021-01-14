#!/bin/env perl

# https://github.com/nordic-institute/X-Road/blob/6.23.0/doc/Manuals/ug-syspar_x-road_v6_system_parameters.md

use strict;
use warnings;

my $prefix = "PX_INI_";

# From https://github.com/nordic-institute/X-Road/blob/6.23.0/doc/Manuals/ug-syspar_x-road_v6_system_parameters.md#table-of-contents
my %sections = (
    # Security Server System Parameters
    common              => 'common',
    proxy               => 'proxy',
    proxyui             => 'proxy-ui',
    signer              => 'signer',
    antidos             => 'anti-dos',
    configurationclient => 'configuration-client',
    messagelog          => 'message-log',
    envmonitor          => 'env-monitor',
    # Central Server System Parameters
    center              => 'center',
    # Configuration Proxy System Parameters
    configurationproxy  => 'configuration-proxy',
    proxyuiapi          => 'proxy-ui-api',
);

my @vars = sort `env | grep "^$prefix"`;
my $last_section = '';

# eg: PX_INI_MESSAGELOG_ARCHIVE_PATH=/var/lib/xroad
foreach my $env (@vars) {
    my $result = parse($env);
    if (!$result) {
        next;
    }

    # print the section part of the ini file only when it has changed
    if ($result->{section} ne $last_section) {
        printf "[$result->{section}]\n";
    }
    $last_section = $result->{section};

    printf "$result->{name}=\"$result->{value}\"\n";
}

# Parse environment variables into perl hashes
# eg: PX_INI_MESSAGELOG_ARCHIVE_PATH=/var/lib/xroad
# becomes:
# {
#   section: 'message-log',
#   name: 'archive-path',
#   value: '/var/lib/xroad'
# }
sub parse {
    my ($env) = @_;
    chomp($env); # remove last \n

    my $prefix_removed = substr($env, length($prefix));
    my @pair = split(/_/, $prefix_removed, 2);
    if (scalar @pair < 2) {
        return undef
    }

    # eg: messagelog
    my $section_id = $pair[0];

    # eg: message_log
    my $section_name = $sections{lc($section_id)};
    if (! $section_name) {
        return undef;
    }

    # eg: ARCHIVE_PATH=/var/lib/xroad
    my $section_removed = $pair[1];

    @pair = split(/=/, $section_removed, 2);
    if (scalar @pair < 2) {
        return undef
    }

    # eg: ARCHIVE_PATH
    my $var_name = $pair[0];
    $var_name = lc($var_name); # lowercase
    $var_name =~ s/_/-/g; # underscores to dashes
    # eg: archive-path

    # eg: /var/lib/xroad
    my $value    = $pair[1];

    return {
        section => $section_name,
        name    => $var_name,
        value   => $value,
    };
}

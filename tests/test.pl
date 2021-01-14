#!/bin/env perl

use strict;
use warnings;
use Test::More;

my $ini = 'files/local.ini.pl';
my $conf = 'files/local.conf.pl';

is( run($ini, { PX_INI_MESSAGELOG_ARCHIVE_PATH => '/var/lib/xroad' }),
    "[message-log]\narchive-path=\"/var/lib/xroad\"\n",
    'PX_INI_MESSAGELOG_ARCHIVE_PATH' );
is( run($ini, { PX_INI_MESSAGELOG_A => '128' }),
    "[message-log]\na=\"128\"\n",
    'PX_INI_MESSAGELOG_A' );
is( run($ini, { PX_INI_PROXY_ALLOW_GET_WSDL_REQUEST => 'true' }),
    "[proxy]\nallow-get-wsdl-request=\"true\"\n",
    'PX_INI_PROXY_ALLOW_GET_WSDL_REQUEST' );
is( run($ini, { PX_INI_PROXYUIAPI_SSL_PROPERTIES => '/etc/xroad/ssl.properties' }),
    "[proxy-ui-api]\nssl-properties=\"/etc/xroad/ssl.properties\"\n",
    'PX_INI_PROXYUIAPI_SSL_PROPERTIES' );

is( run($conf, { PX_CONF_PROXY_PARAMS => ' -Xms100m -Xmx1536m -XX:MaxMetaspaceSize=128m -Djavax.net.ssl.sessionCacheSize=10000 -Dlogback.configurationFile=/etc/xroad/conf.d/proxy-logback.xml -Dxroad.proxy.clientHandlers=${CLIENT_HANDLERS#?} -Dxroad.proxy.serverServiceHandlers=${SERVICE_HANDLERS#?} -Dxroad.proxy.serverRestServiceHandlers=${SERVICE_REST_HANDLERS#?}' }),
    'PROXY_PARAMS=" -Xms100m -Xmx1536m -XX:MaxMetaspaceSize=128m -Djavax.net.ssl.sessionCacheSize=10000 -Dlogback.configurationFile=/etc/xroad/conf.d/proxy-logback.xml -Dxroad.proxy.clientHandlers=${CLIENT_HANDLERS#?} -Dxroad.proxy.serverServiceHandlers=${SERVICE_HANDLERS#?} -Dxroad.proxy.serverRestServiceHandlers=${SERVICE_REST_HANDLERS#?}"' . "\n",
    'PX_CONF_PROXY_PARAMS' );

done_testing;

sub run {
    my ($target, $env_vars) = @_;

    # Temporary set environment variable
    local %ENV = %ENV;
    foreach my $key (keys %$env_vars) {
        $ENV{$key} = $env_vars->{$key};
    }

    my $stdout = `perl $target`;
    return $stdout;
}

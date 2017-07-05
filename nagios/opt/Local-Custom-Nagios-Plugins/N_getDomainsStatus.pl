#!/usr/bin/perl

use REST::Client;
use MIME::Base64;
use JSON;

# Configurables

my $server = $ARGV[0];
my $port = "5554";
my $endpoint = $server.":".$port;
my $userpass = "admin:admin";

my $currentDomain = $ARGV[1];
my $uri = "/mgmt/status/$currentDomain/ObjectStatus";

# Older implementations of LWP check this to disable server verification
#$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

# Set up the connection

my $client = REST::Client->new();

# Newer implementations of LWP use this to disable server verification
# Try SSL_verify_mode => SSL_VERIFY_NONE.  0 is more compatible, but may be deprecated

$client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
$client->getUseragent()->ssl_opts( verify_hostname => 0 );

$client->setHost("https://$endpoint");
$client->addHeader( "Authorization", "Basic " . encode_base64($userpass) );

# Perform a HTTP GET on this URI
$client->GET($uri);
die $client->responseContent() if ( $client->responseCode() >= 300 );

# Add the node to the list of draining nodes
my $r = decode_json( $client->responseContent() );
my $resp = $r->{ObjectStatus};

my $isAllUp = 0;

if ($resp->[0]{EventCode} eq "0x00360026"){
	print " - E - "."Domain is down";
	$isAllUp = 2;
}else{
	for ( my $i = 0 ; $i < ( scalar @{$resp} ) ; $i++ ) {
	        my $className = $resp->[$i]{Class};
        	if ( $className eq 'WSGateway'
	                || $className eq 'XMLFirewallService'
     		        || $className eq 'MultiProtocolGateway'
       	        	|| $className eq 'B2BGateway'
                	|| index($className, "Handler") != -1)
        	{
                	if($resp->[$i]{OpState} eq 'down' && $resp->[$i]{AdminState} eq 'disabled'){
                        	print " - W - ".$resp->[$i]{Class}."->".$resp->[$i]{Name}."->".$resp->[$i]{AdminState}."+".$resp->[$i]{OpState}."\n";
                        	if ($isAllUp lt 1) {$isAllUp = 1;}
                	} elsif($resp->[$i]{OpState} eq 'down'){
                        	print " - E - ".$resp->[$i]{Class}."->".$resp->[$i]{Name}."->".$resp->[$i]{AdminState}."+".$resp->[$i]{OpState}."\n";
                        	if ($isAllUp lt 1) {$isAllUp = 2};
                	}
        	}
	}
}

if ($isAllUp eq 0){print "Objects Status OK";}
exit($isAllUp);

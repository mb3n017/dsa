#!/usr/bin/perl

use REST::Client;
use MIME::Base64;
use JSON;

# Configurables
$hostaddress = $ARGV[0];
$endpoint = $hostaddress.":5554";
$userpass = "admin:admin";

$uri = "/mgmt/status/default/ObjectStatus";

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

for ( my $i = 0 ; $i < ( scalar @{$resp} ) ; $i++ ) {
	my $className = $resp->[$i]{Class};
	if ( $className eq 'CryptoCertificate' || $className eq 'Domain' || $className eq 'RaidVolume' || $className eq 'B2BPersistence') {
		if($resp->[$i]{OpState} eq 'down' && $resp->[$i]{AdminState} eq 'disabled'){
			print "- W - ".$resp->[$i]{Class}."->".$resp->[$i]{Name}."->".$resp->[$i]{AdminState}."+".$resp->[$i]{OpState}." ";
			if ($isAllUp lt 1) {
				$isAllUp = 1;
			}
		} elsif($resp->[$i]{OpState} eq 'down'){
			print "- E - ".$resp->[$i]{Class}."->".$resp->[$i]{Name}."->".$resp->[$i]{AdminState}."+".$resp->[$i]{OpState}." ";
			if ($isAllUp lt 2) {
				$isAllUp = 2
			};
		}
	}
}

exit($isAllUp);

#!/usr/bin/perl -w

################################################################################

################################################################################

use strict;
use warnings;

use REST::Client;
use MIME::Base64;
use JSON;

################################################################################
#define variables
################################################################################

my $server = $ARGV[0];
my $port = "5554";
my $endpoint = $server.":".$port;
my $userpass = "admin:admin";
my $uri = "/mgmt/domains/config/";
my $newDomains = 0;
my $newDomainsList;
my $hostname = $ARGV[1];
my $path_to_services = "/var/local/nagios/dsa/".$hostname."/*";
my $path_to_servicesdir = "/var/local/nagios/dsa/".$hostname;

################################################################################
#Set up the connection
################################################################################

my $client = REST::Client->new();

$client->getUseragent()->ssl_opts( SSL_verify_mode => 0 );
$client->getUseragent()->ssl_opts( verify_hostname => 0 );

$client->setHost("https://$endpoint");
$client->addHeader( "Authorization", "Basic " . encode_base64($userpass) );

################################################################################
#Perform a HTTP GET on this URI and parse response
################################################################################

$client->GET($uri);
die $client->responseContent() if ( $client->responseCode() >= 300 );
my $r = decode_json( $client->responseContent() );

my $resp = $r->{domain};

for ( my $i = 0 ; $i < ( scalar @{$resp} ) ; $i++ ) {
        my $domainName = $resp->[$i]{name};
	find_match($domainName);
}
################################################################################
#compare to existing domains
################################################################################
sub find_match
{
	my $currentDomain = shift;
	if (index($currentDomain, ".INF") == -1 && index($currentDomain, ".DEV") == -1 && index($currentDomain, ".VAL") == -1){
		mkdir $path_to_servicesdir,0755;
		open FILE,">>$path_to_servicesdir/$currentDomain.cfg" || die "Couldn't open: $!";
		my $host_cfg = `grep $currentDomain $path_to_services`;
		if($host_cfg !~ m/$currentDomain/g){
			$newDomains = 1;
			$newDomainsList .= $currentDomain." ";
			print FILE "define service{
	use                     generic-service
        host_name         	$hostname 
        service_description     [$currentDomain] ObjectsStatus
        check_command           check_dsa_domain!$currentDomain
        }\n";
		}
	}

	return 0;
}	

if ($newDomains eq 0){
	print "OK - no new domain"
} else {
	print $newDomainsList;
}
exit($newDomains);

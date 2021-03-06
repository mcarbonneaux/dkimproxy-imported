#!/usr/bin/perl

use strict;
use warnings;

use TestHarnass;
use Test::More tests => 5;

my $tester = TestHarnass->new;
$tester->make_private_key("/tmp/private.key");
$tester->{proxy_args} = [
		"--conf_file=single_domain.conf",
		];
$tester->start_servers;

my @signatures;
eval {

@signatures = $tester->generate_signatures("msg1.txt");
ok(@signatures == 2, "should be two signatures");
ok($signatures[0]->domain eq "domain1.example", "found expected d= argument");
ok($signatures[1]->domain eq "domain1.example", "found expected d= argument");

@signatures = $tester->generate_signatures("msg3.txt");
ok(@signatures == 1, "should be one signature");
ok($signatures[0]->domain eq "domain1.example", "found expected d= argument");

};
my $E = $@;
$tester->shutdown_servers;
die $E if $E;

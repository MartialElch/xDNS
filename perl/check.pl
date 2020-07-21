#!/usr/bin/perl -w
use strict;

# count fixed addresses
# count dhcp addresses

use lib ".";

use Database;
use System;
use DBConfig;

my $db = new Database(host => $DBConfig::DB_HOSTNAME, database => $DBConfig::DB_DATABASE, user =>$DBConfig::DB_USERNAME, password => $DBConfig::DB_PASSWORD);
$db->connect();

my $query = sprintf("SELECT * FROM System");
my @list = @{$db->getList($query)};

foreach (@list) {
	print $_->{MAC}, "\n";
	print $_->{description}, "\n";
	print $_->{fixed}, "\n";
}


exit 0

__END__
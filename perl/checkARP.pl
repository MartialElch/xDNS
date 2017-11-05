#!/usr/bin/perl -w
use strict;

use Database;
use System;
use DBConfig;

my @arp = `arp -a`;

my $BYTE = qr/[0-2]?[0-9][0-9]?/x;
my $HEX = qr/[a-fA-F0-9][a-fA-F0-9]/x;
my $IPv4 = qr/$BYTE\.$BYTE\.$BYTE\.$BYTE/x;
my $MAC = qr/$HEX:$HEX:$HEX:$HEX:$HEX:$HEX/x;

my @ip;
my @mac;

my $i = 0;
foreach (@arp) {
    chomp;
    print $i++, ": ", $_, "\n";
    if (/^(\S+)\s+\(($IPv4)\)\s+at\s+($MAC)/) {
        print $2, " ", $3, "\n";
        push @ip, $2;
        push @mac, $3;
    } elsif (/^(\S+)\s+\(($IPv4)\)\s+at\s+<incomplete>/) {
        print $2, " incomplete\n";
        push @ip, $2;
    } else {
        print "found something odd\n";
    }
}

# check for doubles
my %hash;

# check for double IPs
foreach (@ip) {
    $hash{$_}++;
    if ($hash{$_} > 1) {
        print $_, " is a double\n";
    }
}

# check for double MACs
undef %hash;
foreach (@mac) {
    $hash{$_}++;
    if ($hash{$_} > 1) {
        print $_, " is a double\n";
    }
}

# check MAC registered in database

my $db = new Database(host => $DBConfig::DB_HOSTNAME, database => $DBConfig::DB_DATABASE, user =>$DBConfig::DB_USERNAME, password => $DBConfig::DB_PASSWORD);
$db->connect();
foreach (@mac) {
    my $system = new System(database => $db);
    $system->getByMac($_);
    if ($system->{MAC} ne "") {
        $system->show();
    } else {
        $system->MAC($_);
        $system->insert();
    }
}

my $system = new System(database => $db);
$system->getByMac("c8:0e:14:cc:9d:ca");
$system->show();
$system = new System(database => $db);
$system->getByMac("80:ea:96:e9:2c:8a");
$system->show();
# $system->insert();

$db->disconnect();
exit;

__END__

#!/usr/bin/perl -w
use strict;

use lib ".";

use Database;
use DBConfig;
use DHCP;

my $config = new DHCP::Config(
    domainname => "reimbold.netz",
    nameserver => "ns.reimbold.netz",
    defaultlease => 600,
    maxlease => 7200);

my $db = new Database(
    host => $DBConfig::DB_HOSTNAME,
    database => $DBConfig::DB_DATABASE,
    user =>$DBConfig::DB_USERNAME,
    password => $DBConfig::DB_PASSWORD);
$db->connect();

my $query = "SELECT * FROM System";
my @system = @{$db->getList($query)};

my %Subnets;

foreach (@system) {
    if ($_->{fixed} == 1) {               # has fixed address ?
        my $mac = $_->{MAC};

        # get IP information
        my $query = sprintf("SELECT * FROM DNS_Record WHERE id='%s'", $_->{record_id});
        my $record = $db->getEntry($query);
        my $name = $record->{name};

        # get domain information
        $query = sprintf("SELECT * FROM Domain WHERE id='%s'", $record->{domain_id});
        my $domain = $db->getEntry($query);
        my $address = sprintf("%s.%s", $record->{name}, $domain->{name});

        # get subnet information
        $query = sprintf("SELECT * FROM DNS_Record WHERE id='%s'", $record->{target_id});
        my $ptr = $db->getEntry($query);
        $query = sprintf("SELECT * FROM Subnet WHERE id='%s'", $ptr->{domain_id});
        my $net = $db->getEntry($query);

        # create if not exists
        my $subnet;
        if (!exists $Subnets{$net->{name}}) {
            $subnet = $config->add(name => $net->{name},
                                   address => $net->{address},
                                   netmask => $net->{mask},
                                   broadcast => $net->{broadcast},
                                   router => $net->{router},
                                   range => $net->{range});
            $Subnets{$net->{name}} = $subnet;
        } else {
            $subnet = $Subnets{$net->{name}};
        }

        # add host
        $subnet->add(name => $name, mac => lc($mac), address => $address);
    }
}

$db->disconnect();

$config->print();

exit;

__END__

#!/usr/bin/perl -w
use strict;

use lib ".";

use Database;
use DBConfig;
use Bind9;

my $config = new Bind9::Config();

my $db = new Database(
    host => $DBConfig::DB_HOSTNAME,
    database => $DBConfig::DB_DATABASE,
    user =>$DBConfig::DB_USERNAME,
    password => $DBConfig::DB_PASSWORD);
$db->connect();

my $query = "SELECT * FROM Domain";
my @domainlist = @{$db->getList($query)};

my %domain;
foreach (@domainlist) {
    my $d = new Database::Domain(db => $db);
    $d->get($_->{id});
    $domain{$d->{ID}} = $config->add(name => $d->{Name}, serial => $d->{Serial});

    my $query = sprintf("SELECT * FROM Subnet WHERE domain_id=%s", $d->{ID});
    my @subnetlist = @{$db->getList($query)};
    foreach my $subnet (@subnetlist) {
        $domain{$d->{ID}}->addSubnet(name => $subnet->{name}, address => $subnet->{address}, mask => $subnet->{mask});
    }

    # increment serial number
    $d->increment();
}

$query = "SELECT * FROM DNS_Record";
my @row = @{$db->getList($query)};

# build hash with record ids
my %name;
foreach my $record (@row) {
    $name{$record->{id}} = $record->{name};
}

# add records to domain
foreach my $record (@row) {
    if ($record->{type} eq 'A') {
        if (exists $name{$record->{target_id}}) {
            my $ip = $name{$record->{target_id}};
            $domain{$record->{domain_id}}->add(name => $record->{name}, ip => $ip, type => "A");
        }
    } elsif ($record->{type} eq 'PTR') {
        if (exists $name{$record->{target_id}}) {
            my $ip = $record->{name};
            my $name = $name{$record->{target_id}};
            $domain{$record->{domain_id}}->add(name => $name, ip => $ip, type => "PTR");
        }
    } elsif ($record->{type} eq 'CNAME') {
        if (exists $name{$record->{target_id}}) {
            my $alias = sprintf("%s.%s", $name{$record->{target_id}}, $domain{$record->{domain_id}}->{Name});
            $domain{$record->{domain_id}}->add(name => $record->{name}, alias => $alias, type => "CNAME");
        }
    } elsif ($record->{type} eq 'NS') {
        if (exists $name{$record->{target_id}}) {
            my $ip = $name{$record->{target_id}};
            $domain{$record->{domain_id}}->add(name => $record->{name}, ip => $ip, type => "NS");
        }
    }
}

$db->disconnect();

$config->print;

exit;
__END__
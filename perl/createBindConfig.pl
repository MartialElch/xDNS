#!/usr/bin/perl -w
use strict;

use lib ".";

use DBI;
use DBConfig;
use Bind9;

my $config = new Bind9::Config();

my @DSN = ("DBI:mysql:database=$DBConfig::DB_DATABASE;host=$DBConfig::DB_HOSTNAME", $DBConfig::DB_USERNAME, $DBConfig::DB_PASSWORD);
my $dbc = DBI->connect(@DSN, { PrintError => 0, AutoCommit => 1, });
die $DBI::errstr unless $dbc;

my $query = "SELECT * FROM Domain";
my $dbh = $dbc->prepare($query);
print $DBI::errstr unless $dbh;
$dbh->execute();
my @domainlist = @{$dbh->fetchall_arrayref({})};

my %domain;
foreach (@domainlist) {
    $domain{$_->{id}} = $config->add(name => $_->{name}, serial => $_->{serial});

    my $query = sprintf("SELECT * FROM Subnet WHERE domain_id=%s", $_->{id});
    my $dbh = $dbc->prepare($query);
    print $DBI::errstr unless $dbh;
    $dbh->execute();
    my @subnetlist = @{$dbh->fetchall_arrayref({})};
    foreach my $subnet (@subnetlist) {
        $domain{$_->{id}}->addSubnet(name => $subnet->{name}, address => $subnet->{address}, mask => $subnet->{mask});
    }
}

$query = "SELECT * FROM DNS_Record";
$dbh = $dbc->prepare($query);
print $DBI::errstr unless $dbh;
$dbh->execute();
my @row = @{$dbh->fetchall_arrayref({})};

# build hash with record ids
my %name;
foreach my $record (@row) {
    $name{$record->{id}} = $record->{name};
}
print "\n";

# add records to domain
foreach (@row) {
    if ($_->{type} eq 'A') {
        if (exists $name{$_->{target_id}}) {
            my $ip = $name{$_->{target_id}};
            $domain{$_->{domain_id}}->add(name => $_->{name}, ip => $ip, type => "A");
        }
    } elsif ($_->{type} eq 'PTR') {
        if (exists $name{$_->{target_id}}) {
            my $ip = $_->{name};
            my $name = $name{$_->{target_id}};
            $domain{$_->{domain_id}}->add(name => $name, ip => $ip, type => "PTR");
        }
    } elsif ($_->{type} eq 'CNAME') {
        if (exists $name{$_->{target_id}}) {
            my $alias = $name{$_->{target_id}};
            $domain{$_->{domain_id}}->add(name => $_->{name}, alias => $alias, type => "CNAME");
        }
    } elsif ($_->{type} eq 'NS') {
        if (exists $name{$_->{target_id}}) {
            my $ip = $name{$_->{target_id}};
            $domain{$_->{domain_id}}->add(name => $_->{name}, ip => $ip, type => "NS");
        }
    }
}

$dbc->disconnect();

$config->print;

exit;
__END__
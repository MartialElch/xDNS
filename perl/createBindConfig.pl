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
foreach my $d (@domainlist) {
    $domain{$d->{id}} = $config->add(name => $d->{name}, serial => $d->{serial});
    my $query = sprintf("SELECT * FROM Subnet WHERE domain_id=%s", $d->{id});
    my $dbh = $dbc->prepare($query);
    print $DBI::errstr unless $dbh;
    $dbh->execute();
    my @subnetlist = @{$dbh->fetchall_arrayref({})};
    foreach my $subnet (@subnetlist) {
        $domain{$d->{id}}->addSubnet(name => $subnet->{name}, address => $subnet->{address}, mask => $subnet->{mask});
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

$dbc->disconnect();

$config->print;

exit;
__END__
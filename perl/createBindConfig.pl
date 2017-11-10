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

my $query = "SELECT * FROM DNS_Record";
my $dbh = $dbc->prepare($query);
print $DBI::errstr unless $dbh;
$dbh->execute();
my @row = @{$dbh->fetchall_arrayref({})};

my $domain = $config->add(name => "reimbold.netz", serial => "14");
my $subnet = $domain->addSubnet(address => "192.168.10.0", mask => "255.255.255.0");

# build hash with record ids
my %name;
foreach (@row) {
    $name{$_->{id}} = $_->{name};
}
print "\n";

# add records to domain
foreach (@row) {
    if ($_->{type} eq 'A') {
        if (exists $name{$_->{target_id}}) {
            my $ip = $name{$_->{target_id}};
            $domain->add(name => $_->{name}, ip => $ip, type => "A");
        }
    } elsif ($_->{type} eq 'PTR') {
        if (exists $name{$_->{target_id}}) {
            my $ip = $_->{name};
            my $name = $name{$_->{target_id}};
            $domain->add(name => $name, ip => $ip, type => "PTR");
        }
    } elsif ($_->{type} eq 'CNAME') {
        if (exists $name{$_->{target_id}}) {
            my $alias = $name{$_->{target_id}};
            $domain->add(name => $_->{name}, alias => $alias, type => "CNAME");
        }
    } elsif ($_->{type} eq 'NS') {
        if (exists $name{$_->{target_id}}) {
            my $ip = $name{$_->{target_id}};
            $domain->add(name => $_->{name}, ip => $ip, type => "NS");
        }
    }
}

$dbc->disconnect();

$config->print;

exit;
__END__
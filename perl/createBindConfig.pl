#!/usr/bin/perl -w
use strict;

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
        my $ip = "";
        if (exists $name{$_->{target_id}}) {
            $ip = $name{$_->{target_id}};
        }
        $domain->add(
            name => $_->{name},
            ip => $ip, 
            type => "A");
    }
}

$dbc->disconnect();

$config->print;

exit;
__END__
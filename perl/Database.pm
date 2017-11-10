#-------------------------------------------------------------------------------
package Database;
use strict;

use DBI;

sub new {
    my $class = shift;
    my %param =@_;

    my $self = {
        Host       => $param{"host"},
        Database   => $param{"database"},
        Username   => $param{"user"},
        Password   => $param{"password"},
        Connection => "",
        Connected  => 0,
    };
    bless $self, $class;

    return $self;
}

sub connect {
    my $self = shift;

    my @DSN = ("DBI:mysql:database=$self->{Database};host=$self->{Host}", 
        $self->{Username}, $self->{Password});

    my $conn = DBI->connect(@DSN, { PrintError => 0, AutoCommit => 1,});
    # error with conection ?
    die $DBI::errstr unless $conn;

    $self->{Connection} = $conn;
    $self->{Connected} = 1;

    return;
}

sub disconnect {
    my $self = shift;

    $self->{Connection}->disconnect();
    $self->{Connected} = 0;

    return;
}

sub getEntry {
    my $self = shift;
    my $query = shift;

    my $conn = $self->{Connection};
    my $h = $conn->prepare($query);
    my $ret = $h->execute();

    my @result = @{$h->fetchall_arrayref({})};
    if (scalar(@result) > 1) {
        die "Database::getEntry - entry not unique";
    }

    return $result[0];
}

sub getList {
    my $self = shift;
    my $query = shift;

    my $conn = $self->{Connection};
    my $h = $conn->prepare($query);
    my $ret = $h->execute();
    my $list = $h->fetchall_arrayref({});

    return $list;
}

sub insert {
    my $self = shift;
    my $query = shift;

    my $conn = $self->{Connection};
    my $h = $conn->prepare($query);
    my $ret = $h->execute();

    return;
}

#-------------------------------------------------------------------------------
1;
__END__
#-------------------------------------------------------------------------------

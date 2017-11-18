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

sub execute {
    my $self = shift;
    my $query = shift;

    my $conn = $self->{Connection};
    my $h = $conn->prepare($query);
    my $ret = $h->execute();

    return $ret;
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
package Database::Domain;

use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name   => "",
	    ID     => 0,
		Serial => 0,
	    DB     => $param{"db"},
	};
	bless $self, $class;

	return $self;
}

sub get {
    my $self = shift;
    my $id = shift;

    my $query = sprintf("SELECT * FROM Domain WHERE id='%s'", $id);
    my $entry = $self->{DB}->getEntry($query);

    $self->{Name} = $entry->{name};
    $self->{ID} = $entry->{id};
    $self->{Serial} = $entry->{serial};

    return;
}

sub increment {
    my $self = shift;

    $self->{Serial}++;
    $self->update();

    return;
}

sub show {
    my $self = shift;

    printf("Name   = %s\n", $self->{Name});
    printf("ID     = %s\n", $self->{ID});
    printf("Serial = %s\n", $self->{Serial});

    return;
}

sub update {
    my $self = shift;

    my $values = sprintf("name='%s', serial='%s'", $self->{Name}, $self->{Serial});
    my $query = sprintf("UPDATE Domain SET %s WHERE id='%d'", $values, $self->{ID});
    $self->{DB}->execute($query);

    return;
}

#-------------------------------------------------------------------------------
1;
__END__
#-------------------------------------------------------------------------------

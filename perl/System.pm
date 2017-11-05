package System;
use strict;

sub new {
    my $class = shift;
    my %param =@_;

    my $self = {
        Database => $param{database},
        id => 0,
        MAC => "",
        Description => "",
        unknown => 0,
    };
    bless $self, $class;

    return $self;
}

sub getByMac {
    my $self = shift;
    my $mac = uc(shift);

    my $db = $self->{Database};
    my $query = sprintf("SELECT * FROM System WHERE MAC='$mac'", $mac);
    my $result = $db->getEntry($query);

    if (defined $result) {
        $self->{id} = $result->{id};
        $self->{MAC} = $result->{MAC};
        $self->{Description} = $result->{description};
        $self->{unknown} = $result->{unknown};
    } else {
        $self->{unknown} = 1;
    }

    return;
}

sub insert {
    my $self = shift;

    my $db = $self->{Database};
    my $query = sprintf("INSERT INTO System (MAC) VALUES ('%s')", uc($self->{MAC}));
    $db->insert($query);

    return;
}

sub show {
    my $self = shift;

    printf("System:\n");
    printf("    id      = %s\n", $self->{id});
    printf("    MAC     = %s\n", $self->{MAC});
    printf("    Desc    = %s\n", $self->{Description});
    printf("    unknown = %s\n", $self->{unknown});

    return;
}

# setter and getter
sub MAC {
    my $self = shift;
    my $input = shift;

    if (defined $input) {
        $self->{MAC} = $input;
    } else {
        return $self->{MAC};
    }

    return;
}
1;
__END__

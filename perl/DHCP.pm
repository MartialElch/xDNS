#-------------------------------------------------------------------------------
package DHCP::RecordHost;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
	    Type => "Host",
	    Name => $param{"name"},
	    MAC => $param{"mac"},
	    Address => $param{"address"},
	};
	bless $self, $class;

	return $self;
}

sub print {
    my $self = shift;

    printf("host %s {\n", $self->{Name});
    printf("    hardware ethernet %s;\n", lc($self->{MAC}));
    printf("    fixed-address %s;\n", $self->{Address});
    printf("}\n");

    return;
}

# setter and getter
sub Type {
    my $self = shift;
    return $self->{Type};
}

#-------------------------------------------------------------------------------
package DHCP::Subnet;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
	    Address => $param{"address"},
	    Netmask => $param{"netmask"},
	    Broadcast => $param{"broadcast"},
	    Router => $param{"router"},
	    Record => \@{[]},
	};
	bless $self, $class;

    if (defined $param{"domainname"}) {
        $self->{DomainName} = $param{"domainname"};
    }
    if (defined $param{"nameserver"}) {
        $self->{NameServer} = $param{"nameserver"};
    }
    if (defined $param{"defaultlease"}) {
        $self->{DefaultLeaseTime} = $param{"defaultlease"};
    }
    if (defined $param{"maxlease"}) {
        $self->{MaxLeaseTime} = $param{"maxlease"};
    }
    if (defined $param{"range"}) {
        $self->{Range} = $param{"range"};
    }

	return $self;
}

sub add {
    my $self = shift;
	my %param = @_;

    my $record = new DHCP::RecordHost(
        name => $param{"name"},
        mac => $param{"mac"},
        address => $param{"address"});
	push @{$self->{Record}}, $record;

    return;
}

sub print {
    my $self = shift;

    printf("subnet %s netmask %s {\n", $self->{Address}, $self->{Netmask});
    if (defined $self->{Range}) {
        printf("    range %s;\n", $self->{Range});
    }
    printf("    option broadcast-address %s;\n", $self->{Broadcast});
    printf("    option routers %s;\n", $self->{Router});
    if (defined $self->{DomainName}) {
        printf("   option domain-name %s;\n", $self->{DomainName});
    }
    printf("}\n");
    printf("\n");

    # print Host records
    foreach (@{$self->{Record}}) {
        if ($_->Type() eq "Host") {
            $_->print();
        }
        printf("\n");
    }

    return;
}

#-------------------------------------------------------------------------------
package DHCP::Config;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
	    DomainName => $param{"domainname"},
	    NameServer => $param{"nameserver"},
	    DefaultLeaseTime => 600,
	    MaxLeaseTime => 7200,
	    DDNSUpdateStyle => "none",
	    Subnet => \@{[]},
	};
	bless $self, $class;

    if (defined $param{"defaultlease"}) {
        $self->{DefaultLeaseTime} = $param{"defaultlease"};
    }
    if (defined $param{"maxlease"}) {
        $self->{MaxLeaseTime} = $param{"maxlease"};
    }
    if (defined $param{"ddns"}) {
        $self->{DDNSUpdateStyle} = $param{"ddns"};
    }
    
	return $self;
}

sub add {
    my $self = shift;
	my %param = @_;

    my $subnet = new DHCP::Subnet(
        name => $param{"name"},
        address => $param{"address"},
        netmask => $param{"netmask"},
        broadcast => $param{"broadcast"},
        router => $param{"router"},
        range => $param{"range"});
	push @{$self->{Subnet}}, $subnet;

    return $subnet;
}

sub print {
    my $self = shift;

    printf("ddns-update-style %s;\n", $self->{DDNSUpdateStyle});
    printf("\n");
    printf("option domain-name \"%s\";\n", $self->{DomainName});
    printf("option domain-name-servers %s;\n", $self->{NameServer});
    printf("default-lease-time %d;\n", $self->{DefaultLeaseTime});
    printf("max-lease-time %d;\n", $self->{MaxLeaseTime});
    printf("\n");
    # print some defaults
    printf("log-facility local7;\n");
    printf("\n");

    foreach (@{$self->{Subnet}}) {
        $_->print();
    }

    return;
}

#-------------------------------------------------------------------------------
1;
__END__
#-------------------------------------------------------------------------------

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

sub sprint {
    my $self = shift;

    my $text;

    $text .= sprintf("host %s {\n", $self->{Name});
    $text .= sprintf("    hardware ethernet %s;\n", lc($self->{MAC}));
    $text .= sprintf("    fixed-address %s;\n", $self->{Address});
    $text .= sprintf("}\n");

    return $text;
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

sub sprint {
    my $self = shift;

    my $text;

    $text .= sprintf("subnet %s netmask %s {\n", $self->{Address}, $self->{Netmask});
    if (defined $self->{Range}) {
        $text .= sprintf("    range %s;\n", $self->{Range});
    }
    $text .= sprintf("    option broadcast-address %s;\n", $self->{Broadcast});
    $text .= sprintf("    option routers %s;\n", $self->{Router});
    if (defined $self->{DomainName}) {
        $text .= sprintf("   option domain-name %s;\n", $self->{DomainName});
    }
    $text .= sprintf("}\n");
    $text .= sprintf("\n");

    # print Host records
    foreach (@{$self->{Record}}) {
        if ($_->Type() eq "Host") {
            $text .= $_->sprint();
        }
        $text .= sprintf("\n");
    }

    return $text;
}

#-------------------------------------------------------------------------------
package DHCP::Config;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
	    Filename => "dhcpd.conf",
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

    use IO::File;

    my $text;

    $text .= sprintf("ddns-update-style %s;\n", $self->{DDNSUpdateStyle});
    $text .= sprintf("\n");
    $text .= sprintf("option domain-name \"%s\";\n", $self->{DomainName});
    $text .= sprintf("option domain-name-servers %s;\n", $self->{NameServer});
    $text .= sprintf("default-lease-time %d;\n", $self->{DefaultLeaseTime});
    $text .= sprintf("max-lease-time %d;\n", $self->{MaxLeaseTime});
    $text .= sprintf("\n");

    # print some defaults
    $text .= sprintf("log-facility local7;\n");
    $text .= sprintf("\n");

    foreach (@{$self->{Subnet}}) {
        $text .= $_->sprint();
    }
        
    my $file = new IO::File($self->{Filename}, 'w');
    print $file $text;
    $file->close;

    return;
}

#-------------------------------------------------------------------------------
1;
__END__
#-------------------------------------------------------------------------------

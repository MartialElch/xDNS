#-------------------------------------------------------------------------------
package Bind9::Record;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name => $param{"name"},
	};
	bless $self, $class;

	return $self;
}

#-------------------------------------------------------------------------------
package Bind9::RecordA;
use strict;

use base qw(Bind9::Record);

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name      => $param{"name"},
		IpAddress => $param{"ip"},
		Type      => "A",
	};
	bless $self, $class;

	return $self;
}

sub sprint {
    my $self = shift;

    return sprintf("%-17s IN     A       %-s\n", $self->{Name}, $self->{IpAddress});
}

#-------------------------------------------------------------------------------
package Bind9::RecordCNAME;
use strict;

use base qw(Bind9::Record);

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name  => $param{"name"},
		Alias => $param{"alias"},
		Type  => "CNAME",
	};
	bless $self, $class;

	return $self;
}

sub sprint {
    my $self = shift;

    return sprintf("%-17s IN     CNAME   %-s.\n", $self->{Name}, $self->{Alias});
}

#-------------------------------------------------------------------------------
package Bind9::RecordNS;
use strict;

use base qw(Bind9::RecordA);

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name      => $param{"name"},
		IpAddress => $param{"ip"},
		Subnet    => $param{"subnet"},
		Type      => "NS",
	};
	bless $self, $class;

	return $self;
}

#-------------------------------------------------------------------------------
package Bind9::RecordPTR;
use strict;

use base qw(Bind9::Record);

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name      => $param{"name"},
		IpAddress => $param{"ip"},
		Type      => "PTR",
		Netmask   => $param{"netmask"},
	};
	bless $self, $class;

	return $self;
}

sub getHostPart {
    my $self = shift;

	my $ip = $self->{IpAddress};
	my $mask = $self->{Netmask};

	$ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
	$ip = hex(sprintf("0x%02x%02x%02x%02x", $1, $2, $3, $4));
	$mask =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
	$mask = hex(sprintf("0x%02x%02x%02x%02x", $1, $2, $3, $4));

	return $ip & (~$mask);
}

sub sprint {
    my $self = shift;

    my $fullname = $self->{Name}.".";
    return sprintf("%-7s IN      PTR     %-s\n", $self->getHostPart, $fullname);
}

#-------------------------------------------------------------------------------
package Bind9::Zone;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
	    Name     => $param{name},
	    Filename => "db.".$param{name},
        Domain   => $param{domain},
		Serial   => "0",
		Refresh  => "604800",
		Retry    => "86400",
		Expire   => "2419200",
		Cache    => "604800",
		TTL      => "604800",
	    Record   => \@{[]},
	};
	bless $self, $class;

	return $self;
}

sub add {
        my $self = shift;
        my $record = shift;

        push @{$self->{Record}}, $record;

        return;
}

sub getRecordsA {
    my $self = shift;

	my @list;
    foreach (@{$self->{Record}}) {
		if ($_->{Type} eq "A") {
			push @list, $_;
		}
    }

	return \@list;	
}

sub getRecordsCNAME {
    my $self = shift;

	my @list;
    foreach (@{$self->{Record}}) {
		if ($_->{Type} eq "CNAME") {
	    	push @list, $_;
		}
    }

	return \@list;	
}

sub getRecordsNS {
    my $self = shift;

	my @list;
    foreach (@{$self->{Record}}) {
		if ($_->{Type} eq "NS") {
	    	push @list, $_;
		}
    }

	return \@list;	
}

sub getRecordsPTR {
    my $self = shift;

	my @list;
	my %record;
    foreach (@{$self->{Record}}) {
		if ($_->{Type} eq "PTR") {
			# put records in hash to sort by host part of IpAddress
	        $record{$_->getHostPart} = $_;
		}
    }

	foreach (sort {$a<=>$b} keys %record) {
		push @list, $record{$_};
	}

	return \@list;	
}

sub print {
    my $self = shift;
    my $text = shift;

    use IO::File;
        
    my $file = new IO::File($self->{Filename}, 'w');
    print $file $text;
    $file->close;

    return;
}

sub sprintHeader {
    my $self = shift;

    my $text;
	my $ns = @{$self->getRecordsNS()}[0];

	# print header
    $text .= sprintf("\$TTL    %-d\n", $self->{TTL});
    $text .= sprintf("@       IN      SOA     %s.%s. admin.%s. (\n", $ns->{Name}, $self->{Domain}, $self->{Domain});
    $text .= sprintf("                       %8d         ; Serial\n", $self->{Serial});
    $text .= sprintf("                       %8d         ; Refresh\n", $self->{Refresh});
    $text .= sprintf("                       %8d         ; Retry\n", $self->{Retry});
    $text .= sprintf("                       %8d         ; Expire\n", $self->{Expire});
    $text .= sprintf("                       %8d )       ; Negative Cache TTL\n", $self->{Cache});

	# print nameserver records
    $text .= sprintf("\n");
    $text .= sprintf("; name servers - NS records\n");
	foreach (@{$self->getRecordsNS()}) {
		my $fullname = $_->{Name}.".".$self->{Domain}.".";
	    $text .= sprintf("@                 IN      NS      %s\n", $fullname);
    }
    $text .= sprintf("\n");

	return $text;	
}

# setter and getter
sub Serial {
    my $self = shift;
    my $input = shift;
        
    if (defined $input) {
    	$self->{Serial} = $input;
        return;
    }
    return $self->{Serial};
}

#-------------------------------------------------------------------------------
package Bind9::Zone::Forward;
use strict;

use base qw(Bind9::Zone);

sub print {
    my $self = shift;

    my $text = $self->sprintHeader();
    $text .= sprintf("; name servers - A records\n");
	foreach (@{$self->getRecordsNS()}) {
	    $text .= $_->sprint();
	}
    $text .= sprintf("\n");

	# print CNAME records
    $text .= sprintf("; alias names\n");
	foreach (@{$self->getRecordsCNAME()}) {
	    $text .= $_->sprint();
	}
    $text .= sprintf("\n");

	# print A records
	my $subnet = ${$self->getRecordsNS()}[0]->{Subnet}->{Address};
    $text .= sprintf("; %s - A records\n", $subnet);
	foreach (@{$self->getRecordsA()}) {
	    $text .= $_->sprint();
	}

    print $text;
    $self->SUPER::print($text);

    return;
}

#-------------------------------------------------------------------------------
package Bind9::Zone::Reverse;
use strict;

use base qw(Bind9::Zone);

sub print {
    my $self = shift;

    my $text = $self->sprintHeader();

	# print PTR records
	foreach (@{$self->getRecordsPTR()}) {
	    $text .= $_->sprint();
	}

    print $text;
    $self->SUPER::print($text);

    return;
}

#-------------------------------------------------------------------------------
package Bind9::Subnet;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name    => $param{"name"},
		Address => $param{"address"},
		Mask    => $param{"mask"},
	    Record  => \@{[]},
	};
	bless $self, $class;

	return $self;
}

# setter and getter
sub Zone {
    my $self = shift;
    my $input = shift;
        
    if (defined $input) {
    	$self->{Zone} = $input;
        return;
    }
    return $self->{Zone};
}

#-------------------------------------------------------------------------------
package Bind9::Domain;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Name    => $param{"name"},
	    Record  => \@{[]},
		Serial  => $param{"serial"},
	    Subnet  => \@{[]},
	    Zone   => \@{[]},
	};
	bless $self, $class;

    my $zone = new Bind9::Zone::Forward(name => $param{"name"}, domain => $self->{Name});
	push @{$self->{Zone}}, $zone;

	return $self;
}

sub add {
    my $self = shift;
	my %param = @_;

    my $record;

    if ($param{"type"} eq "A") {
    	$record = new Bind9::RecordA(name => $param{"name"},
                                     ip   => $param{"ip"});
        @{$self->{Zone}}[0]->add($record);
    } elsif ($param{"type"} eq "PTR") {
        my $subnet = $self->getSubnet($param{"ip"});
        my $zone = $subnet->Zone();
        $record = new Bind9::RecordPTR(ip      => $param{"ip"},
                                       name    => $param{"name"}.".".$self->{Name},
                                       netmask => $subnet->{Mask});
       	$zone->add($record);
    } elsif ($param{"type"} eq "CNAME") {
        $record = new Bind9::RecordCNAME(name  => $param{"name"},
                                         alias => $param{"alias"});
        @{$self->{Zone}}[0]->add($record);
    } elsif ($param{"type"} eq "NS") {
        my $subnet = $self->getSubnet($param{"ip"});
        my $zone = $subnet->Zone();
        $record = new Bind9::RecordNS(name   => $param{"name"},
                                      ip     => $param{"ip"},
                                      subnet => $subnet);
        @{$self->{Zone}}[0]->add($record);
        $zone->add($record);
    }
    return;
}

sub addSubnet {
    my $self = shift;
	my %param = @_;

	my $subnet = new Bind9::Subnet(name    => $param{"name"},
	                               address => $param{"address"},
	                               mask    => $param{"mask"});
	push @{$self->{Subnet}}, $subnet;

    my $zone = new Bind9::Zone::Reverse(name => $param{"name"}, domain => $self->{Name});
	push @{$self->{Zone}}, $zone;
    $subnet->Zone($zone);

    return $subnet;
}

sub getSubnet {
    my $self = shift;
	my $ip = shift;

    foreach (@{$self->{Subnet}}) {
		$ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
	    my $hex = hex(sprintf("%02x%02x%02x%02x", $1, $2, $3, $4));

	    my $mask = $_->{Mask};
	    $mask =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
	    $mask = hex(sprintf("%02x%02x%02x%02x", $1, $2, $3, $4));

	    my $subnet = $_->{Address};
	    $subnet =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
	    $subnet = hex(sprintf("%02x%02x%02x%02x", $1, $2, $3, $4));

        my $net = $hex & $mask;
	    if ($subnet == $net) {
	    	return $_;
	    }
    }
	return;	
}

sub print {
    my $self = shift;
        
    foreach (@{$self->{Zone}}) {
    	$_->Serial($self->{Serial});
        $_->print();
    }
    return;
}

#-------------------------------------------------------------------------------
package Bind9::Config;
use strict;

sub new {
	my $class = shift;
	my $self = {
	    Domain => \@{[]},
	};
	bless $self, $class;

	return $self;
}

sub add {
    my $self = shift;
	my %param = @_;

    my $name = $param{"name"};
    my $serial = $param{"serial"};
    my $domain = new Bind9::Domain(name => $name, serial => $serial);

	push @{$self->{Domain}}, $domain;

    return $domain;
}

sub print {
        my $self = shift;

        foreach (@{$self->{Domain}}) {
                $_->print();
        }

        return;
}

#-------------------------------------------------------------------------------
1;
__END__
#-------------------------------------------------------------------------------

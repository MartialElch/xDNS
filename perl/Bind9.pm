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

sub print {
        my $self = shift;
        return;
}

sub show {
        my $self = shift;

        printf("Name = %s\n", $self->{Name});

        return;
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

sub print {
        my $self = shift;

        my $fullname = $self->{Name}.".";
        printf("%-32s IN     A       %-s\n", $fullname, $self->{IpAddress});

        return;
}

sub show {
        my $self = shift;

        my $fullname = $self->{Name}.".";
        printf("%-32s IN     A       %-32s\n", $fullname, $self->{IpAddress});

        return;
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

sub print {
        my $self = shift;

        my $fullname = $self->{Name}.".";
        printf("%-32s IN     CNAME   %-s\n", $fullname, $self->{Alias});

        return;
}

sub show {
        my $self = shift;

        my $fullname = $self->{Name}.".";
        printf("%-32s IN     CNAME   %-32s\n", $fullname, $self->{Alias});

        return;
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

sub print {
        my $self = shift;

        my $fullname = $self->{Name}.".";
        printf("%-7s IN      PTR     %-s\n", $self->getHostPart, $fullname);

        return;
}

sub show {
        my $self = shift;

        my $fullname = $self->{Name}.".";
        printf("%-32s IN     PTR     %-32s\n", $self->{IpAddress}, $fullname);

        return;
}

#-------------------------------------------------------------------------------
package Bind9::Subnet;
use strict;

sub new {
	my $class = shift;
	my %param = @_;

	my $self = {
		Address => $param{"address"},
		Mask    => $param{"mask"},
	};
	bless $self, $class;

	return $self;
}

sub show {
	my $self = shift;
	
	printf("Subnet Address = %s\n", $self->{Address});
	printf("Subnet Mask    = %s\n", $self->{Mask});
	return;
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
		Refresh => "604800",
		Retry   => "86400",
		Expire  => "2419200",
		Cache   => "604800",
		TTL     => "604800",
	        Subnet  => \@{[]},
	};
	bless $self, $class;

	return $self;
}

sub add {
        my $self = shift;
	my %param = @_;

        my $record;

        if ($param{"type"} eq "A") {
                $record = new Bind9::RecordA(name => $param{"name"}.".".$self->{Name},
                                             ip => $param{"ip"});
        } elsif ($param{"type"} eq "PTR") {
                $record = new Bind9::RecordPTR(ip => $param{"ip"},
                                               name => $param{"name"}.".".$self->{Name},
                                               netmask => $self->getSubnet($param{"ip"})->{Mask});
        } elsif ($param{"type"} eq "CNAME") {
                $record = new Bind9::RecordCNAME(name => $param{"name"}.".".$self->{Name},
                                                 alias => $param{"alias"});
        } elsif ($param{"type"} eq "NS") {
                $record = new Bind9::RecordNS(name => $param{"name"}.".".$self->{Name},
                                              ip => $param{"ip"});
        }

	push @{$self->{Record}}, $record;

        return;
}

sub addSubnet {
        my $self = shift;
	my %param = @_;

	my $subnet = new Bind9::Subnet(address => $param{"address"},
	                               mask    => $param{"mask"});
	push @{$self->{Subnet}}, $subnet;

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

sub printHeader {
        my $self = shift;

	my $ns = @{$self->getRecordsNS()}[0];

	# print header
        printf("\$TTL    %-8d\n", $self->{TTL});
        printf("@       IN      SOA     %s. admin.%s. (\n", $ns->{Name}, $self->{Name});
        printf("                       %8d         ; Serial\n", $self->{Serial});
        printf("                       %8d         ; Refresh\n", $self->{Refresh});
        printf("                       %8d         ; Retry\n", $self->{Retry});
        printf("                       %8d         ; Expire\n", $self->{Expire});
        printf("                       %8d )       ; Negative Cache TTL\n", $self->{Cache});

	# print nameserver records
        printf("\n");
        printf("; name servers - NS records\n");
	foreach (@{$self->getRecordsNS()}) {
		my $fullname = $_->{Name}.".";
	        printf("        IN      NS      %s\n", $fullname);
        }
        printf("\n");
	return;	
}

sub printForwardZone {
        my $self = shift;

	$self->printHeader();

        printf("; name servers - A records\n");
	foreach (@{$self->getRecordsNS()}) {
	        $_->print();
	}
        printf("\n");

	# print CNAME records
        printf("; alias names\n");
	foreach (@{$self->getRecordsCNAME()}) {
	        $_->print();
	}
        printf("\n");

	# print A records
        printf("; - A records\n");
	foreach (@{$self->getRecordsA()}) {
	        $_->print();
	}

        return;
}

sub printReverseZone {
        my $self = shift;

	$self->printHeader();

	# print PTR records
	foreach (@{$self->getRecordsPTR()}) {
	        $_->print();
	}

        return;
}

sub show {
        my $self = shift;
        
        printf("Domain: %s\n", $self->{Name});
        foreach (@{$self->{Record}}) {
                $_->show;
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
                $_->printForwardZone();
                # $_->printReverseZone();
        }

        return;
}

sub show {
        my $self = shift;

        foreach (@{$self->{Domain}}) {
                $_->show;
        }

        return;
}

#-------------------------------------------------------------------------------
1;
__END__
#-------------------------------------------------------------------------------

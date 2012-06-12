package Smokeping::probes::SqlLatency;

=head1 301 Moved Permanently

This is a Smokeping probe module. Please use the command.

C<smokeping -man Smokeping::probes::SqlLatency>

to view the documentation or the command

C<smokeping -makepod Smokeping::probes::SqlLatency>

to generate the POD document.

=cut

use strict;
use base qw(Smokeping::probes::basefork);
use Time::HiRes qw(gettimeofday tv_interval);
use DBI;

sub pod_hash {
		return {
				name => <<DOC,
Smokeping::probes::SqlLatency - MySQL latency probe for SmokePing
DOC
				description => <<DOC,
Integrates MySQL latency into smokeping. The variables B<host>
B<user> and B<password> must be specified in order for the probe
to work. Requires perl-DBI.

The Probe asks the given host for status and computes query time.
DOC
                authors => <<'DOC',
 Alex Negulescu <alecs@altlinux.org>
DOC
        };
}

sub new($$$) {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    return $self;
}

sub ProbeDesc($){
    my $self = shift;
    return "SQL Connections";
}

sub pingone ($) {
		my $self   = shift;
		my $target = shift;
		my $host = $target->{addr};
		my $port = $target->{vars}{port};
		my $username = $target->{vars}{username};
		my $password = $target->{vars}{password};
		my ($key,$val,$starttime,$values,$nbytes);
		my @times;
		for ( my $run = 0 ; $run < $self->pings($target) ; $run++ ) {
		$starttime = [gettimeofday()];
		my $dbc = DBI->connect("dbi:mysql:mysql:$host:$port", "$username", "$password")
			or $self->do_debug("Can't connect to the DB: $DBI::errstr");
		my $test = $dbc->prepare("SHOW STATUS;")
			or $self->do_debug("Connected, but can't query DB: $DBI::errstr");
		$test->execute();
		while(($key, $val) = $test->fetchrow_array()) {
			$values .= $val;
		}
		$nbytes = length($values);
		if (not defined $nbytes or $nbytes <= 0) {
			$self->do_debug("Read nothing or some kind of error!");
		}
		$dbc->disconnect or $self->do_debug("Error $DBI::errstr;");
		push @times, tv_interval($starttime);
		}
		@times =  map {sprintf "%.10e", $_ } sort {$a <=> $b} @times;
		return @times;
}

sub probevars {
		my $class = shift;
		my $h = $class->SUPER::probevars;
		delete $h->{timeout};
		return $h;
}

sub targetvars {
        my $class = shift;
        return $class->_makevars($class->SUPER::targetvars, {
                username => { _doc => "Username to connect with.",
                            _example => "mysqluser",
                },
                password => { _doc => "Username's password.",
                              _example => "mysqlpass",
                },
                port => { _doc => "Remote MySQL port.",
                          _default => 3306,
                          _example => "3306",
                },
        });
}

1;

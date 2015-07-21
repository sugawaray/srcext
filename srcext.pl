use strict;

use Getopt::Std;

our($opt_d, $opt_a);

sub getconf {
	my ($a) = @_;
	undef $opt_d;
	undef $opt_a;
	@ARGV = @{$a};
	getopts('d:a:');
	my @sl = @ARGV;
	my %r = ( 'dest' => $opt_d, 'absdest' => $opt_a, 'srclist' => \@sl );
	return \%r;
};

1;

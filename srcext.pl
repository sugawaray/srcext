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
}

sub normpath {
	my ($a) = @_;
	my (@l, @m, $i, $r);
	@l = split /\//, $a;
	for ($i = 0; $i < @l; ++$i) {
		if ($l[$i] eq '.') {
			;
		} elsif ($l[$i] eq '..' && @m > 0 && $m[@m - 1] eq '..') {
			push @m, ($l[$i]);
		} elsif ($l[$i] eq '..' && @m > 0) {
			pop @m;
		} else {
			push @m, ($l[$i]);
		}
	}
	$r = @m > 0 ? $m[0] : '';
	for ($i = 1; $i < @m; ++$i) {
		$r .= '/' . $m[$i];
	}
	if ($r eq '') {
		$r = '.';
	}
	return $r;
}

sub genkey {
	my ($d, $name) = @_;
	$name =~ s/"//g;
	return $d . '/' . $name;
}

sub collect_recur {
	my ($a, $b, $c, $d) = @_;
	$c->{$a} = 1;
}

1;

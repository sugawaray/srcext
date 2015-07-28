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
	return &normpath($d . '/' . $name);
}

sub collect {
	my ($file, $list) = @_;
	my $in;
	open($in, '<', $file);
	while (<$in>) {
		chomp;
		if (/^#include\s+/) {
			s/^#include ("[^"]+"|<[^>]+>).*/$1/;
			push @$list, ($_);
		}
	}
	close($in);
};

sub collect_recur {
	my ($path, $basedir, $deps, $absdeps) = @_;
	my @v = ();
	my $file = &genkey($basedir, $path);
	&collect($file, \@v);
	$deps->{$file} = \@v;
	my $i;
	for ($i = 0; $i < @v; ++$i) {
		&collect_recur($v[$i], $basedir, $deps, $absdeps);
	}
}

1;

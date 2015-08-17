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
	if ($a eq '/') {
		return $a;
	}
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

sub dirname {
	my ($a) = @_;
	if ($a eq '/') {
		return $a;
	}
	$a =~ s#/[^/]*$##;
	return &normpath($a);
}

sub isabs {
	my ($a) = @_;
	return $a =~ /<[^>]+>/;
}

sub genkey {
	my ($d, $name) = @_;
	if (&isabs($name)) {
		$name =~ s/<([^>]+)>/$1/;
	} else {
		$name =~ s/"//g;
	}
	return &normpath($d . '/' . $name);
}

sub collect {
	my ($file, $list) = @_;
	my $in;
	open($in, '<', $file) or return 1;
	while (<$in>) {
		chomp;
		if (/^#include\s+/) {
			s/^#include ("[^"]+"|<[^>]+>).*/$1/;
			push @$list, ($_);
		}
	}
	close($in);
	return 0;
};

sub collect_recur {
	my ($path, $basedir, $deps, $absbase, $absdeps) = @_;
	my @v = ();
	my $file;
	if (!&isabs($path)) {
		$file = &genkey($basedir, $path);
	} else {
		$file = &genkey($absbase, $path);
	}
	&collect($file, \@v);
	if (!&isabs($path)) {
		$deps->{$file} = \@v;
	} else {
		$absdeps->{$file} = \@v;
	}
	my $i;
	for ($i = 0; $i < @v; ++$i) {
		my $t = &dirname($file);
		&collect_recur($v[$i], $t, $deps, $absbase, $absdeps);
	}
}

1;

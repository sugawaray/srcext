#! /usr/bin/perl -W

use strict;

my $rpath = '("[^"]+"|<[^>]+>)';
my $rinclude = '^#include\s+' . $rpath;

use Cwd 'abs_path', 'getcwd';

sub collect {
	my ($file, $deps) = @_;
	my @d = ();
	my $abspath = &abs_path($file);
	$deps->{$abspath} = \@d;
	my $in;
	open($in, '<', $file)
		or die "can not open an input file(" . $file .")";
	while (<$in>) {
		chomp;
		if (/$rinclude/) {
			s/$rinclude.*/$1/;
			s/"//g;
			s/<//g;
			s/>//g;
			push @d, $_;
		}
	}
	close $in or die "can not close the input file.";
};

sub collectall {
	my ($file, $deps) = @_;
	&collect($file, $deps);
	my $deplist = %{$deps}{&abs_path($file)};
	my $origcwd = &getcwd();
	if ($file =~ /\/[^\/]*$/) {
		my $path = $file;
		$path =~ s#/[^/]*$#/#;
		chdir $path;
	}
	for (my $i = 0; $i < scalar @{$deplist}; ++$i) {
		&collectall(@{$deplist}[$i], $deps);
	}
	chdir $origcwd;
};

my %dependencies = ();
&collectall($ARGV[0], \%dependencies);

for my $file (keys %dependencies) {
	printf "%s:", $file;
	my $d = $dependencies{$file};
	for (my $i = 0; $i < scalar @{$d} - 1; ++$i) {
		printf "%s, ", @{$d}[$i];
	}
	if (scalar @{$d} != 0) {
		printf "%s", @{$d}[scalar @{$d} - 1];
	}
	printf "\n";
}
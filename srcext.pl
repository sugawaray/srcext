#! /usr/bin/perl -W

use strict;

my $rpath = '("[^"]+"|<[^>]+>)';
my $rinclude = '^#include\s+' . $rpath;

use Cwd 'abs_path', 'getcwd';

# This subroutine collects files which the 1st argument file includes
# and inserts them into the 2nd argument hash.
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

# This subroutine collects files which the 1st argument file includes.
# And It also collects files which files included by the 1st argument file
# include, recursively. It inserts all collected files into the 2nd argument
# hash.
sub collect_recur {
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
		&collect_recur(@{$deplist}[$i], $deps);
	}
	chdir $origcwd;
};

# The key is an absolute path of a file.
# The value is a list of files which the file of the key includes.
my %dependencies = ();
&collect_recur($ARGV[0], \%dependencies);

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

#! /usr/bin/perl -W

use strict;
require "srcext.pl";

# The key is an absolute path of a file.
# The value is a list of files which the file of the key includes.
my %dependencies = ();
my %absdeps = ();
&collect_recur('"' . $ARGV[2] . '"', &getdir($ARGV[2]), \%dependencies,
	\%absdeps);

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

for my $f (keys %dependencies) {
	&copyfile($f);
}

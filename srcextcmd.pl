#! /usr/bin/perl -W

use strict;
require "srcext.pl";

my $DESTDIR = 1;
my $ABSDESTDIR = 3;
my $SRC = 4;

# The key is an absolute path of a file.
# The value is a list of files which the file of the key includes.
my %dependencies = ();
my %absdeps = ();
&collect_recur('"' . $ARGV[$SRC] . '"', &getdir($ARGV[$SRC]), \%dependencies,
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

sub copyfile {
	my ($f, $destdir) = @_;
	my $d = &cleanpath($destdir . '/' . &getdir($ARGV[$SRC]) .
		'/' . $f);
	my $dd = &cleanpath(&getdir($d));
	if (index($dd, '/') >= 0) {
		my $t = substr($dd, 0, (index $dd, "/"));
		&create_dirtree($t, $dd);
	}
	copy($f, $d);
};

for my $f (keys %dependencies) {
	&copyfile($f, $ARGV[$DESTDIR]);
}
for my $f (keys %absdeps) {
	&copyfile($f, $ARGV[$ABSDESTDIR]);
}

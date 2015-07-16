#! /usr/bin/perl -W

use strict;
require "srcext.pl";

my %deps = ();
my %absdeps = ();
&collect_recur('"./inputs/simple.c"', ".", \%deps, \%absdeps);
scalar keys(%deps) == 2 or printf("%d\n", scalar keys(%deps)) && die "count1";
scalar keys(%absdeps) == 2 or printf("%d\n", scalar keys(%absdeps)) &&
	die "count2";

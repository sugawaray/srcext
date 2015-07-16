#! /usr/bin/perl -W

use strict;

my @incpath = ( 'incdir1', 'incdir2' );
scalar @incpath == 2 or die 'incpath1';
$incpath[1] eq 'incdir2' or die 'incpath2';

my $rpath = '("[^"]+"|<[^>]+>)';
my $rinclude = '^#include\s+' . $rpath;

sub isabs {
	my ($s) = @_;
	$s = substr $s, 0, 1;
	if ($s eq '<') {
		return 1;
	} else {
		return 0;
	}
};

sub rmparen {
	my ($s) = @_;
	return substr $s, 1, length($s) - 2;
};

!&isabs("\"file1\"") or die "isabs1";
&isabs("<file1>") or die "isabs2";

# This subroutine collects files which the 1st argument file includes
# and inserts them into the 2nd argument hash.
sub collect {
	my ($file, $deps) = @_;
	my @d = ();
	$deps->{$file} = \@d;
	my $in;
	open($in, '<', $file) or return 1;
	while (<$in>) {
		chomp;
		if (/$rinclude/) {
			s/$rinclude.*/$1/;
			push @d, $_;
		}
	}
	close $in or die "can not close the input file.";
	return 0;
};

sub getdir {
	my ($s) = @_;
	if ($s =~ /\//) {
		$s =~ s#/[^/]*$##;
	} else {
		$s = '.';
	}
	return $s;
}

(&getdir('./dir/file1') cmp './dir') == 0 or die 'getdir1';
(&getdir('dir') cmp '.') == 0 or die 'getdir2';

# This subroutine collects files which the 1st argument file includes.
# And It also collects files which files included by the 1st argument file
# include, recursively. It inserts all collected files into the 2nd argument
# hash.
sub collect_recur {
	my ($file, $deps, $dir) = @_;
	my $abs = &isabs($file);
	$file = &rmparen($file);
	if ($abs) {
		my $tmp;
		for (my $i = 0; $i < scalar @incpath; ++$i) {
			$tmp = $incpath[$i] . '/' . $file;
			if (&collect($tmp, $deps) == 0) {
				last;
			}
		}
		$file = $tmp;
	} else {
		$file = $dir . '/' . $file;
		&collect($file, $deps);
	}
	my $deplist = %{$deps}{$file};
	for (my $i = 0; $i < scalar @{$deplist}; ++$i) {
		&collect_recur(@{$deplist}[$i], $deps, &getdir($file));
	}
};

# The key is an absolute path of a file.
# The value is a list of files which the file of the key includes.
my %dependencies = ();
&collect_recur('"' . $ARGV[2] . '"', \%dependencies, &getdir($ARGV[2]));

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

use File::Copy;

sub create_dirtree {
	my ($dir, $maxtree) = @_;
	mkdir($dir);
	my $p = index($maxtree, '/', length($dir) + 1);
	if ($p >= 0) {
		$dir = substr($maxtree, 0, $p);
		&create_dirtree($dir, $maxtree);
	} else {
		mkdir($maxtree);
	}
};

sub cleanpath {
	my ($s) = @_;
	$s =~ s#/(\./)+#/#g;
	return $s;
};

&cleanpath("./././dir1") eq './dir1' or die 'cleanpath1';

sub copyfile {
	my ($f) = @_;
	my $d = &cleanpath($ARGV[1] . '/' . &getdir($ARGV[2]) . '/' . $f);
	my $dd = &cleanpath(&getdir($d));
	if (index($dd, '/') >= 0) {
		my $t = substr($dd, 0, (index $dd, "/"));
		&create_dirtree($t, $dd);
	}
	copy($f, $d);
};

for my $f (keys %dependencies) {
	&copyfile($f);
}

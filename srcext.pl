#! /usr/bin/perl -W

use strict;

my @incpath = ( 'incdir1', 'incdir2' );
scalar @incpath == 2 or die 'incpath1';
$incpath[1] eq 'incdir2' or die 'incpath2';

my $rpath = '("[^"]+"|<[^>]+>)';
my $rinclude = '^#include\s+' . $rpath;

use Cwd 'abs_path', 'getcwd';

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
	if (!defined $file) {
		return 1;
	}
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

# This subroutine collects files which the 1st argument file includes.
# And It also collects files which files included by the 1st argument file
# include, recursively. It inserts all collected files into the 2nd argument
# hash.
sub collect_recur {
	my ($file, $deps) = @_;
	my $origcwd = &getcwd();
	my $abs = &isabs($file);
	$file = &rmparen($file);
	if ($abs) {
		for (my $i = 0; $i < scalar @incpath; ++$i) {
			chdir $incpath[$i];
			if (&collect(&abs_path($file), $deps) == 0) {
				last;
			}
			chdir $origcwd;
		}
	} elsif ($file =~ /\/[^\/]*$/) {
		my $path = $file;
		$path =~ s#/[^/]*$#/#;
		$file = substr $file, length($path);
		chdir $path;
		&collect(&abs_path($file), $deps);
	} else {
		&collect(&abs_path($file), $deps);
	}
	my $deplist = %{$deps}{&abs_path($file)};
	for (my $i = 0; $i < scalar @{$deplist}; ++$i) {
		&collect_recur(@{$deplist}[$i], $deps);
	}
	chdir $origcwd;
};

# The key is an absolute path of a file.
# The value is a list of files which the file of the key includes.
my %dependencies = ();
&collect_recur('"' . $ARGV[0] . '"', \%dependencies);

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

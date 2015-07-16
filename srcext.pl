use strict;

my @incpath = ( 'incdir1', 'incdir2' );
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

sub basename {
	my ($s) = @_;
	$s =~ s#.*/([^/]*)$#$1#;
	return $s;
};

sub rmparen {
	my ($s) = @_;
	return substr $s, 1, length($s) - 2;
};

!&isabs("\"file1\"") or die "isabs1";
&isabs("<file1>") or die "isabs2";

sub cleanpath {
	my ($s) = @_;
	$s =~ s#/(\./)+#/#g;
	return $s;
};

&cleanpath("./././dir1") eq './dir1' or die 'cleanpath1';

# This subroutine collects files which the 1st argument file includes
# and inserts them into the 2nd argument hash.
sub collect {
	my ($file, $buf) = @_;
	my $in;
	open($in, '<', $file) or return 1;
	while (<$in>) {
		chomp;
		if (/$rinclude/) {
			s/$rinclude.*/$1/;
			push @$buf, $_;
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
	my ($file, $dir, $deps, $absdeps) = @_;
	my $abs = &isabs($file);
	my $deplist;
	$file = &rmparen($file);
	if ($abs) {
		my $tmp;
		for (my $i = 0; $i < scalar @incpath; ++$i) {
			my @d = ();
			$tmp = &cleanpath($incpath[$i] . '/' . $file);
			if (&collect($tmp, \@d) == 0) {
				$absdeps->{$tmp} = \@d;
				last;
			}
		}
		$file = $tmp;
		$deplist = %{$absdeps}{$file};
	} else {
		my @d = ();
		$file = &cleanpath($dir . '/' . $file);
		&collect($file, \@d);
		$deps->{$file} = \@d;
		$deplist = %{$deps}{$file};
	}
	for (my $i = 0; $i < scalar @{$deplist}; ++$i) {
		&collect_recur(@{$deplist}[$i], &getdir($file),
			$deps, $absdeps);
	}
};

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

1;

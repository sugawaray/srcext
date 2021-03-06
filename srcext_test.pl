use strict;

# This script tests the script below.
require "./srcext.pl";

# returns arguments list.
sub genarg {
	my @r = ('-d', './dest1', '-a', './destabs1', 'file1');
	return \@r;
};

sub setat {
	my ($a, $i, $v) = @_;
	@{$a}[$i] = $v;
	return $a;
};

sub getconf_test {
	# arg indice
	my $DEST = 1;
	my $ABSDEST = 3;
	my $SRC1ST = 4;

	my $c;	# config reference
	my @sl;	# source list

	$c = &getconf(&genarg());

	@sl = @{$c->{'srclist'}};
	defined $sl[0] or die '05';

	$c = &getconf(&setat(&genarg(), $DEST, './dest2'));
	$c->{'dest'} eq './dest2' or die '06';
	$c = &getconf(&setat(&genarg(), $DEST, './dest1'));
	$c->{'dest'} eq './dest1' or die '07';

	$c = &getconf(&setat(&genarg(), $ABSDEST, './destabs1'));
	$c->{'absdest'} eq './destabs1' or die '08';
	$c = &getconf(&setat(&genarg(), $ABSDEST, './destabs2'));
	$c->{'absdest'} eq './destabs2' or die '09';

	@sl = @{&getconf(&setat(&genarg(), $SRC1ST, 'file2'))->{'srclist'}};
	$sl[0] eq 'file2' or die '0A';
	@sl = @{&getconf(&setat(&genarg(), $SRC1ST, 'file1'))->{'srclist'}};
	$sl[0] eq 'file1' or die '0B';

	my @a;	# tmp array
	@a = @{&genarg()};
	push @a, ('file2');
	@sl = @{&getconf(\@a)->{'srclist'}};
	scalar @sl == 2 or die '0C';
}
&getconf_test();

my $sa;

&normpath('') eq '.' or die '30';
($sa = &normpath('ab')) eq 'ab' or printf("%s\n", $sa) and die '31';
($sa = &normpath('.')) eq '.' or printf("%s\n", $sa) and die '32';
&normpath('..') eq '..' or die '33';
&normpath('ab/cd/de') eq 'ab/cd/de' or die '34';
&normpath('././ab') eq 'ab' or die '35';
&normpath('./.') eq '.' or die '36';
&normpath('ab/cd/../../de') eq 'de' or die '37';
&normpath('..') eq '..' or die '38';
&normpath('ab/..') eq '.' or die '39';
&normpath('ab/../..') eq '..' or die '3A';
($sa = &normpath('ab/../../..')) eq '../..' or printf("%s\n", $sa) and die '3B';
&normpath('/') eq '/' or die '3C';

($sa = &genkey('.', '"ab"')) eq 'ab' or printf("%s\n", $sa) and die '20';
($sa = &genkey('.', '"./ab"')) eq 'ab' or printf("%s\n", $sa) and die '21';
($sa = &genkey('./d1', '<ab>')) eq 'd1/ab' or die '22';
($sa = &genkey('/d1', '<ab>')) eq '/d1/ab' or die '23';

($sa = &isabs('"ab"')) == 0 or die '50';
($sa = &isabs('<ab>')) == 1 or die '51';

($sa = &dirname('/ab/cd')) eq '/ab' or die '60';
($sa = &dirname('./ab/cd')) eq 'ab' or die '61';
($sa = &dirname('/')) eq '/' or die '62';
($sa = &dirname('./')) eq '.' or die '63';
($sa = &dirname('../')) eq '..' or die '64';

use Errno;

my $TESTDIR = 'testdir';
my $ABSDIR = 'absdir';
my $ABSDIR1 = 'absdir1';
my @ABSDIRLIST = ($ABSDIR);
sub createemptyindir {
	my ($n, $dir) = @_;
	my $r;
	$! = 0;
	if (!mkdir $dir) {
		$! == $!{EEXIST} or die 'createemptyindir 1';
	}
	open($r, '>', "${dir}/$n") or die 'createemptyindir 2';
	return $r;
};
sub createempty {
	my ($n) = @_;
	return &createemptyindir($n, $TESTDIR);
};

my @aa;
close(&createempty('a'));
$sa = &collect("$TESTDIR/a", \@aa);
$sa == 0 or die '40';
@aa == 0 or die '41';

$sa = &createempty('a');
print $sa "#include \"bb\"\n";
print $sa "#include \"cc\"\n";
print $sa "#include \<dd\>\n";
close($sa);
@aa = ();
$sa = &collect("$TESTDIR/a", \@aa);
$sa == 0 or die '42';
@aa = sort(@aa);
@aa == 3 or die '43';
$aa[0] eq '"bb"' or die '44';
$aa[1] eq '"cc"' or die '45';
$aa[2] eq '<dd>' or die '46';

unlink "$TESTDIR/a";
(&collect("$TESTDIR/a", \@aa) == 1) or die '47';

my %ha;
my %hb;
my @INCDIRS;
my @ab;
my @ac;

sub t_collect_recur_1 {
	close(&createempty('a'));
	&collect_recur('"a"', $TESTDIR, \%ha, \@ABSDIRLIST, \%hb);

	@aa = keys %ha;
	@aa == 1 or die '10';
	$aa[0] eq &genkey($TESTDIR, '"a"') or die '11';
	
	@ab = @{$ha{$aa[0]}};
	@ab == 0 or die '12';
	keys %hb == 0 or die '14';
}
&t_collect_recur_1();

sub createfileindir {
	my ($path, $content, $dir) = @_;
	my $t = &createemptyindir($path, $dir);
	if (defined($content)) {
		print $t $content;
	}
	close($t);
}

sub createfile {
	my ($path, $content) = @_;
	&createfileindir($path, $content, $TESTDIR);
}

sub assertarray {
	my ($t, $tt, $m) = @_;
	my @in = @{$t};
	my @expected = @{$tt};
	my $i;
	@in == @expected or die $m;
	for ($i = 0; $i < @in; ++$i) {
		if ($in[$i] ne $expected[$i]) {
			printf("expect(%s) but (%s)\n", $expected[$i], $in[$i]);
			die $m;
		}
	}
}

use File::Path qw(make_path);

sub t_collect_recur_2 {
	make_path("${TESTDIR}/dir1");
	&createfile('a',
		"#include \"b\"\n" .
		"#include \"dir1/c\"\n");
	&createfile('b');
	&createfile('dir1/c');
	%ha = ();
	%hb = ();
	&collect_recur('"a"', $TESTDIR, \%ha, \@ABSDIRLIST, \%hb);
	@aa = sort(keys %ha);
	@ab = ("${TESTDIR}/a", "${TESTDIR}/b", "${TESTDIR}/dir1/c");
	&assertarray(\@aa, \@ab, '16');
	@ab = sort(@{$ha{$aa[0]}});
	@ac = ('"b"', '"dir1/c"');
	&assertarray(\@ab, \@ac, '18');
	@ab = @{$ha{$aa[1]}};
	@ab == 0 or die '1C';
	@ab = @{$ha{$aa[2]}};
	@ab == 0 or die '1D';
}
&t_collect_recur_2();

sub t_collect_recur_3 {
	make_path("${TESTDIR}/dir1");
	&createfile('dir1/a', "#include \"b\"\n");
	&createfile('dir1/b');
	%ha = ();
	%hb = ();
	&collect_recur('"dir1/a"', $TESTDIR, \%ha, \@ABSDIRLIST, \%hb);
	@aa = sort(keys %ha);
	@ab = ("${TESTDIR}/dir1/a", "${TESTDIR}/dir1/b");
	&assertarray(\@aa, \@ab, '2C');
	@ab = @{$ha{$aa[0]}};
	@ab == 1 or die '2E';
	$ab[0] eq '"b"' or print $ab[0] and die '2F';
	@ab = @{$ha{$aa[1]}};
	@ab == 0 or die '2G';
}
&t_collect_recur_3();

sub t_collect_recur_4 {
	make_path("${TESTDIR}");
	&createfile('a', "#include \"b\"\n");
	&createfile('b', "#include \"c\"\n");
	&createfile('c');
	%ha = ();
	%hb = ();
	&collect_recur('"a"', $TESTDIR, \%ha, \@ABSDIRLIST, \%hb);
	@aa = sort(keys %ha);
	@ab = ("${TESTDIR}/a", "${TESTDIR}/b", "${TESTDIR}/c");
	&assertarray(\@aa, \@ab, '2H');
	@ab = @{$ha{$aa[0]}};
	@ac = ('"b"');
	&assertarray(\@ab, \@ac, '2I');
	@ab = @{$ha{$aa[1]}};
	@ac = ('"c"');
	&assertarray(\@ab, \@ac, '2K');
	@ab = @{$ha{$aa[2]}};
	@ac = ();
	&assertarray(\@ab, \@ac, '2M');
}
&t_collect_recur_4();

sub t_collect_recur_5 {
	make_path("${TESTDIR}");
	make_path("${ABSDIR}");
	&createfile('a', "#include <b>\n");
	&createfileindir('b', "", ${ABSDIR});
	%ha = ();
	%hb = ();
	&collect_recur('"a"', $TESTDIR, \%ha, \@ABSDIRLIST, \%hb);
	@aa = sort(keys %ha);
	@ab = ("${TESTDIR}/a");
	&assertarray(\@aa, \@ab, '2N');
	@ab = @{$ha{$aa[0]}};
	@ac = ('<b>');
	&assertarray(\@ab, \@ac, '2P');
	@aa = sort(keys %hb);
	@ab = ("${ABSDIR}/b");
	&assertarray(\@aa, \@ab, '2O');
	@ab = @{$hb{$aa[0]}};
	@ac = ();
	&assertarray(\@ab, \@ac, '2Q');
}
&t_collect_recur_5();

use POSIX qw/opendir readdir closedir/;
sub rmR {
	my ($a) = @_;
	my $d;
	my @e;
	my $i;
	my @r = stat($a);
	if (@r == 0) {
		return -1;
	} elsif (POSIX::S_ISDIR($r[2])) {
		if ($d = opendir($a)) {
			@e = &readdir($d);
			for ($i = 0; $i < @e; ++$i) {
				if ($e[$i] eq "." || $e[$i] eq "..") {
					next;
				}
				&rmR($a . "/" . $e[$i]);
			}
			&closedir($d);
			undef $d;
		}
	} else {
		unlink $a;
	}
	return 0;			
}

sub t_collect_recur_6 {
	&rmR("${TESTDIR}");
	&rmR("${ABSDIR}");
	make_path("${TESTDIR}");
	make_path("${ABSDIR}");
	&createfile('a', "#include \"b\"\n");
	%ha = ();
	%hb = ();
	&collect_recur('"a"', $TESTDIR, \%ha, \@ABSDIRLIST, \%hb);
	@aa = sort(keys %ha);
	@ab = ("${TESTDIR}/a", "${TESTDIR}/b");
	&assertarray(\@aa, \@ab, '30');
	@ab = @{$ha{$aa[1]}};
	@ab == 0 or die '31';
}
&t_collect_recur_6();

sub t_collect_recur_7 {
	print "t_collect_recur_7\n";
	print "The error messages should follow.\n";
	&rmR("${TESTDIR}");
	&rmR("${ABSDIR}");
	make_path("${TESTDIR}");
	&createfile('a', "#include <b>\n");
	%ha = ();
	%hb = ();
	my @empty = ();
	&collect_recur('"a"', $TESTDIR, \%ha, \@empty, \%hb);
	keys %hb == 0 or die '1';
}
&t_collect_recur_7();

sub t_collect_recur_8 {
	print "t_collect_recur_8\n";
	&rmR("${TESTDIR}");
	&rmR("${ABSDIR}");
	&rmR("${ABSDIR1}");
	make_path("${TESTDIR}");
	make_path("${ABSDIR}");
	make_path("${ABSDIR1}");
	&createfile('a', "#include <b>\n");
	&createemptyindir('b', $ABSDIR1);
	%ha = ();
	%hb = ();
	my @abslist = ($ABSDIR, $ABSDIR1);
	&collect_recur('"a"', $TESTDIR, \%ha, \@abslist, \%hb);
	@aa = sort(keys %hb);
	@aa == 1 or die '1';
	$aa[0] eq "${ABSDIR1}/b" or die '2';
}
&t_collect_recur_8();

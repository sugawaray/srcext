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

($sa = &genkey('.', '"ab"')) eq 'ab' or printf("%s\n", $sa) and die '20';
($sa = &genkey('.', '"./ab"')) eq 'ab' or printf("%s\n", $sa) and die '21';

use Errno;

my $TESTDIR = 'testdir';
sub createempty {
	my ($n) = @_;
	my $r;
	$! = 0;
	if (!mkdir $TESTDIR) {
		$! == $!{EEXIST} or die 'createempty 1';
	}
	open($r, '>', "$TESTDIR/$n") or die 'createempty 2';
	return $r;
};

my @aa;
close(&createempty('a'));
&collect("$TESTDIR/a", \@aa);
@aa == 0 or die '40';

$sa = &createempty('a');
print $sa "#include \"bb\"\n";
print $sa "#include \"cc\"\n";
print $sa "#include \<dd\>\n";
close($sa);
@aa = ();
&collect("$TESTDIR/a", \@aa);
@aa = sort(@aa);
@aa == 3 or die '41';
$aa[0] eq '"bb"' or die '42';
$aa[1] eq '"cc"' or die '43';
$aa[2] eq '<dd>' or die '44';

my %ha;
my %hb;
my @INCDIRS;
close(&createempty('a'));
&collect_recur('"a"', $TESTDIR, \%ha, \%hb);

@aa = keys %ha;
@aa == 1 or die '10';
$aa[0] eq &genkey($TESTDIR, '"a"') or die '11';

my @ab;
@ab = @{$ha{$aa[0]}};
@ab == 0 or die '12';

keys %hb == 0 or die '14';

use File::Path qw(make_path);
make_path("${TESTDIR}/dir1");
$sa = &createempty('a');
print $sa "#include \"b\"\n";
print $sa "#include \"dir1/c\"\n";
close($sa);
close(&createempty('b'));
close(&createempty('dir1/c'));
%ha = ();
%hb = ();
&collect_recur('"a"', $TESTDIR, \%ha, \%hb);
@aa = sort(keys %ha);
@aa == 3 or die '15';
$aa[0] eq "${TESTDIR}/a" or die '16';
$aa[1] eq "${TESTDIR}/b" or die '17';
$aa[2] eq "${TESTDIR}/dir1/c" or print $aa[2] and die '18';
@ab = @{$ha{$aa[0]}};
@ab = sort(@ab);
@ab == 2 or die '19';
$ab[0] eq '"b"' or die '1A';
$ab[1] eq '"dir1/c"' or die '1B';
@ab = @{$ha{$aa[1]}};
@ab == 0 or die '1C';
@ab = @{$ha{$aa[2]}};
@ab == 0 or die '1D';

use File::Path qw(make_path);
make_path("${TESTDIR}/dir1");
$sa = &createempty('dir1/a');
print $sa "#include \"b\"\n";
close($sa);
close(&createempty('dir1/b'));
%ha = ();
%hb = ();
&collect_recur('"dir1/a"', $TESTDIR, \%ha, \%hb);
@aa = sort(keys %ha);
@aa == 2 or die '2B';
$aa[0] eq "${TESTDIR}/dir1/a" or die '2C';
$aa[1] eq "${TESTDIR}/dir1/b" or die '2D';
@ab = @{$ha{$aa[0]}};
@ab == 1 or die '2E';
$ab[0] eq '"b"' or print $ab[0] and die '2F';
@ab = @{$ha{$aa[1]}};
@ab == 0 or die '2G';

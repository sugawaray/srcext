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

use Errno;

my $sa;
my %ha;
my %hb;
my $TESTDIR = 'testdir';
my @INCDIRS;
$! = 0;
if (!mkdir $TESTDIR) {
	$! == $!{EEXIST} or die 'test 1';
}
open($sa, '>', "$TESTDIR/a") or die 'test 2';
close($sa);
&collect_recur('"a"', $TESTDIR, \%ha, \%hb);
keys %ha == 1 or die '10';
keys %hb == 0 or die '11';

use strict;

#my @b = (1, 2, 3, 4, 5);
#@b = @b[1..$#b];
#foreach (@b) {
#	print $_ . ", ";
#}

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

# arg indice
my $DEST = 1;
my $ABSDEST = 3;
my $SRC1ST = 4;

my $c;	# config reference
my @sl;	# source list

$c = &getconf(&genarg());

@sl = @{$c->{'srclist'}};
defined $sl[0] or die 5;

$c = &getconf(&setat(&genarg(), $DEST, './dest2'));
$c->{'dest'} eq './dest2' or die 6;
$c = &getconf(&setat(&genarg(), $DEST, './dest1'));
$c->{'dest'} eq './dest1' or die 7;

$c = &getconf(&setat(&genarg(), $ABSDEST, './destabs1'));
$c->{'absdest'} eq './destabs1' or die 8;
$c = &getconf(&setat(&genarg(), $ABSDEST, './destabs2'));
$c->{'absdest'} eq './destabs2' or die 9;

@sl = @{&getconf(&setat(&genarg(), $SRC1ST, 'file2'))->{'srclist'}};
$sl[0] eq 'file2' or die 10;
@sl = @{&getconf(&setat(&genarg(), $SRC1ST, 'file1'))->{'srclist'}};
$sl[0] eq 'file1' or die 11;

my @a;	# tmp array
@a = @{&genarg()};
push @a, ('file2');
@sl = @{&getconf(\@a)->{'srclist'}};
scalar @sl == 2 or die 12;

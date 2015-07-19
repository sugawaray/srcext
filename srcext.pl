use strict;

sub getconf {
	my ($a) = @_;
	my @sl = ($a->[4]);
	my %r = ( 'dest' => $a->[1], 'absdest' => $a->[3], 'srclist' => \@sl );
	return \%r;
};

1;

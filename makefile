.POSIX :

PERL = /usr/bin/perl
PERLOPT = -W

test :
	$(PERL) $(PERLOPT) ./srcext_test.pl


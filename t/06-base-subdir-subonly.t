package Testophile;

use strict;

use FindBin qw( $Bin );

use FindBin::libs qw( base=lib subdir=FindBin subonly );

use Test::More tests => 1;

ok $INC[0] =~ m{/lib/FindBin $}x, "$INC[0]";

__END__

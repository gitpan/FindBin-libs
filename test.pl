#!/usr/bin/perl

package Testophile;

use strict;

$\ = "\n";
$, = "\n\t";

# export @lib after looking for */lib
# export @found after looking for */blib
# export @binz after looking for */bin, override the 
#  "ignore" to search /bin, /usr/bin.

use FindBin::libs qw( noprint export );
use FindBin::libs qw( export=found base=blib );
use FindBin::libs qw( print export=binz base=bin ignore=foo,bar );
use FindBin::libs qw( print export=junk base=frobnicatorium );

use Test::Simple tests => 7;

ok( @lib,     '@lib exported'   );
ok( @found,   '@found exported' );
ok( @binz,    '@binz exported'  );
ok( ! @junk,  'empty @junk exported'  );

ok( $lib[0]   eq "$FindBin::Bin/lib",	'Found lib' );
ok( $found[0] eq "$FindBin::Bin/blib",	'Found blib' );
ok( $binz[-1] =~ m{/bin$},            	'Found */bin' );

exit 0;

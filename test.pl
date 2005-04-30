#!/usr/bin/perl

package Testophile;

use strict;

$\ = "\n";
$, = "\n\t";

# export @lib after looking for */lib
# export @found after looking for */blib
# export @binz after looking for */bin, override the 
#  "ignore" to search /bin, /usr/bin.
#
# shouldn't print the output for "lib" or "blib", should print
# the resuilt for binz, junk.
#
# eval necessary for crippled O/S w/ missing/broken symlinks.

BEGIN
{
	eval { symlink qw( /nonexistant/path/to/foobar ./foobar ) }
}

use FindBin::libs qw( verbose export );
use FindBin::libs qw( verbose noprint export=found base=blib );
use FindBin::libs qw( verbose print export=binz base=bin ignore=foo,bar );
use FindBin::libs qw( verbose print export=junk base=frobnicatorium );
use FindBin::libs qw( verbose export base=foobar );

use Test::Simple tests => 8;

ok( @lib,		'@lib exported'   );
ok( @found,		'@found exported' );
ok( @binz,    	'@binz exported'  );
ok( ! @junk,  	'empty @junk exported'  );
ok( ! @foobar,	'empty @foobar exported' );

ok( $lib[0]   eq "$FindBin::Bin/lib",	'Found lib' );
ok( $found[0] eq "$FindBin::Bin/blib",	'Found blib' );
ok( $binz[-1] =~ m{/bin$},            	'Found */bin' );

# clean up temp files on the way out.

eval { -e and unlink } for qw( ./foobar );

exit 0;

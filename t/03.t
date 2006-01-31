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
#
# eval necessary for crippled O/S w/ missing/broken symlinks.

BEGIN
{
    print STDERR qq{\n\nVerbosely import 'bin  ', silently import 'lib'\n\n};
}

use FindBin::libs qw( noprint export nouse ignore= base=lib );
use FindBin::libs qw(   print export nouse ignore= base=bin );

use Test::More tests => 2;

ok( @lib,		'@lib exported' );
ok( @bin,		'@bin exported' );

exit 0;

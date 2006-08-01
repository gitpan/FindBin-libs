#!/usr/bin/perl

package Testophile;

use strict;

$\ = "\n";
$, = "\n\t";

use FindBin::libs qw( noprint export nouse ignore= base=lib );
use FindBin::libs qw(   print export nouse ignore= base=bin );

use Test::More tests => 2;

ok( @lib,		'@lib exported' );
ok( @bin,		'@bin exported' );

exit 0;

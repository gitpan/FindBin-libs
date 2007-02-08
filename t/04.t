#!/usr/bin/perl

package Testophile;

use strict;

$\ = "\n";
$, = "\n\t";

BEGIN   { mkdir './lib/foo', 0555   }
END     { rmdir './lib/foo'         }

use FindBin::libs qw( export subdir=foo );

use Test::More tests => 1;

ok ( grep /foo/, @lib ), 'Found foo subdir';

__END__

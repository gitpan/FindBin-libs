package Testophile;

use strict;

$\ = "\n";
$, = "\n\t";

BEGIN { -d './lib/foo' || mkdir './lib/foo', 0555  or die $! }
END   { -d './lib/foo' && rmdir './lib/foo'        or die $! }

use FindBin::libs qw( export subdir=foo );

use Test::More tests => 1;

ok ( grep /foo/, @lib ), 'Found foo subdir';

__END__

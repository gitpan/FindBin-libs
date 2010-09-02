package Testophile;

use strict;

use Test::More tests => 1;

$\ = "\n";
$, = "\n\t";

BEGIN { -d './lib/foo' || mkdir './lib/foo', 0555  or die $! }
END   { -d './lib/foo' && rmdir './lib/foo'        or die $! }

use FindBin::libs qw( export subdir=foo );

ok ( grep /foo/, @lib ), 'Found foo subdir';

__END__

package Testophile;

use strict;

use Test::More tests => 2;

BEGIN   { mkdir './blib/foo', 0555  }
END     { rmdir './blib/foo'        }

use FindBin::libs qw( base=blib subdir=foo subonly );
use FindBin::libs;

print join "\n", '@INC:', @INC, '';

ok $INC[1] =~ m{/blib/foo$}, 'Found foo subdir';
ok $INC[0] =~ m{/lib$}, 'Added lib dir';

__END__

package Testophile;

use v5.8;

use File::Spec::Functions   qw( catpath         );
use Symbol                  qw( qualify_to_ref  );

use Test::More tests => 2;

BEGIN   { mkdir './blib/blort', 0555  }
END     { rmdir './blib/blort'        }

require FindBin::libs;

FindBin::libs->import
(
    qw
    (
        base=blib
        subdir=blort
        subonly
        export=snark
        scalar
    )
);

my $ref     = qualify_to_ref 'snark';
my $expect  = catpath '' => qw( blib blort );

my $value   = ${ *$ref };

ok $value, "Exported scalar '\$snark'";
like $value, qr{\Q$expect\E $}x, "Found 'blib/blort' ($value)";

__END__

package Testophile;

use v5.8;

use File::Spec::Functions  qw( catpath );

use Test::More tests => 2;

BEGIN   { mkdir './blib/foo', 0555  }
END     { rmdir './blib/foo'        }

require FindBin::libs;

FindBin::libs->import( qw( base=blib subdir=foo subonly ) );

my $expect  = catpath '' => qw( blib foo );

ok $INC[0] =~ m{$expect $}x, 'Found only foo subdir';

FindBin::libs->import;

ok $INC[0] =~ m{/lib$}, 'Added lib dir';

__END__

package Testophile;

use v5.8;

use Test::More tests => 3;

use_ok 'FindBin::libs_curr',    'libs_curr is use-able';
use_ok 'FindBin::libs_5_8',     'libs_5_8 is use-able';
use_ok 'FindBin::libs',         'Module is use-able';

__END__

#!/usr/bin/perl

package Testophile;

use strict;

use Test::More tests => 1;

use_ok( 'FindBin::libs', 'Module is use-able' );

exit 0;

########################################################################
# housekeeping
########################################################################

use strict;
use Module::Build;

########################################################################
# figure out which versin of libs.pm to install based on the 
# current running version.
########################################################################

my $path 
= do
{
    my $type
    = ref $^V
    ? 'curr'
    : '5_8'
    ;

    "lib/FindBin/libs_$type.pm"
};

my @build_argz  =
(
    qw
    (
        module_name     FindBin::libs
        license         perl
        dist_version    1.8
    ),

    pm_files =>
    {
         $path  => 'lib/FindBin/libs.pm' 
    },

    dist_author => 'Steven Lembark <lembark@wrkhors.com',

    requires =>
    {
        qw
        (
            strict          0

            Carp            0
            Cwd             0
            FindBin         0
            Symbol          0
            File::Spec      0
            File::Temp      0
            List::Util      0
            Test::More      0

        )
    },

    configure_requires =>
    {
        'Module::Build' => $Module::Build::VERSION,
    },

    dist_abstract   => <<END
FindBin::libs - locate and a 'use lib' or export 
directories based on $FindBin::Bin.
END

);

Module::Build
->new( @build_argz )
->create_build_script;

__END__

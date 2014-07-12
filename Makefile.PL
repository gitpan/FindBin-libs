use ExtUtils::MakeMaker;

# even the old version is guaranteed not to work with anything earlier.

use 5.008;

my $stub	= 'lib/FindBin/libs';
my $dest	= $stub . '.pm';

my $path
= ref $^V && v5.10 le $^V 
? $stub . '_curr.pm'
: $stub . '_old.pm'
;

-e $dest && unlink $dest;
-e $dest && die "Failed unlink: '$dest' ($!)"; 

link $path => $dest;

[ -e $dest ] || die "Failed link: '$dest' ($!)";


WriteMakefile
(
    NAME            => 'FindBin::libs',
    VERSION         => '1.10',
    ABSTRACT_FROM   => $dest,
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

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
);

__END__

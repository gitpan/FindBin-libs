########################################################################
# FindBin::libs
#
# use $FindBin::Bin to search for 'lib' directories and use them.
#
# default action is to look for dir's named "lib" and silently use
# the lib's without exporting anything. print turns on a short 
# message with the abs_path results, export pushes out a variable
# (default name is the base value), verbose turns on decision output
# and print. export takes an optional argument with the name of a
# variable to export.
#
# Copyright (C) 2003, Steven Lembark, Workhorse Computing.
# This code is released under the same terms as Perl-5.6.1
# or any later version of Perl.
# 
########################################################################

########################################################################
# housekeeping
########################################################################

package FindBin::libs;

use 5.6.1;

use strict;
use warnings;

use Carp qw( &croak );

use FindBin;

use Symbol;

# both of these are in the standard distro and 
# should be available.

use File::Spec::Functions
qw
(
    &splitpath
    &splitdir
    &catpath
    &catdir
);

BEGIN
{
    # however... there have been complains of 
    # places where abs_path does not work. 
    #
    # if abs_path fails on the working directory
    # then replace it with rel2abs and live with 
    # possibly slower, redundant directories.

    use Cwd qw( &abs_path &cwd );

    unless( eval { abs_path cwd } )
    {
        # abs_path seems to be having problems,
        # fix is to stub it out.

        my $ref = qualify_to_ref 'abs_path', __PACKAGE__;

        undef &{ $ref };

        *$ref = sub{ $_[0] };
    };
}

########################################################################
# package variables 
########################################################################

our $VERSION = '1.20';

my %defaultz = 
(
	base    => 'lib',
	use     => 1,

	export	=> undef,
	verbose => undef,
    debug   => undef,

	print   => undef,

	ignore => '/,/usr',
);

# only new directories are used, ignore pre-loads
# this with unwanted values.

my %found = ();

# saves passing this between import and $handle_args.

my %argz = ();

my $verbose = 0;

########################################################################
# subroutines
########################################################################

sub find_libs
{
    my $base = shift || $argz{ base };

    # for some reason, RH Enterprise V/4 has a 
    # trailing '/'; I havn't seen another copy of 
    # FindBin that does this. fix is quick enough: 
    # strip the trailing '/'.
    #
    # using a regex to extract the value untaints it.
    # after that split path can grab the directory 
    # portion for future use.

    my ( $Bin ) = $FindBin::Bin =~ m{^(.+)/?$};

	print STDERR "\nSearching $Bin for '$base'...\n"
		if $verbose;

    my( $vol, $bin ) = splitpath $Bin, 1;

    my @bin = splitdir $bin;

	my @libz = ();

    for( 1 .. @bin )
    {
        
        my $abs
        = abs_path ( catpath $vol, ( catdir @bin, $base ) );

        if( $abs && -d $abs && ! exists $found{ $abs } )
        {
            $found{ $abs } = 1;

            push @libz, $abs;
        }

        pop @bin
    }

    # caller gets back the existing lib paths 
    # (including volume) walking up the path 
    # from $FindBin::Bin -> root.
    #
    # passing it back as a list isn't all that
    # painful for a few paths.

    wantarray ? @libz : \@libz
};

# break out the messy part into a separate block.

my $handle_args 
= sub
{
	# discard the module, rest are arguments.

	shift;

	# anything after the module are options with arguments
	# assigned via '='.

	%argz = 
		map
		{
			my ( $k, $v ) = split '=', $_, 2;

			if( $k =~ s{^(?:!|no)}{} )
			{
				$k => undef
			}
			else
			{
				$k => ( $v || '' )
			}
		}
		@_
	;

    # stuff "debug=1" into your arguments and perl -d will stop here.

    $DB::single = 1 if $argz{debug};

	# use defaults to false if export is an argument and use is not
	# (or nouse is specified).

	exists $argz{use} or $defaultz{use} = ! exists $argz{export};

	# now apply the defaults, then sanity check the result.
	# base is a special case since it always has to exist.
	#
	# if $argz{export} is defined but false then it takes
	# its default from $argz{base}.

	exists $argz{$_} or $argz{$_} = $defaultz{$_}
    for keys %defaultz;

	exists $argz{base} && $argz{base} 
    or croak "Bogus FindBin::libs: missing/false base argument, should be 'base=NAME'";

	defined $argz{export} and $argz{export} ||= $argz{base};

	$argz{ ignore } =
    [
        grep { $_ }
        split /\s*,\s*/,
        $argz{ignore}
    ];

	$verbose = defined $argz{verbose};

	my $base = $argz{base};

	# now locate the libraries.
	#
	# %found contains the abs_path results for each directory to 
	# avoid double-including directories.
    #
    # note: loop short-curcuts for the (usually) list.

    %found = ();

    for( @{ $argz{ ignore } } )
    {
            if( my $dir = abs_path catdir $_, $base )
            {
                if( -d $dir )
                {
                    $found{ $dir } = 1;
                }
            }
    }
};

sub import
{
    &$handle_args;

    my @libz = find_libs;

    my $caller = caller;

	if( $verbose || defined $argz{print} )
	{
		local $\ = "\n";
		local $, = "\n\t";

		print STDERR "Found */$argz{ base }:", @libz
	}

	if( $argz{export} )
	{
		my $caller = caller;

		print STDERR join '', "\nExporting: @", $caller, '::', $argz{export}, "\n"
			if $verbose;

        # Symbol this is cleaner than "no strict" 
        # for installing the array.

        my $ref = qualify_to_ref $argz{ export }, $caller;

        *$ref = \@libz;
	}

	if( $argz{use} )
	{
		my @code = 
		qw
        (
			{
				package caller ;
				use lib qw( list ) ;
			}
		);

        # insert the caller's package and replace the "list" 
        # token with the libs found.

		$code[2] = $caller;
		splice @code, 7, 1, @libz;

		my $code = join ' ', @code;

		print STDERR "\n", 'Executing:', $code, ''
        if $verbose;

		eval $code
	}

	0
}

# keep require happy

1

__END__

=head1 NAME

FindBin::libs - Locate and 'use lib' directories along
the path of $FindBin::Bin to automate locating modules.
Uses File::Spec and Cwd's abs_path to accomodate multiple
O/S and redundant symlinks.

=head1 SYNOPSIS

	# search up $FindBin::Bin looking for ./lib directories
	# and "use lib" them.

	use FindBin::libs;

	# same as above with explicit defaults.

	use FindBin::libs qw( base=lib use noexport noprint );

	# print the lib dir's before using them.

	use FindBin::libs qw( print );

	# find and use lib "altlib" dir's

	use FindBin::libs qw( base=altlib );

	# skip "use lib", export "@altlib" instead.

	use FindBin::libs qw( base=altlib export );

	# find altlib directories, use lib them and export @mylibs

	use FindBin::libs qw( base=altlib export=mylibs use );

	# "export" defaults to "nouse", these two are identical:

	use FindBin::libs qw( export nouse );
	use FindBin::libs qw( export       );

	# use and export are not exclusive:

	use FindBin::libs qw( use export );           # do both
	use FindBin::libs qw( nouse noexport print ); # print only
	use FindBin::libs qw( nouse noexport );       # do nothting at all

    # print a few interesting messages about the 
    # items found.

    use FindBinlibs qw( verbose );

    # turn on a breakpoint after the args are prcoessed, before
    # any search/export/use lib is handled.

    use FindBin::libs qw( debug );

=head1 DESCRIPTION

=head2 General Use

This module will locate directories along the path to $FindBin::Bin
and "use lib" or export an array of the directories found. The default
is to locate "lib" directories and "use lib" them without printing
the list. The basename searched for can be changed via 'base=name' so
that

	use FindBin::libs qw( base=altlib );

will search for directories named "altlib" and "use lib" them.

The 'export' option will push an array of the directories found
and takes an optional argument of the array name, which defaults 
to the basename searched for:

	use FindBin::libs qw( export );

will find "lib" directories and export @lib with the
list of directories found.

	use FindBin::libs qw( export=mylibs );

will find "lib" directories and export them as "@mylibs" to
the caller.

If "export" only is given then the "use" option defaults to 
false. So:

	use FindBin::libs qw( export );
	use FindBin::libs qw( export nouse );

are equivalent. This is mainly for use when looking for data
directories with the "base=" argument.

If base is used with export the default array name is the base
directory value:

	use FindBin::libs qw( export base=meta );

exports @meta while

	use FindBin::libs qw( export=metadirs base=meta );

exports @metadirs.

The use and export switches are not exclusive:

	use FindBin::libs qw( use export=mylibs );

will locate "lib" directories, use lib them, and export 
@mylibs into the caller's package. 

=head2 Skipping directories

By default, lib directories under / and /usr are
sliently ignored. This normally means that /lib, /usr/lib, and
'/usr/local/lib' are skipped. The "ignore" parameter provides
a comma-separated list of directories to ignore:

	use FindBin::libs qw( ignore=/skip/this,/and/this/also );

will replace the standard list and thus skip "/skip/this/lib"
and "/and/this/also/lib". It will search "/lib" and "/usr/lib"
since the argument ignore list replaces the original one.

=head2 Homegrown Library Management 

An all-too-common occurrance managing perly projects is
being unable to install new modules becuse "it might 
break things", and being unable to test them becuase
you can't install them. The usual outcome of this is a 
collection of hard-coded

	use lib qw( /usr/local/projectX ... )

code at the top of each #! file that has to be updated by
hand for each new project.

To get away from this you'll often see relative paths
for the lib's, which require running the code from one
specific place. All this does is push the hard-coding
into cron, shell wrappers, and begin blocks.

With FindBin::libs you need suffer no more.

Automatically finding libraries in and above the executable
means you can put your modules into cvs/svn and check them
out with the project, have multiple copies shared by developers,
or easily move a module up the directory tree in a testbed
to regression test the module with existing code. All without
having to modify a single line of code.

=item Code-speicfic modules.

Say your sandbox is in ./sandbox and you are currently
working in ./sandbox/projects/package/bin on a perl
executable. You may have some number of modules that
are specific -- or customized -- for this pacakge, 
share some modules within the project, and may want 
to use company-wide modules that are managed out of 
./sandbox in development. All of this lives under a 
./qc tree on the test boxes and under ./production 
on production servers.

For simplicity, say that your sandbox lives in your
home direcotry, /home/jowbloe, as a directory or a
symlink.

If your #! uses FindBin::libs in it then it will
effectively

	use lib
	qw(
		/home/jowbloe/sandbox/lib
		/home/jowbloe/sandbox/project/lib
		/home/jowbloe/sandbox/project/package/lib
	);

if you run /home/jowbloe/sandbox/project/package/bin/foobar.
This will happen the same way if you use a relative or
absolute path, perl -d the thing, or if any of the lib
directories are symlinks outside of your sandbox.

This means that the most specific module directories
("closest" to your executable) will be picked up first.

If you have a version of Frobnicate.pm in your ./package/lib
for modifications fine: you'll use it before the one in 
./project or ./sandbox. 

=item Regression Testing

Everntually, however, you'll need to regression test 
Frobnicate.pm with other modules. 

Fine: move, copy, or symlink it into ./project/lib and
you can merrily run ./project/*/bin/* with it and see 
if there are any problems. In fact, so can the nice 
folks in QC. 

If you want to install and test a new module just 
prefix it into, say, ./sandbox/lib and all the code
that has FindBin::libs will simply use it first. 

=item Testing with Symlinks

$FindBin::Bin is relative to where an executable is started from.
This allows a symlink to change the location of directories used
by FindBin::libs. Full regression testing of an executable can be
accomplished with a symlink:

	./sandbox
		./lib -> /homegrown/dir/lib
		./lib/What/Ever.pm

		./pre-change
			./bin/foobar

		./post-change
			./lib/What/Ever.pm
			./bin/foobar -> ../../pre-last-change/bin/foobar

Running foobar symlinked into the post-change directory will
test it with whatever collection of modules is in the post-change
directory. A large regression test on some collection of 
changed modules can be performed with a few symlinks into a 
sandbox area.

=item Managing Configuration and Meta-data Files

The "base" option alters FindBin::libs standard base directory.
This allows for a heirarchical set of metadata directories:

	./sandbox
		./meta
		./project/
			./meta

		./project/package
			./bin
			./meta

with

	use FindBin::libs qw( base=meta export );

	sub read_meta
	{
		my $base = shift;

		for my $dir ( @meta )
		{
			# open the first one and return
			...
		}

		# caller gets back empty list if nothing was read.

		()
	}

=back

=head1 Notes

=item File::Spec

In order to accmodate a wider range of filesystems, 
the code has been re-written to use File::Spec for
all directory and volume manglement. 

There is one thing that File::Spec does not handle,
hoever, which is fully reolving absolute paths. That
still has to be handled via abs_path, when it works.

The issue is that File::Spec::rel2abs and 
Cwd::abs_path work differently: abs_path only 
returns true for existing directories and 
resolves symlinks; rel2abs simply prepends cwd() 
to any non-absolute paths.

The difference for FinBin::libs is that 
including redundant directories can lead to 
unexpected results in what gets included; 
looking up the contents of heavily-symlinked 
paths is slow (and has some -- admittedly 
unlikely -- failures at runtime). So, abs_path() 
is the preferred way to find where the lib's 
really live after they are found looking up the 
tree. Using abs_path() also avoids problems 
where the same directory is included twice in a 
sandbox' tree via symlinks.

Due to previous complaints that abs_path did not 
work properly on all systems, the current 
version of FindBin::libs uses File::Spec to 
break apart and re-assemble directories, with 
abs_path used optinally. If "abs_path cwd" works 
then abs_path is used on the directory paths 
handed by File::Spec::catpath(); otherwise the 
paths are used as-is. This may leave users on 
systms with non-working abs_path() having extra
copies of external library directories in @INC.

Another issue is that I've heard reports of 
some systems failing the '-d' test on symlinks,
where '-e' would have succeded. 

=over 4

=item 

=head1 See Also

NEXT::init can be combined with FindBin::libs to 
manage inherited data. This can be a lifesaver 
for setting up working environments on systms with
tiered sandboxes.

=head1 BUGS

=over 4

=item 

In order to avoid including junk, FindBin::libs
uses '-d' to test the items before including
them on the library list. This works fine so 
long as abs_path() is used to disambiguate any
symlinks first. If abs_path() is turned off
then legitimate directories may be left off in
whatever local conditions might cause a valid
symlink to fail the '-d' test."

=item

Oddity during "make test". You'll probably get
a bunch of warnings like

    Use of uninitialized value in string ne at
    /opt/perl5/5.8/lib/5.8.6/i686-linux-thread-multi/File/Spec/Unix.pm
    line 313.
    Use of uninitialized value in concatenation (.) or string at
    /opt/perl5/5.8/lib/5.8.6/i686-linux-thread-multi/File/Spec/Unix.pm
    line 321.

They do not show up with "prove -v t/*.t" nor with
"perl t/01.t", etc. They also do not seem to affect 
the outcome: all of the tests pass with the warnings.
Only when running make test. At this point I am 
going to ignore them.

=head1 AUTHOR

Steven Lembark, Workhorse Computing <lembark@wrkhors.com>

=head1 COPYRIGHT

This code is released under the same terms as Perl-5.8.1 itself,
or any later version of Perl the user prefers.

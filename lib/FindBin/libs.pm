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
# This code is released under the same terms as Perl-5.8.1
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

use FindBin qw( $Bin );

use Cwd qw( &abs_path );

########################################################################
# package variables 
########################################################################

our $VERSION = '0.10';

my %defaultz = 
(
	base    => 'lib',
	use     => 1,

	export	=> undef,
	verbose => undef,

	print   => 0,

	ignore => '/ /usr',
);

########################################################################
# subroutines
########################################################################

sub import
{
	$DB::single = 1;

	# deal with the use arguments.

	my $module = shift;

	# anything after the module are options with arguments
	# assigned via '='.

	my %argz = 
		map
		{
			my ( $k, $v ) = split '=', $_, 2;

			$v = undef if $k =~ s{^(?:!|no)}{};

			$k => ( $v || '' )
		}
		@_
	;

	# use defaults to false if export is an argument and use is not
	# (or nouse is specified).

	exists $argz{use} or $defaultz{use} = ! exists $argz{export};

	# now apply the defaults, then sanity check the result.
	# base is a special case since it always has to exists.
	#
	# if $argz{export} is defined but false then it takes
	# its default from $argz{base}.

	exists $argz{$_} or $argz{$_} = $defaultz{$_}
		for keys %defaultz;

	exists $argz{base} && $argz{base} 
		or croak "Bogus FindBin::libs: missing base argument, should be 'base=NAME'";

	defined $argz{export} and $argz{export} ||= $argz{base};

	$argz{ignore} = [ split /,/, $argz{ignore} ];

	$argz{print} ||= defined $argz{verbose};

	# syntatic sugar, minor speedup.

	my $verbose = defined $argz{verbose};

	my $base = $argz{base};

	# now locate the libraries.
	#
	# %found contains the abs_path results for each directory to 
	# avoid double-including directories.

	my %found =
		map
		{
			(-d "$_/$base") ? (abs_path("$_/$base") => 1) : ()
		}
		@{ $argz{ignore} }
	;

	# walk down the tree from the root and find any dir's
	# with the basename. if the dir exists at all then 
	# abs_path it to ensure that a unique list of names
	# is used -- the order of symlinks will still be used.
	#
	# if the item has not already been found and is an
	# existing directory then store it and keep moving
	# down the tree.
	#
	# reversing the list gets the lowest dir's first, which
	# are the ones closer to the executable.

	print STDERR "\nSearching $Bin for $base...\n"
		if $verbose;

	my $dir = '';

	my @libs =
		reverse
		map 
		{
			$dir .= "/$_";

			my $lib = abs_path "$dir/$base";

			! $found{$lib} && -d $lib ? ($found{$lib}=$lib) : ();
		}
		split '/', $Bin
	;

	# print the dir's found if asked to, then do the deeds.

	if( $argz{print} )
	{
		local $\ = "\n";
		local $, = "\n\t";

		print STDERR "Found */$base:", @libs
	}

	if( $argz{export} )
	{
		my $caller = caller;

		print STDERR join '', "\nExporting: @", $caller, '::', $argz{export}, "\n"
			if $verbose;

		no strict 'refs';

		*{ $caller . '::' . $argz{export} } = \@libs
	}

	if( $argz{use} )
	{
		my @code = 
		qw(
			{
				package caller ;
				use lib qw( list ) ;
			}
		);

		$code[2] = caller;
		splice @code, 7, 1, @libs;

		my $code = join ' ', @code;

		print STDERR "\n", $code, "\n" if $verbose;

		eval $code
	}

	0
}

# keep require happy

1

__END__

=head1 NAME

FindBin::libs

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


=head1 BUGS

Doesn't use File::Spec and depends on splitting $Bin on '/' to
get subdirectories. Tested on *NIX, should run on OS/X, Cygwin. 


=head1 AUTHOR

Steven Lembark, Workhorse Computing <lembark@wrkhors.com>

=head1 COPYRIGHT

This code is released under the same terms as Perl-5.8.1 itself,
or any later version of Perl the user prefers.

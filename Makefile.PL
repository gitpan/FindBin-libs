use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME            => 'FindBin::libs',
	VERSION_FROM    => 'lib/FindBin/libs.pm',
	ABSTRACT        => 'Search $FindBin::Bin for ./lib dirs and use them',
	PREREQ_PM =>
	{
		# standard distros

		strict       => 0,
		warnings     => 0,
		Carp         => 0,
		Cwd          => 0,
		FindBin      => 0,
	},
);

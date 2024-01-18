#!/usr/bin/perl

use File::Basename;

my ($myself, $path) = fileparse($0);
chdir($path);

use FindBin;
use lib $FindBin::Bin;
require 'helpers.pm';

chdir('..');
chdir('..');

open(PDBLOG, '../OUTPUT/pdblog.txt') or die "Could not open pdblog.txt: $!\n";

#Get version info
my ($version);
$version = Build::ProductVersion(Build::PathFormat('product.version'));
$version =~ s/-dev//g;
$version .= '-git' . Build::GitRevNum('.');

my ($build_type);
$build_type = Build::GetBuildType(Build::PathFormat('tools/buildbot/build_type'));

if ($build_type eq "dev")
{
	$build_type = "buildbot";
}
elsif ($build_type eq "rel")
{
	$build_type = "release";
}

my ($line);
while (<PDBLOG>)
{
	$line = $_;
	$line =~ s/\.pdb/\*/;
	chomp $line;
	Build::Command("symstore add /r /f \"..\\OUTPUT\\$line\" /s \"S:\\source2mod\" /t \"Source2Mod\" /v \"$version\" /c \"$build_type\"");
}

close(PDBLOG);

#Lowercase DLLs.  Sigh.
my (@files);
opendir(DIR, "S:\\source2mod") or die "Could not open source2mod symbol folder: $!\n";
@files = readdir(DIR);
closedir(DIR);

my ($i, $j, $file, @subdirs);
for ($i = 0; $i <= $#files; $i++)
{
	$file = $files[$i];
	next unless ($file =~ /\.dll$/);
	next unless (-d "S:\\source2mod\\$file");
	opendir(DIR, "S:\\source2mod\\$file") or die "Could not open S:\\source2mod\\$file: $!\n";
	@subdirs = readdir(DIR);
	closedir(DIR);
	for ($j = 0; $j <= $#subdirs; $j++)
	{
		next unless ($subdirs[$j] =~ /[A-Z]/);
		Build::Command("rename S:\\source2mod\\$file\\" . $subdirs[$j] . " " . lc($subdirs[$j]));
	}	
}


#!/usr/bin/perl -w
use strict;
use warnings;
use Switch;
use Cwd;
use File::chdir;
use Git::Repository;
use Data::Dumper;
use List::MoreUtils 'any';

my $repo;
if($ARGV[0] && -d "/var/www/$ARGV[0]"){
	$repo = $ARGV[0];
}elsif(getcwd() =~ /^\/var\/www\/([\w\d\.]+)$/){
	$repo = $1;
}else{
	die "Error: Repo '$ARGV[0]' not found!";
}

$CWD = "/var/www/$repo";

my $git = Git::Repository->new();

$git->run('pull');

my @diff = $git->run('diff', '--name-only', 'HEAD^1', 'HEAD');
if( any{ /^(js|css)\// } @diff ){
	if(-f 'gulpfile.js'){
		system('gulp prod');
	}elsif(-f 'Gruntfile.js'){
		system('grunt prod');
	}
}

system('naught deploy index.ipc');

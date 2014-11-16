#!/usr/bin/perl -w
use strict;
use warnings;
use Switch;
use Cwd;
use File::chdir;
use Git::Repository;
use Data::Dumper;

my $repo;
if($ARGV[0] && -d "/var/www/$ARGV[0]"){
	$repo = $ARGV[0];
}elsif(getcwd() =~ /^\/var\/www\/([\w\d\.]+)$/){
	$repo = $1;
}else{
	$ARGV[0] = '' if not $ARGV[0];
	die "Error: Repo '$ARGV[0]' not found!";
}

$CWD = "/var/www/$repo";

my $git = Git::Repository->new();

$git->run('submodule', 'foreach', 'git', 'pull');
$git->run('pull');

#TODO: Diff between previous HEAD and HEAD, not only HEAD and prevous commit
my @diff = $git->run('diff', '--name-only', 'HEAD^1', 'HEAD');
if( /^package\.json$/ ~~ @diff ){
	system('npm install');
}
if( /^(js|css)\// ~~ @diff ){
	if(-f 'gulpfile.js'){
		system('gulp prod');
	}elsif(-f 'Gruntfile.js'){
		system('grunt prod');
	}
	system('chown 1000:33 public/css -R');
}

system('naught deploy --override-env false naught.ipc') if(-e 'naught.ipc');

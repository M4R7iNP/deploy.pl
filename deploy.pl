#!/usr/bin/perl -w
use strict;
use warnings;
use Switch;
use Cwd;
use File::chdir;
use Git::Repository;
use Data::Dumper;

my $repo;
my $force;

while (my $arg = shift @ARGV) {
    switch ($arg) {
        case '--force' {
            $force = shift @ARGV;
        }
        else {
            if (!$repo && -d "/srv/www/$arg") {
                $repo = $arg;
            }
        }
    }
}

if (!$repo) {
    if (getcwd() =~ /^\/srv\/www\/([\w\d\.]+)$/) {
        $repo = $1;
    } else {
        die "Error: Repo not found!";
    }
}

$CWD = "/srv/www/$repo";

my $git = Git::Repository->new();
my $preCommitId = $git->run('rev-parse', 'HEAD');

#$git->run('submodule', 'update', '--init', '--recursive') unless scalar glob('./models/*'); #Doesnt work :c
#$git->run('submodule', 'update', '--init', '--recursive'); #still doesnt work
#$git->run('submodule', 'foreach', 'git', 'pull');
$git->run('submodule', 'init');
$git->run('submodule', 'update', '--init', '--recursive'); #still doesnt work
$git->run('fetch');
$git->run('checkout', 'HEAD');

if($git->run('rev-parse', 'HEAD') eq $preCommitId) {
    $preCommitId = 'HEAD~';
}

my @diff = $git->run('diff', '--name-only', $preCommitId, 'HEAD');
if (grep(/^package\.json$/, @diff) || !-e 'node_modules' ) {
    system('npm install --production') && die('npm install failed. Check output, resolve errors, run npm install again and then deploy again.');
}
if (grep(/^(js|css)\//, @diff) || !-e 'public/js' || !-e 'public/css' || ($force && $force eq 'gulp')) {
    if (-f 'gulpfile.js') {
        system('gulp prod');
    }
    elsif (-f 'Gruntfile.js') {
        system('grunt prod');
    }
    system('chown 1000:33 public/css -R');
    system('chown 1000:33 public/js -R');
}

if (-e 'naught.ipc') {
    system('naught deploy --override-env false naught.ipc');
} else {
    system('NODE_ENV=production naught start index.js');
    #chown((getpwnam('martin'))[2], (getpwnam('www-data'))[2], 'naught.ipc');
    #chmod 660, 'naught.ipc';
}

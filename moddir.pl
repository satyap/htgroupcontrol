#!/usr/bin/perl -w

use strict;
use warnings;
use CGI;
use LWP::Simple;
use HTML::Template;
require 'modutil.pl';
our $file;
our $docs;
our $base;


my $q=new CGI;
if($q->param('logout')) {
    print "Location: logout.html\n\n";
} # logout

my $template=HTML::Template->new(
    filename => 'moddir.html',
    loop_context_vars => 1,
);

my $footer='</td></tr></table></center></body></html>';

my $user=$ENV{'REMOTE_USER'} || &error($template, "You're not authorized");

my $newdir = $q->param('newdir') || '';
$newdir =~ s/[^a-zA-Z0-9_]//g;
my $restr = $q->param('restr') || '';
my $valid = $q->param('valid') || '';
my $dirmod = $q->param('dirmod') || '';
$dirmod =~ s/[^a-zA-Z0-9_]//g;

opendir(DIR,"$docs") || die "$!";
my @dirs = readdir(DIR);
closedir(DIR);
my %dirs = map {$_ => 1} @dirs;

if($newdir) {
    if(exists $dirs{$newdir}) {
        &error($template,"$newdir already exists");
    }
    mkdir("$docs/$newdir") || do {
        &error($template, "$newdir creation failed: $!");
    };
    &writehtaccess($newdir,$template);
    my $groups = {};
    my $users = &initusers($user);
    ($users,$groups) = processfile(
        file=>$file,
        tpl=>$template,
        user=>$user,
        users => $users,
    );
    $groups->{$newdir.'_admin'} = [$user];
    $groups->{$newdir.'_read'} = [$user];
    $groups->{$newdir.'_write'} = [$user];
    &writefile(
        tpl=>$template,
        groups => $groups,
        file => $file,
    );
    $template->param(MSG => "$newdir created");
} # newdir


if($restr ne '' && $dirmod ne '') {
    if(!exists $dirs{$dirmod}) {
        &error($template,"$dirmod doesn't exist");
    }
    &writehtaccess($dirmod,$template);
    $template->param(MSG => "$dirmod set to restricted access, please check the <a href=\"modgroup.pl\">access control lists</a>");
} # restr icted access

if($valid ne '' && $dirmod ne '') {
    if(!exists $dirs{$dirmod}) {
        &error($template,"$dirmod doesn't exist");
    }
    &writevalidhtaccess($dirmod,$template);
    $template->param(MSG => "All valid users have read access on $dirmod, please check the <a href=\"modgroup.pl\">access control lists</a> for write access.");
} # valid user access

my @dirlist;
foreach my $dir (sort @dirs) {
    next if substr($dir,0,1) eq '.';
    push(@dirlist, {
            dir => $dir,
        });
}
$template->param(DIRS => \@dirlist);

print $template->output;
exit;


sub writehtaccess() {
    my $newdir = shift;
    my $template=shift;
    open(HTACCESS,"> $docs/$newdir/.htaccess") || &error($template,"cannot write htaccess file: $!");
    print HTACCESS <<HTACCESS;
    <Limit MKCOL PUT DELETE LOCK UNLOCK COPY MOVE PROPPATCH POST OPTIONS PROPFIND>
    require group ${newdir}_write
    </Limit>
    <Limit GET PROPFIND PROPPATCH>
    require group ${newdir}_read
    </Limit>
HTACCESS
    close(HTACCESS);
} # writehtaccess

sub writevalidhtaccess() {
    my $newdir = shift;
    my $template=shift;
    open(HTACCESS,"> $docs/$newdir/.htaccess") || &error($template,"cannot write htaccess file: $!");
    print HTACCESS <<HTACCESS;
    <Limit MKCOL PUT DELETE LOCK UNLOCK COPY MOVE PROPPATCH POST OPTIONS PROPFIND>
    require group ${newdir}_write
    </Limit>
    <Limit GET PROPFIND PROPPATCH>
    require valid-user
    </Limit>
HTACCESS
    close(HTACCESS);
} # writehtaccess

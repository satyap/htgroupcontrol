#!/usr/bin/perl -w

use strict;
use warnings;
use CGI;
use LWP::Simple;
use HTML::Template;
use Net::LDAP;
use Fcntl ':flock';
require 'modutil.pl';

our $file;
our $base;
our $docs;

### end editable portion

my $q=new CGI;

if($q->param('logout')) {
    print "Location: logout.html\n\n";
} # logout

my $template=HTML::Template->new(
    filename => 'modgroup.html',
    loop_context_vars => 1,
);


my $footer='</td></tr></table></center></body></html>';

#
# AUTHORIZE
# 

my $user=$ENV{'REMOTE_USER'} || do {
    $template->param(MSG => "You're not authorized");
    print $template->output;
    exit;
};
my $users = &initusers($user);

# set group permissions for this user's groups
#%gperms=(
#    $user.'admin' => {
#        $user.'_admin' => 1,
#        $user.'_read' => 1,
#        $user.'_write' => 1,
#    }, # gives the admin group permission to modify read and write group and itself too.
#); # group permissions


#
# READ user/group DATA from file
# 
my $groups;
($users,$groups) = &processfile( 
    file=>$file, 
    tpl=>$template,
    user=>$user,
    users => $users,
);

#use CGI::Carp;
#use Data::Dumper;
#croak(Dumper(\%users));

unless(exists $users->{$user}) {
    $template->param(MSG => "You're not authorized for any group");
    print $template->output;
    exit;
}

#
# RESTORE?
# 

if($q->param('restore')) {
    my $dump;
    my $fh=$q->param('filename');
    my @g=<$fh>;
    foreach (@g) {
        chomp;
        my ($n,$l)=split(/:\s+/,$_,2);
        next unless $users->{$user}->{$n};
        $groups->{$n}=[ split(/\s+/,$l) ];
    }
    &writefile(
        tpl=>$template,
        groups => $groups,
        file => $file,
    );
    print "Location: modgroup.pl\n\n";
    exit;
    ($users,$groups) = &processfile(
        file=>$file,
        tpl=>$template,
        user=>$user,
        users => $users,
    );
} # restore

#
# BACKUP?
# 

if($q->param('backup')) {
    print "Content-type: application/octet-stream\n";
    print "Content-Disposition: attachment; filename=modgroup.txt\n\n";
    my $dump='';
    foreach my $g (sort keys %$groups) {
        next unless $users->{$user}->{$g};
        $dump.="$g: ";
        $dump.=join(' ',@{ $groups->{$g} });
        $dump.="\n";
    }
    print $dump;
    exit;
} # backup

#
# SAVE CHANGES
# 

my $editgroup=$q->param('modgroupgroupname');
if($editgroup && $users->{$user}->{$editgroup}) {
    my $mna=$q->param('modgroupnewname');
    $mna=~s/[^-_a-zA-Z0-9]//g;
    if($mna) {
        push(@{ $groups->{$editgroup} },$q->param('modgroupnewname'));
    }
    my @newgroup;
    foreach (@{ $groups->{$editgroup} }) {
        next if $q->param($_);
        push(@newgroup,$_);
    }
    $groups->{$editgroup}=\@newgroup;
    &writefile(
        tpl=>$template,
        groups => $groups,
        file => $file,
    );
    print "Location: modgroup.pl\n\n";
    exit;
}


#
# now show allowed groups
#
#
my @groups;
foreach my $k (sort keys %$groups) {
    next unless $users->{$user}->{$k};
    my $hash={};
    $hash->{'group'}=$k;
    $hash->{'users'}=[];
    foreach (sort @{$groups->{$k}}) {
        my $h2={};
        $h2->{'user'}=$_;
        push(@{$hash->{'users'}},$h2);
    }
    push(@groups,$hash);
}
$template->param(GROUPS => \@groups);


print $template->output;
exit;





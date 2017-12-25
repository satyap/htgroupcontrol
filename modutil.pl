# contains utility scripts

use Fcntl ':flock';
our $file='/etc/accesscontrol/groupcontrol';
our $base='/var/www/accesscontrol';
our $docs='/var/www/base/of/protected/tree';

sub initusers() {
    my $user=shift;
    my $users={
    }; # user permissions
    $users->{$user} = {
        $user.'_admin' => 1,
        $user.'_read' => 1,
        $user.'_write' => 1,
    }; # user permissions -- this user has permission on all his/her groups

}

sub processfile() {
    # read user/group data from access control file
    my %args = @_;
    my $file = $args{'file'};
    my $template = $args{'tpl'};
    my $user = $args{'user'};
    my $users = $args{'users'};
    #my %groups = %{ $args{'groups'} };

    my %groups; # set up empty groups, to be populated below
    $groups{$user . '_admin'} = [];
    $groups{$user . '_read'} = [];
    $groups{$user . '_write'} = [];

    open(DAT,"<$file") || do {
        $template->param(MSG => "Couldn't open data file for reading");
        print $template->output;
        die "$file: $!";
    };
    flock(DAT,LOCK_EX);
    my @g=<DAT>;
    flock(DAT,LOCK_UN);
    close(DAT);

    foreach (@g) {
        chomp;
        next if (/^$/ || /^:$/);
        my ($n,$l)=split(/:\s*/,$_,2);
        if(defined($l) && $l !~/^\s*$/) {
            $groups{$n}=[ split(/\s+/,$l) ];
        }
        else {
            $groups{$n}=[ ];
        }
    }

# for each admin group in keys(%groups)
#   if the user is in that group,
#     give user permission on the corresponding read and write groups
# similarly for write groups, give them read access

    foreach my $k (keys %groups) {
        next unless $k=~/^(.+)_admin$/;
        my $g = $1;
        foreach my $u (@{$groups{$k}}) {
           if ($u eq $user) {
                $users->{$user}->{$g . '_admin'} = 1;
                $users->{$user}->{$g . '_read'} = 1;
                $users->{$user}->{$g . '_write'} = 1;
            }
        }
    }
    foreach my $k (keys %groups) {
        next unless $k=~/^(.+)_write$/;
        my $g = $1;
        foreach my $u (@{$groups{$k}}) {
            if ($u eq $user) {
                $users->{$user}->{$g . '_read'} = 1;
            }
        }
    }
    return $users,\%groups;
} # sub processfile


sub writefile() {
    my %args = @_;
    my $file = $args{'file'};
    my $template = $args{'tpl'};
    my $groups = $args{'groups'};

    my $dump='';
    foreach my $g (sort keys %$groups) {
        $dump.="$g: ";
        $dump.=join(' ',&uniq($groups->{$g}));
        $dump.="\n";
    }
    open(DAT,">$file") || do {
        $template->param(MSG => "Couldn't open data file for writing");
        print $template->output;
        die "$file: $!";
    };
    flock(DAT,LOCK_EX);
    print DAT $dump;
    flock(DAT,LOCK_UN);
    close(DAT);

} # writefile

sub uniq() {
    # given arrayref ($), return an array (@) of unique elements
    my $arrayref=shift;
    my %hash;
    foreach (@$arrayref) {
        $hash{$_} = 1;
    }
    return sort keys %hash;
} # sub uniq


sub error() {
    my $template=shift;
    my @message=@_;
    $template->param(MSG => join(" ",@message));
    print $template->output;
    exit;
} # error


1;

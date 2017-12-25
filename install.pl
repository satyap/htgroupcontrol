#!/usr/bin/perl

use strict;
use warnings;

my $systems = {
    'd' => { # debian
        scriptbase => '/usr/lib/cgi-bin',
    },
    'r' => { # redhat
        scriptbase => '/var/www/cgi-bin',
    },
    'o' => { # other
        scriptbase => '/usr/lib/cgi-bin',
    },
    'v' => { # devel
        scriptbase => '/home/satyap/public_html/htgroupcontrol',
    },
};

my $appdir='htgroupcontrol';

sub prompt(@) {
    my $pr = shift;
    my $def = shift;
    my @allowed=@_;
    my %allowed = map {$_ => 1}  @allowed;
    my $inp;
    while(!defined($inp)) {
        print "$pr [$def] ";
        $inp = <>;
        chomp($inp);
        if($inp eq '') {
            $inp = $def;
        }
        undef($inp) unless ($#allowed<0 || exists($allowed{$inp}) );
    }
    return $inp;
}

my $sys = lc(prompt('Which system? (Debian/Redhat/Other/deVelopment)','d',
        map {uc($_),lc($_)} keys(%$systems),
    ));

my $mysys = $systems->{$sys};

my $scriptbase = prompt("Where do you want to install the htgroupcontrol CGI scripts?\n",$mysys->{'scriptbase'});


if(-e "$scriptbase/$appdir" && -d "$scriptbase/$appdir") {
    my $res = lc(prompt("$scriptbase/$appdir already exists, do you want to overwrite? (y/n)",'y',  'y','n'));
    if($res eq 'n') {
        print "Installation cancelled\n";
        exit;
    }
}



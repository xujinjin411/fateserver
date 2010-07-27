package FATE;

use strict;
use warnings;

use POSIX qw/asctime mktime/;

BEGIN {
    use Exporter;
    our ($VERSION, @ISA, @EXPORT);
    $VERSION = 0.1;
    @ISA     = qw/Exporter/;
    @EXPORT  = qw/split_header split_config split_rec parse_date agestr
                  doctype start end tag h1 trow trowa trowh th td anchor
                  fail $fatedir $recent_age $ancient_age/;
}

our $fatedir;
our $recent_age  = 3600;
our $ancient_age = 3 * 86400;

require "$ENV{FATEWEB_CONFIG}";

# report utils

sub split_header {
    my @hdr = split /:/, $_[0];
    $hdr[0] eq 'fate' or return undef;
    return {
        version => $hdr[1],
        date    => $hdr[2],
        slot    => $hdr[3],
        rev     => $hdr[4],
        status  => $hdr[5],
        errstr  => $hdr[6],
    };
}

sub split_config {
    my @conf = split /:/, $_[0];
    $conf[0] eq 'config' or return undef;
    return {
        arch    => $conf[1],
        subarch => $conf[2],
        cpu     => $conf[3],
        os      => $conf[4],
        cc      => $conf[5],
        config  => $conf[6],
    };
}

sub split_rec {
    my @rec = split /:/, $_[0];
    return {
        name   => $rec[0],
        status => $rec[1],
        diff   => $rec[2],
        stderr => $rec[3],
    };
}

sub parse_date {
    $_[0] =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/ or return undef;
    mktime $6, $5, $4, $3, $2-1, $1-1900;
}

sub agestr {
    my ($age, $time) = @_;
    my $agestr;
    if ($age <= 0) {
        $agestr = 'Right now';
    } elsif ($age < 60) {
        $agestr = "$age seconds ago";
    } elsif ($age < 60 * 120) {
        $agestr = sprintf '%d minutes ago', $age / 60;
    } elsif ($age < 48 * 3600) {
        $agestr = sprintf '%d hours ago',   $age / 3600;
    } elsif ($age < 14 * 86400) {
        $agestr = sprintf '%d days ago',    $age / 86400;
    } else {
        $agestr = asctime gmtime $time;
    }
    return $agestr;
}

# HTML helpers

my %block_tags;
my @block_tags = ('html', 'head', 'style', 'body', 'table');
$block_tags{$_} = 1 for @block_tags;

my @tags;

sub doctype {
    print q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">}, "\n";
}

sub opentag {
    my ($tag, %attrs) = @_;
    print qq{<$tag};
    print qq{ $_="$attrs{$_}"} for grep defined $attrs{$_}, keys %attrs;
}

sub start {
    my ($tag, %attrs) = @_;
    opentag @_;
    print '>';
    print "\n" if defined $block_tags{$tag};
    push @tags, $tag;
}

sub end {
    my ($end) = @_;
    my $tag;
    do {
        $tag = pop @tags or last;
        print "</$tag>";
        print "\n" if defined $block_tags{$tag};
    } while (defined $end and $tag ne $end);
}

sub tag {
    opentag @_;
    print "/>\n";
}

sub h1 {
    my ($text, %attrs) = @_;
    start 'h1', %attrs;
    print $text;
    end;
    print "\n";
}

sub trow {
    start 'tr';
    print "<td>$_</td>" for @_;
    end;
    print "\n";
}

sub trowh {
    start 'tr';
    print "<th>$_</th>" for @_;
    end;
    print "\n";
}

sub trowa {
    my $attrs = shift;
    start 'tr', %{$attrs};
    print "<td>$_</td>" for @_;
    end;
    print "\n";
}

sub th {
    my ($text, %attrs) = @_;
    start 'th', %attrs;
    print $text;
    end;
}

sub td {
    my ($text, %attrs) = @_;
    start 'td', %attrs;
    print $text;
    end;
}

sub anchor {
    my ($text, %attrs) = @_;
    start 'a', %attrs;
    print $text;
    end;
}

sub fail {
    my ($msg) = @_;
    print "Content-type: text/html\r\n\r\n";
    doctype;
    start 'html', xmlns => "http://www.w3.org/1999/xhtml";
    start 'head';
    tag 'meta', 'http-equiv' => "Content-Type",
                'content'    => "text/html; charset=utf-8";
    print "<title>FATE error</title>\n";
    end 'head';

    start 'body';
    h1 "FATE error", id => 'title';
    print "$msg\n";
    end 'body';
    end 'html';
    exit 1;
}

1;

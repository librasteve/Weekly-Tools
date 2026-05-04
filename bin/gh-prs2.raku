#!/usr/bin/env raku
use Cro::HTTP::Client;
use Air::Functional;
use Weekly::Tools::Nicks;

use Data::Dump::Tree;


my $week = DateTime.now - 7 * 24 * 60 * 60;
my %nicks = Authors.new.nicks;
my $token = %*ENV<GITHUB_TOKEN>;

my $client = Cro::HTTP::Client.new(
    headers => [Authorization => "Bearer $token"]
);

sub fetch($owner, $repo, $info) {
    my $api-url = "https://api.github.com/repos/$owner/$repo/$info";

    start {
        my $resp = $client.get($api-url,
            query => { :state<all> }
        ).result;

        $resp.body.result;
    }
}

sub do-list(@tuple) {
    my ($owner, $repo, $info) = @tuple;
    my @items = |await fetch(|@tuple);

    sub remap(%i) {
        my %r;

        #|url asis https://api.github.com/repos/Raku/problem-solving/issues/497
        #|url tobe https://github.com/Raku/problem-solving/issues/497
        sub fix($url is rw) {
            $url.=subst: / api\.     /, '';
            $url.=subst: / repos\/   /, '';
            $url.=subst: / pulls\/   /, 'pull/';
            $url.=subst: / commits\/ /, 'commit/';
#            say $url;
            $url;
        }

        given $info {
            when 'commits' {
                %r<created_at>  = %i<commit><committer><date>;
                %r<url>         = %i<url>.&fix;
                %r<title>       = %i<commit><message>.lines[0];
                %r<author>      = %i<commit><author><name>;
            }
            default {
                %r<created_at>  = %i<created_at>;
                %r<url>         = %i<url>.&fix;
                %r<title>       = %i<title>;
                %r<author>      = %i<user><login>;
            }
        }

        %r
    }

    my @lis;
    for @items -> %i {
        %i .= &remap;

        if %i<created_at>.DateTime > $week {
            my $byline = %nicks{%i<author>} // %i<author>;
            @lis.push: li [
                a :href(%i<url>), %i<title>;
                { span ' by '; em $byline; } unless $repo eq 'problem-solving';
            ];
        }
    }
    @lis
}

#   ($owner, $repo, $info)
my @tuples = [
    <Raku problem-solving issues>,
    <Raku raku.org pulls>,
    <Raku doc pulls>,
#    <MoarVM MoarVM pulls>,
#    <Raku nqp pulls>,
#    <rakudo rakudo pulls>,
#    <MoarVM MoarVM commits>,
#    <Raku nqp commits>,
#    <rakudo rakudo commits>,
];

my @headings = [
    ['New Problem Solving Issues',  1],
    ['New Doc & Web Pull Requests', 2],
#    ['Core Developments',           0],
];


my $html;

for @headings -> ($heading, $count) {
    my @lis;
    @lis.append: do-list(@tuples[$++]) for ^$count;
    if @lis {
        $html ~= h3($heading) ~ ul(@lis);
    }
}

print $html;


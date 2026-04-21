#!/usr/bin/env raku
use Cro::HTTP::Client;
use Air::Functional;
use Weekly::Tools::Nicks;

use Data::Dump::Tree;


my $week = DateTime.now - 7 * 24 * 60 * 60;

#github
my %authors = (
    'raku-community-modules' => 'Various Artistes',
    'l10n'          => 'Various Artistes',
    'FCO'           => 'Fernando Correa de Oliveira',
    'antononcube'   => 'Anton Antonov',
    'finanalyst'    => 'Richard Hainsworth',
    'librasteve'    => 'Steve Roe',
    'avuserow'      => 'Adrian Kreher',
    'lizmat'        => 'Elizabeth Mattijsen',
    'jjatria'       => 'JJ Atria',
    'wayland'       => 'Tim Nelson',
    'grizzlysmit'   => 'Francis Grizzly Smit',
    'melezhik'      => 'Alexey Melezhik',
    'dwarring'      => 'David Warring',
    'bduggan'       => 'Brian Duggan',
    'tony-o'        => 'Tony O\'Dell',
    'ingy'          => 'Ingy döt Net',
    'nkh'           => 'Nadim Khemir',
    'patrickbkr'    => 'Patrick Böker',
    'arunvickram'   => 'Arun Vickram',
    'kuerbis'       => 'Matthäus Kiem',
    'japhb'         => 'Geoffrey Broadwell',
    'ab5tract'      => 'John Longwalker',
    'arkiuat'       => 'Eric Forste',
    'tbrowder'      => 'Tom Browder',
    'martimm'       => 'Marcel Timmerman',
    'raiph'         => 'Ralph Mellor',
    'masterduke'    => 'Daniel Green',
    'nige123'       => 'Nigel Hamilton',
    'NINE'          => 'Stefan Seifert',
    'massa'         => 'Massa Humberto',
    'Raku'          => 'Core Mongers',
    'jubilatious1'  => 'William Michels',
    'schultzdavid'  => 'David Schultz',
    'timo'          => 'Timo Paulssen',
    'ShimmerFairy'  => 'ShimmerFairy',
    '0rir'          => '0rir',
    'coke'          => 'Will Coleda',
    'frou'          => 'Duncan Holm',
    '2colours'      => 'Márton Polgár',
    'dontlaugh'     => 'Coleman McFarlane',
    'm-doughty'     => 'Matt Doughty',
    '4zv4l'         => 'Alex Daniel',
    'AlexDaniel'    => 'Alex Daniel',
    'codesections'  => 'Daniel Sockwell',
    'jnthn'         => 'Jonathan Worthington',
    'ugexe'         => 'Nick Logan',
    'tyil'          => 'Patrick Spek',
    'niner'         => 'Stefan Seifert',
    'vrurg'         => 'Vadim Belman',
);

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

    ul [
        for @items -> %i {
#ddt %i if %i<url> ~~ / 9e25edce4fc4c3b8f6fb718777ca31bdded4c845 /;
            %i .= &remap;

            if %i<created_at>.DateTime > $week {
                my $byline = %nicks{%i<author>} // %i<author>;
#                my $byline = %authors{%i<author>} // %i<author>;
                li [
                    a :href(%i<url>), %i<title>;
                    { span ' by '; em $byline; } unless $repo eq 'problem-solving';
                ]
            }
        }
    ];
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
    $html ~= div [
        h3 $heading;
        div [do-list(@tuples[$++]) for ^$count];
    ];
}

say $html.trim;


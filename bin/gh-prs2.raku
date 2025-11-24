#!/usr/bin/env raku
use Cro::HTTP::Client;
use Air::Functional;

my $week = DateTime.now - 7 * 24 * 60 * 60;   # FIXME

my %authors = (
    'raku-community-modules' => 'Various Artistes',
    'l10n'        => 'Various Artistes',
    'FCO'         => 'Fernando Correa de Oliveira',
    'antononcube' => 'Anton Antonov',
    'finanalyst'  => 'Richard Hainsworth',
    'librasteve'  => 'Steve Roe',
    'avuserow'    => 'Adrian Kreher',
    'lizmat'      => 'Elizabeth Mattijsen',
    'jjatria'     => 'JJ Atria',
    'wayland'     => 'Tim Nelson',
    'grizzlysmit' => 'Francis Grizzly Smit',
    'melezhik'    => 'Alexey Melezhik',
    'dwarring'    => 'David Warring',
    'bduggan'     => 'Brian Duggan',
    'tony-o'      => 'Tony O\'Dell',
    'ingy'        => 'Ingy döt Net',
    'nkh'         => 'Nadim Khemir',
    'patrickbkr'  => 'Patrick Böker',
    'arunvickram' => 'Arun Vickram',
    'kuerbis'     => 'Matthäus Kiem',
    'japhb'       => 'Geoffrey Broadwell',
    'ab5tract'    => 'John Longwalker',
    'arkiuat'     => 'Eric Forste',
    'tbrowder'    => 'Tom Browder',
    'martimm'     => 'Marcel Timmerman',
    'raiph'       => 'Ralph Mellor',
    'masterduke'  => 'Daniel Green',
    'nige123'     => 'Nigel Hamilton',
    'NINE'        => 'Stefan Seifert',
    'massa'       => 'Massa Humberto',
    'Raku'        => 'Core Mongers',
    'jubilatious1' => 'jubilatious1',
    'schultzdavid' => 'David Schultz',
    'timo'        => 'timo',
);


# todos
# automate the following
# add commits
# pull not pulls on links

my $owner = 'rakudo';
#my $owner = 'MoarVM';
#my $owner = 'Raku';

my $repo  = 'rakudo';
#my $repo  = 'nqp';
#my $repo  = 'MoarVM';
#my $repo  = 'doc';
#my $repo  = 'problem-solving';

my $info  = 'commits';
#my $info  = 'pulls';
#my $info  = 'issues';
my $token = %*ENV<GITHUB_TOKEN>;

my $client = Cro::HTTP::Client.new(
    headers => [Authorization => "Bearer $token"]
);

my $api-url = "https://api.github.com/repos/$owner/$repo/$info";

sub fetch {
    start {
        my $resp = $client.get($api-url,
            query => { :state<all> }
        ).result;

        $resp.body.result;
    }
}

#|url asis https://api.github.com/repos/Raku/problem-solving/issues/497
#|url tobe https://github.com/Raku/problem-solving/issues/497
sub fix($url is rw) {
    $url.=subst: /api\./, '';
    $url.=subst: /repos\//, '';
    $url;
}

my @issues = |await fetch;
#say @issues[0].keys;

say ul [
    for @issues -> %i {
        if %i<created_at>.DateTime > $week {
            my $href = %i<url>.&fix;

            li [
                a :$href, %i<title>;
                ' by ';
                em %authors{%i<user><login>};
            ]
        }
    }
];

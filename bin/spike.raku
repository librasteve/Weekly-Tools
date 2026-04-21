#!/usr/bin/env raku
use Data::Dump::Tree;
use Hash::Merge;

sub out(%h) {
    my $w = 28;

    for %h.kv -> $k, $v {

        my $ko = "'{$k}'";
        my $kp = ~$ko.fmt("%-{$w}s");

        my @vo = $v.map({"'$_'"});
        my $vp = "[{@vo.join(', ')}]";

        my $res = "    {$kp} => {$vp},";

        say $res;
    }
}

sub inverta(%x) {
    my %h;
    for %x.kv -> $k, $v {
        %h{$v}.append: $k;
    }
    %h;
}

my %gh-authors = (
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

my %a-gh = %gh-authors.&inverta;


my %zef-authors = (
'zef:raku-community-modules' => 'Various Artistes',
'zef:l10n'        => 'Various Artistes',
'zef:FCO'         => 'Fernando Correa de Oliveira',
'zef:antononcube' => 'Anton Antonov',
'zef:finanalyst'  => 'Richard Hainsworth',
'zef:librasteve'  => 'Steve Roe',
'zef:avuserow'    => 'Adrian Kreher',
'zef:lizmat'      => 'Elizabeth Mattijsen',
'zef:jjatria'     => 'JJ Atria',
'zef:wayland'     => 'Tim Nelson',
'zef:grizzlysmit' => 'Francis Grizzly Smit',
'zef:melezhik'    => 'Alexey Melezhik',
'zef:dwarring'    => 'David Warring',
'zef:bduggan'     => 'Brian Duggan',
'zef:tony-o'      => 'Tony O\'Dell',
'zef:ingy'        => 'Ingy döt Net',
'github:nkh'      => 'Nadim Khemir',
'zef:nkh'         => 'Nadim Khemir',
'zef:patrickb'    => 'Patrick Böker',
'zef:arunvickram' => 'Arun Vickram',
'zef:kuerbis'     => 'Matthäus Kiem',
'zef:japhb'       => 'Geoffrey Broadwell',
'zef:ab5tract'    => 'John Longwalker',
'zef:arkiuat'     => 'Eric Forste',
'zef:tbrowder'    => 'Tom Browder',
'zef:martimm'     => 'Marcel Timmerman',
'zef:raiph'       => 'Ralph Mellor',
'zef:masterduke'  => 'Daniel Green',
'zef:nige123'     => 'Nigel Hamilton',
'cpan:NINE'       => 'Stefan Seifert',
'zef:massa'       => 'Massa Humberto',
'github:Raku'     => 'Core Mongers',
);

my %dezef-authors;
for %zef-authors.kv -> $k, $v {
    my $k2 = $k.split(':')[1];
    %dezef-authors{$k2} = $v;
}

my %a-zef = %dezef-authors.&inverta;

my %combo = merge-hash(%a-gh, %a-zef, :make-array, :unique);

for %combo.kv -> $k, $v is rw {

}

%combo.&out;
repl;
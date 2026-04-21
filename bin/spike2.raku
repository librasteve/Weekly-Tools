#!/usr/bin/env raku

#swap k <=> k
#strip zef, github, cpan
#combine
#real-name => nick // [list of nicks]
#junction zef, github, cpan

use Data::Dump::Tree;

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

sub evert(%x) {
    my %h;
    for %x.kv -> $k, @v {
        for @v -> $v {
            %h{$v}.append: $k[0];
        }
    }
    %h;
}


class Nicks {
    has %.authors = (
        'Anton Antonov' => ['antononcube'],
        'Timo Paulssen' => ['timo'],
        'Tom Browder' => ['tbrowder'],
        'Jonathan Worthington' => ['jnthn'],
        'Steve Roe' => ['librasteve'],
        'Patrick Böker' => ['patrickbkr', 'patrickb'],
        'ShimmerFairy' => ['ShimmerFairy'],
        'Alex Daniel' => ['AlexDaniel', '4zv4l'],
        'David Warring' => ['dwarring'],
        'Fernando Correa de Oliveira'=> ['FCO'],
        'David Schultz' => ['schultzdavid'],
        'Geoffrey Broadwell' => ['japhb'],
        'Elizabeth Mattijsen' => ['lizmat'],
        'Vadim Belman' => ['vrurg'],
        'Nadim Khemir' => ['nkh'],
        'JJ Atria' => ['jjatria'],
        'Nick Logan' => ['ugexe'],
        'Márton Polgár' => ['2colours'],
        '0rir' => ['0rir'],
        'Brian Duggan' => ['bduggan'],
        'Arun Vickram' => ['arunvickram'],
        'Tony O\'Dell' => ['tony-o'],
        'Various Artistes' => ['raku-community-modules', 'l10n'],
        'Adrian Kreher' => ['avuserow'],
        'Alexey Melezhik' => ['melezhik'],
        'Will Coleda' => ['coke'],
        'Ralph Mellor' => ['raiph'],
        'Daniel Sockwell' => ['codesections'],
        'Nigel Hamilton' => ['nige123'],
        'Eric Forste' => ['arkiuat'],
        'Patrick Spek' => ['tyil'],
        'Richard Hainsworth' => ['finanalyst'],
        'Francis Grizzly Smit' => ['grizzlysmit'],
        'Core Mongers' => ['Raku'],
        'Duncan Holm' => ['frou'],
        'John Longwalker' => ['ab5tract'],
        'Coleman McFarlane' => ['dontlaugh'],
        'Ingy döt Net' => ['ingy'],
        'Stefan Seifert' => ['niner', 'NINE'],
        'Daniel Green' => ['masterduke'],
        'Matthäus Kiem' => ['kuerbis'],
        'Marcel Timmerman' => ['martimm'],
        'Tim Nelson' => ['wayland'],
        'Massa Humberto' => ['massa'],
        'William Michels' => ['jubilatious1'],
        'Matt Doughty' => ['m-doughty'],
    );
    has %.nicks;

    submethod TWEAK {
        %!nicks = %!authors.&evert;
    }
}

my $n = Nicks.new;

$n.authors.&out;
say '============';
$n.nicks.&out;

repl;


unit module Nicks;

multi sub combine(Hash \a, \b --> Hash()) is export {
    (a.keys ∪ b.keys).keys
        .map: -> $k {
        $k =>
            (a{$k}:exists) && (b{$k}:exists)
            ?? combine(a{$k}, b{$k})
            !! a{$k} // b{$k}
    }
}
multi sub combine(\a, \b --> Array()) is export {
    (|a, |b).unique
}

# add recursion & arrays
sub evert(%x) is export {
    my %h;
    for %x.kv -> $k, $v {
        for $v.unique -> $v {
            %h{$v} = $k;
        }
    }
    %h;
}

class Authors is export {
    has %.authors = (
        'Anton Antonov'         => ['antononcube'],
        'Timo Paulssen'         => ['timo'],
        'Tom Browder'           => ['tbrowder'],
        'Jonathan Worthington'  => ['jnthn'],
        'Steve Roe'             => ['librasteve'],
        'Patrick Böker'         => ['patrickbkr', 'patrickb'],
        'ShimmerFairy'          => ['ShimmerFairy'],
        'Alex Daniel'           => ['AlexDaniel', '4zv4l'],
        'David Warring'         => ['dwarring'],
        'Fernando Correa de Oliveira' => ['FCO'],
        'David Schultz'         => ['schultzdavid'],
        'Geoffrey Broadwell'    => ['japhb'],
        'Elizabeth Mattijsen'   => ['lizmat'],
        'Vadim Belman'          => ['vrurg'],
        'Nadim Khemir'          => ['nkh'],
        'JJ Atria'              => ['jjatria'],
        'Nick Logan'            => ['ugexe'],
        'Márton Polgár'         => ['2colours'],
        '0rir'                  => ['0rir'],
        'Brian Duggan'          => ['bduggan'],
        'Arun Vickram'          => ['arunvickram'],
        'Tony O\'Dell'          => ['tony-o'],
        'Various Artistes'      => ['raku-community-modules', 'l10n'],
        'Adrian Kreher'         => ['avuserow'],
        'Alexey Melezhik'       => ['melezhik'],
        'Will Coleda'           => ['coke'],
        'Ralph Mellor'          => ['raiph'],
        'Daniel Sockwell'       => ['codesections'],
        'Nigel Hamilton'        => ['nige123'],
        'Eric Forste'           => ['arkiuat'],
        'Patrick Spek'          => ['tyil'],
        'Richard Hainsworth'    => ['finanalyst'],
        'Francis Grizzly Smit'  => ['grizzlysmit'],
        'Core Mongers'          => ['Raku'],
        'Duncan Holm'           => ['frou'],
        'John Longwalker'       => ['ab5tract'],
        'Coleman McFarlane'     => ['dontlaugh'],
        'Ingy döt Net'          => ['ingy'],
        'Stefan Seifert'        => ['niner', 'NINE'],
        'Daniel Green'          => ['masterduke'],
        'Matthäus Kiem'         => ['kuerbis'],
        'Marcel Timmerman'      => ['martimm'],
        'Tim Nelson'            => ['wayland'],
        'Massa Humberto'        => ['massa'],
        'William Michels'       => ['jubilatious1'],
        'Matt Doughty'          => ['m-doughty', 'apogee'],
        'Wenzel P. P. Peppmeyer'=> ['gfldex'],
        'Zoltan Ness'           => ['Z-raku'],
        'ccmywish'              => ['ccmywish'],
    );

    has %.nicks;
    has %.fezzn;

    method TWEAK {
        %!nicks = %!authors.&evert;

        for %!nicks.kv -> $k, $v {
            %!fezzn{"zef:$k"} = $v;
            %!fezzn{"cpan:$k"} = $v;
            %!fezzn{"github:$k"} = $v;
        }
    }
}
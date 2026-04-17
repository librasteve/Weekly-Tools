use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

my %authors = (
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

# version and datetime indexes
my $aut = 2;
my $vsi = 3;
my $dti = 5;

sub fetch-table-data($url) {
    start {
        my $resp = await Cro::HTTP::Client.get($url);
        my $html = await $resp.body-text;
        my $dom  = DOM::Tiny.parse($html);
        my $table = $dom.at('table');

        my @rows;
        for $table.find('tr') -> $tr {
            my @cells;
            for $tr.find('th, td') -> $cell {
                if my $a = $cell.at('a') {
                    @cells.push: $a.text.trim;
                    @cells.push: "https://raku.land" ~ $a<href>;
                    $a<href> ~~ /^ \/ (<-[\/]>+) /;
                    @cells.push: %authors{~$0} // ~$0;
                } elsif my $t = $cell.at('time') {
                    @cells.push: $t<datetime>.DateTime;
                } elsif my $v = $cell.text.trim ~~ /^ \d+ \. \d+ \. \d+ $/  {    # parse "0.2.2" etc.
                    @cells.push: $v.Version;
                } else {
                    @cells.push($cell.text.trim);
                }
            }
            @rows.push(@cells) if @cells;
        }
        @rows;
    }
}

sub output-table-data(@rows, :$HTML=1) {
    if !$HTML {
        for @rows -> @cells {
            say "@cells[0] by @cells[2].";
        }
    }

    if $HTML {
        for @rows -> @cells {
            say (
                li [ a(:href(@cells[1]), @cells[0]), safe(' by '), em(@cells[2]), safe('.') ]
            )
        }
    }
}

sub output-hash-data(%hash, :$HTML=1) {
    if !$HTML {
        for %hash.kv -> $author, @items {
            say @items.map(*[0]).join(', ') ~ ' by ' ~ $author,
        }
    }

    if $HTML {
        say ul do for %hash.kv -> $author, @items {
            given @items.map( {a(:href(.[1]), .[0]).HTML } ).join(',') {
                li safe( $_ ~ ' by ' ~ em $author );
            }
        }
    }
}

my $url = 'https://raku.land/recent';
react {
    whenever fetch-table-data($url) -> @rows {
        if @rows {
            my $week = DateTime.now - 7 * 24 * 60 * 60;

            my @head = @rows.shift;
            my @recent = @rows.grep: { @^row[$dti] > $week }

            my %by-module;
            for @recent -> @row {
                my $name    = @row[0];
                my $stored  = %by-module{$name};

                my Version() $version = @row[$vsi];
                my Version() $v-stored = $stored[$vsi] // '';

                if !$stored.defined {
                    %by-module{$name} = @row;
                }
                elsif $version > $v-stored {
                    %by-module{$name} = @row;         # keep only the highest version
                }
            }
            my @latest = %by-module.values;

            my %by-author;
            for @latest -> @row {
                my $author = @row[$aut];
                %by-author{$author}.push: @row;
            }

            output-hash-data %by-author;

            for @latest -> @cells {
                say @cells[0] ~ ': ' ~ @cells[3] if @cells[$vsi] < v0.0.10
            }

#            my @sorted = @latest.sort: { $^b[$dti] <=> $^a[$dti] };
#            output-table-data @sorted;

        } else {
            say "No table found at $url";
        }
        exit;
    }
}
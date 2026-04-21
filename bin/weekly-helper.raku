#!/usr/bin/env raku
use Cro::HTTP::Client;

my @new-names;

### Part I - Get and Save https://360.zef.pm

use JSON::Fast;
use Data::Dump::Tree;

my $date = Date.today;
my $dir = "../data";

sub fetch-dists-json($url = 'https://360.zef.pm') {
    start {
        my $resp = await Cro::HTTP::Client.get($url);
        my $body = await $resp.body-text;
        $body;
    }
}

sub save-this($body) {
    my $max = 0;
    for dir($dir) -> $file {
        if $file.basename ~~ /^ 'dists-' $date '-' (\d**3) $/ {
            $max max= +$0;
        }
    }
    my $filename = sprintf("%s-%s-%03d", 'dists', $date, $max+1);
    say "Saving $filename";
    spurt "$dir/$filename", $body;
}

sub prev-body {
    my @files = dir($dir).grep({
        .basename ~~ /^ 'dists-' \d**4 '-' \d**2 '-' \d**2 '-' \d**3 $/
    });

    my $file = @files.sort(*.basename)[*-2];
    say "Loading $file";
    slurp $file;
}

sub get-data($body, :$key) {
    my @raku = $body.&from-json;
    #say @raku.head.keys.sort;

    @raku.map({ .{$key} }).unique;
}

react {
    whenever fetch-dists-json() -> $this-body {
        save-this $this-body;

        say my @this-names = $this-body.&get-data(:key<name>);
        my @prev-names = prev-body().&get-data(:key<name>);

        @new-names = (@this-names (-) @prev-names).keys;
    }
}


### Part II - Get and Process https://raku.land/recent

use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

#zef
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

my %fezzn = Authors.new.fezzn;

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
                    @cells.push: %fezzn{~$0} // ~$0;
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
        say @new-names;

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


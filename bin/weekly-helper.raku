use v6.d;
use Cro::HTTP::Client;
use DOM::Tiny;
use Data::Dump::Tree;
use Air::Functional :BASE;
use Air::Base;

my %authors = ( 
    'zef:FCO'         => 'Fernando Correa de Oliveira',
    'zef:antononcube' => 'Anton Antonov',
    'zef:finanalyst'  => 'Richard Hainsworth',
    'zef:librasteve'  => 'Steve Roe',
    'zef:l10n'        => 'Various Artists',
    'zef:raku-community-modules' => 'Various Artists',
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

#`[
<ul class="wp-block-list">
<li><a href="https://raku.land/zef:lizmat/SBOM::CycloneDX">SBOM::CycloneDX</a>,  <a href="https://raku.land/zef:lizmat/Trap">Trap</a>, <a href="https://raku.land/zef:lizmat/Test::Output">Test::Output</a>, <a href="https://raku.land/zef:lizmat/SBOM::Raku">SBOM::Raku</a> by <em>Elizabeth Mattijsen.</em></li>
<li><a href="https://raku.land/zef:FCO/Red">Red</a> by <em>Fernando Correa de Oliveira</em>.</li>
<li><a href="https://raku.land/zef:avuserow/Audio::TagLib">Audio::TagLib</a> by <em>Adrian Kreher</em>.</li>
<li><a href="https://raku.land/zef:l10n/L10N">L10N</a>, <a href="https://raku.land/zef:raku-community-modules/OpenSSL">OpenSSL</a> by <em>Various Artists</em>.</li>
<li><a href="https://raku.land/zef:librasteve/Physics::Unit">Physics::Unit</a>, <a href="https://raku.land/zef:librasteve/Physics::Measure">Physics::Measure</a>, <a href="https://raku.land/zef:librasteve/App::Crag">App::Crag</a> by <em>Steve Roe</em>.</li>
<li><a href="https://raku.land/zef:finanalyst/Elucid8::Build">Elucid8::Build</a> by <em>Richard Hainsworth</em>.</li>
<li><a href="https://raku.land/zef:antononcube/Graph">Graph</a>, <a href="https://raku.land/zef:antononcube/LLM::Functions">LLM::Functions</a> by <em>Anton Antonov</em>.</li>
</ul>
#]

sub output-table-data(@rows) {

    my $as = 'text';

    if $as eq 'text' {
        for @rows -> @cells {
            say "@cells[0] by @cells[2].";
        }
    }

    if $as eq 'HTML' {
        for @rows -> @cells {

            sub HTML {
                ul li [ a(:href(@cells[1]), @cells[0]), safe(' by '), em(@cells[2]), safe('.') ];
            }

            print HTML;
        }
    }
}

sub output-hash-data(%hash) {

#    my $as = 'HTML';
    my $as = 'text';

    if $as eq 'text' {
        for %hash.kv -> $author, @items {
            say @items.map(*[0]).join(', ') ~ ' by ' ~ $author,
        }
    }

    if $as eq 'HTML' {
        for %hash.kv -> $author, @items {

            my @anchors;
            for @items -> @cells {
                @anchors.push: a(:href(@cells[1]), @cells[0]);
            }

            say @anchors;

#            sub HTML {
#                ul li [ a(:href(@cells[1]), @cells[0]), safe(' by '), em(@cells[2]), safe('.') ];
#            }
#
#            print HTML;

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
                my $version = @row[$vsi];   
                my $stored  = %by-module{$name};

                if !$stored.defined || $version > $stored[$vsi] {
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

#            ddt %by-author{'Steve Roe'};

#            my @sorted = @latest.sort: { $^b[$dti] <=> $^a[$dti] };
#
#            output-table-data @sorted;

        } else {
            say "No table found at $url";
        }
        exit;
    }
}


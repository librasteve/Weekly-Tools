unit module Weekly::Tools::RakuLand;

use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

my $aut = 2;
my $vsi = 3;
my $dti = 5;

sub fetch-table-data($url) {
    my %fezzn = Authors.new.fezzn;
    start {
        my $resp  = await Cro::HTTP::Client.get($url);
        my $dom   = DOM::Tiny.parse(await $resp.body-text);
        my $table = $dom.at('table');
        my @rows;
        for $table.find('tr') -> $tr {
            next if $tr.at('th');
            my @cells;
            for $tr.find('td') -> $cell {
                if my $a = $cell.at('a') {
                    @cells.push: $a.text.trim;
                    @cells.push: "https://raku.land" ~ $a<href>;
                    $a<href> ~~ /^ \/ (<-[\/]>+) /;
                    @cells.push: %fezzn{~$0} // ~$0;
                } elsif my $t = $cell.at('time') {
                    @cells.push: $t<datetime>.DateTime;
                } elsif my $v = $cell.text.trim ~~ /^ \d+ \. \d+ \. \d+ $/ {
                    @cells.push: $v.Version;
                } else {
                    @cells.push: $cell.text.trim;
                }
            }
            @rows.push: @cells if @cells;
        }
        @rows;
    }
}

sub output-hash-data(%hash) {
    print ul do for %hash.kv -> $author, @items {
        given @items.map( { a(:href(.[1]), .[0]).HTML } ).join(', ') {
            li safe( $_ ~ ' by ' ~ em $author );
        }
    }
}

sub render-rakuland($new-names, :$prev-filename, :$latest-filename) is export {
    my $url = 'https://raku.land/recent';
    react {
        my $p1 = fetch-table-data($url);
        my $p2 = fetch-table-data("$url?page=2");
        whenever Promise.allof($p1, $p2) {
            my @rows = |$p1.result, |$p2.result;
            print "\n<!-- Compared $prev-filename to $latest-filename -->";
            my $week = DateTime.now - 7 * 24 * 60 * 60;
            my @recent = @rows.grep: { @^row[$dti] > $week };

            my %by-module;
            for @recent -> @row {
                my $name            = @row[0];
                my Version() $ver   = @row[$vsi];
                my Version() $v-cur = %by-module{$name}[$vsi] // '';
                %by-module{$name}   = @row if !%by-module{$name} || $ver > $v-cur;
            }

            my (%new, %updated);
            for %by-module.values -> @row {
                my $author = @row[$aut];
                if @row[0] ∈ $new-names { %new{$author}.push:     @row }
                else                    { %updated{$author}.push: @row }
            }


            if %new     { print h3 'New Modules';     output-hash-data %new     }
            if %updated { print h3 'Updated Modules'; output-hash-data %updated }
        }
    }
}

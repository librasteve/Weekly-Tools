#!/usr/bin/env raku
use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;


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

        } else {
            say "No table found at $url";
        }
        exit;
    }
}


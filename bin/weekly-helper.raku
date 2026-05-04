#!/usr/bin/env raku
use Cro::HTTP::Client;

my @new-names;
my ($prev-filename, $latest-filename);

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
    note "Saving dists-$date";
    spurt "$dir/dists-$date", $body;
    "dists-$date"
}

sub prev-body {
    my $target = Date.today - 7;
    my @files = dir($dir).grep({
        .basename ~~ /^ 'dists-' (\d**4 '-' \d**2 '-' \d**2) $/
        && abs(Date.new(~$0) - $target) <= 2
    });

    my $file = @files.sort({ abs(Date.new(.basename.substr(6)) - $target) }).head;
    note "Loading $file";
    (slurp($file), $file.basename)
}

sub get-data($body, :$key) {
    my @raku = $body.&from-json;
    @raku.map({ .{$key} }).unique;
}

sub process-dists($body) {
    my @this-names = $body.&get-data(:key<name>);
    my ($prev-body-text, $pf) = prev-body();
    $prev-filename = $pf;
    my @prev-names = $prev-body-text.&get-data(:key<name>);
    @new-names = (@this-names (-) @prev-names).keys;
}

my $today-path = "$dir/dists-$date";
if $today-path.IO.e && (now - $today-path.IO.modified) < 3600 {
    note "Using cached dists-$date (updated within last hour)";
    $latest-filename = "dists-$date";
    process-dists slurp($today-path);
} else {
    react {
        whenever fetch-dists-json() -> $this-body {
            $latest-filename = save-this $this-body;
            process-dists $this-body;
        }
    }
}


### Part II - Get and Process https://raku.land/recent

use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

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
        print ul do for %hash.kv -> $author, @items {
            given @items.map( {a(:href(.[1]), .[0]).HTML } ).join(',') {
                li safe( $_ ~ ' by ' ~ em $author );
            }
        }
    }
}

my $url = 'https://raku.land/recent';
react {
    whenever fetch-table-data($url) -> @rows {
        print "<!-- Compared $prev-filename to $latest-filename -->";
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

            my %by-author-new;
            my %by-author-updated;
            for @latest -> @row {
                my $author = @row[$aut];
                if @row[0] ∈ @new-names {
                    %by-author-new{$author}.push: @row;
                } else {
                    %by-author-updated{$author}.push: @row;
                }
            }

            if %by-author-new {
                print h3 'New Modules';
                output-hash-data %by-author-new;
            }

            if %by-author-updated {
                print h3 'Updated Modules';
                output-hash-data %by-author-updated;
            }

#            # rough way to check new list
#            for @latest -> @cells {
#                say @cells[0] ~ ': ' ~ @cells[3] if (@cells[$vsi] cmp v0.0.10) ~~ Less
#            }

        } else {
            note "No table found at $url";
        }
        exit;
    }
}


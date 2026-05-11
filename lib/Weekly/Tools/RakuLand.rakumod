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

sub render-rakuland(@new-names, :$prev-filename, :$latest-filename) is export {
    my $url = 'https://raku.land/recent';
    react {
        my $p1 = fetch-table-data($url);
        my $p2 = fetch-table-data("$url?page=2");
        whenever Promise.allof($p1, $p2) {
            my @rows = |$p1.result, |$p2.result;
            print "<!-- Compared $prev-filename to $latest-filename -->";
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
                if @row[0] ∈ @new-names { %new{$author}.push:     @row }
                else                    { %updated{$author}.push: @row }
            }

            if %new     { print h3 'New Modules';     output-hash-data %new     }
            if %updated { print h3 'Updated Modules'; output-hash-data %updated }
        }
    }
}

sub render-github(@tuples, @headings) is export {
    my %nicks  = Authors.new.nicks;
    my $week   = DateTime.now - 7 * 24 * 60 * 60;
    my $token  = %*ENV<GITHUB_TOKEN>;
    my $client = Cro::HTTP::Client.new(
        headers => [Authorization => "Bearer $token"]
    );

    sub fetch($owner, $repo, $info) {
        my $url = "https://api.github.com/repos/$owner/$repo/$info";
        start { $client.get($url, query => { :state<all> }).result.body.result }
    }

    sub fix($url is rw) {
        $url.=subst: / api\.     /, '';
        $url.=subst: / repos\/   /, '';
        $url.=subst: / pulls\/   /, 'pull/';
        $url.=subst: / commits\/ /, 'commit/';
        $url
    }

    sub remap(%i, $info) {
        $info eq 'commits'
            ?? { created_at => %i<commit><committer><date>,
                 url        => %i<url>.&fix,
                 title      => %i<commit><message>.lines[0],
                 author     => %i<commit><author><name> }
            !! { created_at => %i<created_at>,
                 url        => %i<url>.&fix,
                 title      => %i<title>,
                 author     => %i<user><login> }
    }

    sub do-list(@tuple) {
        my ($owner, $repo, $info) = @tuple;
        my @items = |await fetch(|@tuple);
        my @lis;
        for @items -> %i {
            my %r = remap(%i, $info);
            if %r<created_at>.DateTime > $week {
                my $byline = %nicks{%r<author>} // %r<author>;
                @lis.push: li [
                    a(:href(%r<url>), %r<title>),
                    ({ span ' by '; em $byline; } unless $repo eq 'problem-solving'),
                ];
            }
        }
        @lis
    }

    my $i = 0;
    my $html;
    for @headings -> ($heading, $count) {
        my @lis;
        @lis.append: do-list(@tuples[$i++]) for ^$count;
        $html ~= h3($heading) ~ ul(@lis) if @lis;
    }
    print $html;
}

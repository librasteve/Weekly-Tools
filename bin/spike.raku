#!/usr/bin/env raku
use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

use JSON::Fast;
use Data::Dump::Tree;

my $date = Date.today;
my $dir = "../data";

sub save-body($body) {
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

sub previous-body {
    my @files = dir($dir).grep({
        .basename ~~ /^ 'dists-' \d**4 '-' \d**2 '-' \d**2 '-' \d**3 $/
    });

    my $file = @files.sort(*.basename)[*-2];
    say "Loading $file";
    slurp $file;
}

sub fetch-dists($url = 'https://360.zef.pm') {
    start {
        my $resp = await Cro::HTTP::Client.get($url);
        my $body = await $resp.body-text;
        $body;
    }
}


react {
    whenever fetch-dists() -> $body {
        save-body $body;

        my @raku = $body.&from-json;

#        @raku = previous-body.&from-json;   #iamerejh

        say @raku.head.keys.sort;

        my %dists;

        for @raku -> $item {
            my $name = $item<name>;
            %dists{$name} = 1
        }

        say %dists.keys;
        say +%dists.keys;
        repl;

        exit;
    }
}


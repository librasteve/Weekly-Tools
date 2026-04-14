#!/usr/bin/env raku
use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

use JSON::Fast;
use Data::Dump::Tree;


my $path = "../data";
my $dist-file = "$path/dists-last.txt";

sub fetch-table-data($url) {
    start {
        my $resp = await Cro::HTTP::Client.get($url);
        my $json = await $resp.body-text;
        $json.&from-json
    }
}


my $url = 'https://360.zef.pm';

react {
    whenever fetch-table-data($url) -> $raku {
        my %dists;

        for |$raku -> $item {
            my $name = $item<dist>.split(':ver')[0];
            %dists{$name} = 1
        }


        repl;

        say %dists.keys;
        say +%dists.keys;

        spurt $dist-file, %dists.&to-json;

        my %dists-last = (slurp $dist-file).&from-json;

        repl;

        exit;
    }
}

#`[
thoughts
  - use 360 throughout
  - store as JSON (ie HTML)
  - need to store all 360 as json (not just the dist keys)
]




#!/usr/bin/env raku
use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

use JSON::Fast;
use Data::Dump::Tree;

my $date = Date.today;
my $dir = "../data";

sub next-filename {
    my $max = 0;
    for dir($dir) -> $file {
        if $file.basename ~~ /^ 'dists-' $date '-' (\d**3) $/ {
            $max max= +$0;
        }
    }
    sprintf("%s-%s-%03d", 'dists', $date, $max+1);
}

#my $filename = next-filename();
#spurt "$dir/$filename", "<html>some content</html>";
#
#say "Saved to $filename";

sub latest-file {
    my @files = dir($dir).grep({
        .basename ~~ /^ 'dists-' \d**4 '-' \d**2 '-' \d**2 '-' \d**3 $/
    });
    @files.sort(*.basename).tail;
}

my $file = latest-file();
my $content = slurp $file;
say "Loaded $file:";
say $content;


#sub fetch-table-data($url) {
#    start {
#        my $resp = await Cro::HTTP::Client.get($url);
#        return await $resp.body-text;
#    }
#}
#
#
#my $url = 'https://360.zef.pm';
#
#my $dist-file = "$path/dists-$dt.txt";
#
#react {
#    whenever fetch-table-data($url) -> $body {
#        spurt $dist-file, $body;
#
#        my $raku = $body.&from-json;
#
#
#
#        my %dists;
#
#        for |$raku -> $item {
#            my $name = $item<dist>.split(':ver')[0];
#            %dists{$name} = 1
#        }
#
#
#        repl;
#
#        say %dists.keys;
#        say +%dists.keys;
#
#        spurt $dist-file, %dists.&to-json;
#
#        my %dists-last = (slurp $dist-file).&from-json;
#
#        repl;
#
#        exit;
#    }
#}

#`[
thoughts
  - use 360 throughout
  - store as JSON (ie HTML)
  - need to store all 360 as json (not just the dist keys)
]




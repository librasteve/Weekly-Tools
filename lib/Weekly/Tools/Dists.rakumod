unit module Weekly::Tools::Dists;

use Cro::HTTP::Client;
use JSON::Fast;

my $dir = "data";

sub get-data($body, :$key) {
    $body.&from-json.map({ .{$key} }).unique;
}

sub prev-body() {
    my $target = Date.today - 7;
    my @files = dir($dir).grep({
        .basename ~~ /^ 'dists-' (\d**4 '-' \d**2 '-' \d**2) $/
        && abs(Date.new(~$0) - $target) <= 2
    });
    my $file = @files.sort({ abs(Date.new(.basename.substr(6)) - $target) }).head;
    note "Loading $file";
    (slurp($file), $file.basename)
}

sub load-dists() is export {
    my $date       = Date.today;
    my $today-path = "$dir/dists-$date";
    my ($latest-filename, $prev-filename, @new-names);

    sub process($body) {
        my @this-names = $body.&get-data(:key<name>);
        my ($prev-text, $pf) = prev-body();
        $prev-filename = $pf;
        my @prev-names = $prev-text.&get-data(:key<name>);
        @new-names = (@this-names (-) @prev-names).keys;
    }

    if $today-path.IO.e && (now - $today-path.IO.modified) < 3600 {
        note "Using cached dists-$date (updated within last hour)";
        $latest-filename = "dists-$date";
        process slurp($today-path);
    } else {
        react {
            whenever (start {
                my $resp = await Cro::HTTP::Client.get('https://360.zef.pm');
                await $resp.body-text;
            }) -> $body {
                note "Saving dists-$date";
                spurt $today-path, $body;
                $latest-filename = "dists-$date";
                process $body;
            }
        }
    }

    (@new-names, $prev-filename, $latest-filename)
}

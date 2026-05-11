unit module Weekly::Tools::GitHub;

use Cro::HTTP::Client;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

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

    sub fix($url is copy) {
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

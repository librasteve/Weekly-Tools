#!/usr/bin/env raku
use lib '.';
use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

my $week = DateTime.now - 7 * 24 * 60 * 60;

react {
    whenever (start {
        my $resp = await Cro::HTTP::Client.get(
            'https://stackoverflow.com/questions/tagged/raku',
            query   => { tab => 'Newest' },
            headers => [ User-Agent => 'Mozilla/5.0' ],
        );
        await $resp.body-text
    }) -> $html {
        my $dom  = DOM::Tiny.parse($html);
        my @lis;

        for $dom.find('div.s-post-summary') -> $q {
            my $rel = $q.at('span.relativetime') or next;
            my $dt  = DateTime.new((~$rel<title>).subst(' ', 'T'));
            next if $dt < $week;

            my $a       = $q.at('h3 a') or next;
            my $url     = 'https://stackoverflow.com' ~ ~$a<href>;
            my $title   = $a.text.trim;
            my $excerpt = do with $q.at('div.s-post-summary--content-excerpt') { .text.trim } else { '' };
            my $author  = do with $q.at('a[itemprop="url"] span[itemprop="name"]') { .text.trim } else { '' };

            @lis.push: li [ a(:href($url), $title), ' — ', $excerpt, ' by ', em($author) ];
        }

        print ul(@lis) if @lis;
    }
}

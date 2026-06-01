#!/usr/bin/env raku
use lib '.';
use Cro::HTTP::Client;
use JSON::Fast;
use Air::Functional :BASE;
use Air::Base;

sub decode-html(Str $text) {
    $text
        .subst(/ '<' <-[>]>* '>' /, '', :g)
        .subst('&amp;',  '&',  :g)
        .subst('&lt;',   '<',  :g)
        .subst('&gt;',   '>',  :g)
        .subst('&quot;', '"',  :g)
        .subst('&#x27;', "'",  :g)
        .subst('&#x2F;', '/',  :g)
        .subst('&nbsp;', ' ',  :g)
        .subst('&#39;',  "'",  :g)
}

sub snippet(Str $text, Int $len = 20) {
    my @words = $text.words;
    return '' unless @words;
    @words.head($len).join(' ') ~ (@words > $len ?? '…' !! '')
}

my $end   = DateTime.now.posix.Int;
my $start = $end - 7 * 24 * 60 * 60;

my $url = "https://mastodon.social/api/v1/timelines/tag/rakulang?limit=40";

react {
    whenever (start {
        my $resp = await Cro::HTTP::Client.get($url);
        from-json await $resp.body-text;
    }) -> $data {
        my @posts = |$data;

        my @recent = @posts.grep: -> %p {
            DateTime.new(%p<created_at>).posix > $start
        };

        my @lis = @recent.map: -> %p {
            my $text   = decode-html(%p<content> // '');
            my $snip   = snippet($text);
            my $url    = %p<url>;
            my $author = %p<account><display_name> || %p<account><acct>;
            li [ a(:href($url), $snip), ' by ', em($author) ];
        };

        print ul(@lis) if @lis;
    }
}

#!/usr/bin/env raku
use lib '.';
use Cro::HTTP::Client;
use JSON::Fast;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

sub decode-html(Str $text) {
    $text
        .subst(/ '<' <-[>]>* '>' /, '', :g)
        .subst('&amp;',  '&',  :g)
        .subst('&lt;',   '<',  :g)
        .subst('&gt;',   '>',  :g)
        .subst('&quot;', '"',  :g)
        .subst('&#x27;', "'",  :g)
        .subst('&#x2F;', '/',  :g)
        .subst('&#x60;', '`',  :g)
        .subst('&nbsp;', ' ',  :g)
        .subst('&#39;',  "'",  :g)
}

sub snippet(Str $text) {
    my $clean     = $text.subst(/ 'http' 's'? '://' \S+ /, '[url]', :g);
    my @words     = $clean.words;
    return ''     unless @words;
    my $m         = $clean ~~ m:i/ << raku >> /;
    my $raku-pos  = $m ?? $m.from !! 0;
    my $raku-idx  = $clean.substr(0, $raku-pos).words.elems;
    my $before    = min(10, $raku-idx);
    my $s         = $raku-idx - $before;
    my $e         = min($s + 19, @words.end);
    my $out       = @words[$s .. $e].join(' ');
    $out = '…' ~ $out if $s > 0;
    $out ~= '…'       if $e < @words.end;
    $out
}

my %nicks = Authors.new.nicks;

my $end   = DateTime.now.posix.Int;
my $start = $end - 7 * 24 * 60 * 60;

my $url = "https://hn.algolia.com/api/v1/search_by_date"
        ~ "?query=raku&tags=comment"
        ~ "&numericFilters=created_at_i>{$start},created_at_i<{$end}"
        ~ "&hitsPerPage=1000";

react {
    whenever (start {
        my $resp = await Cro::HTTP::Client.get($url);
        from-json await $resp.body-text;
    }) -> %data {
        my @hits = |%data<hits>;

        my @relevant = @hits.grep: -> %h {
            my $text  = decode-html(%h<comment_text> // '');
            my $title = %h<story_title> // '';
            $text  ~~ m:i/ << raku >> /
            || $title ~~ m:i/ << raku >> /
        };

        my %seen;
        my @stories = @relevant.grep: -> %h { !%seen{%h<story_id>}++ };

        my @lis = @stories.map: -> %h {
            my $comment-url = "https://news.ycombinator.com/item?id={%h<objectID>}";
            my $snippet     = snippet(decode-html(%h<comment_text> // ''));
            my $author      = %nicks{%h<author>} // %h<author>;

            li [ a(:href($comment-url), $snippet), ' by ', em($author) ];
        };

        print ul(@lis) if @lis;
    }
}

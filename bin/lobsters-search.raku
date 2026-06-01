#!/usr/bin/env raku
use lib '.';
use Cro::HTTP::Client;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

my %nicks = Authors.new.nicks;
my $week  = DateTime.now - 7 * 24 * 60 * 60;

sub strip-tags(Str $html) {
    $html.subst(/ '<' <-[>]>* '>' /, ' ', :g).subst(/\s+/, ' ', :g).trim
}

sub snippet(Str $text) {
    my $clean    = $text.subst(/ 'http' 's'? '://' \S+ /, '', :g);
    my @words    = $clean.words;
    return ''    unless @words;
    my $m        = $clean ~~ m:i/ << raku >> /;
    return @words.head(20).join(' ') ~ '…' unless $m;
    my $raku-idx = $clean.substr(0, $m.from).words.elems;
    my $s        = max(0, $raku-idx - 8);
    my $e        = min($s + 19, @words.end);
    my $out      = @words[$s .. $e].join(' ');
    $out = '…' ~ $out if $s > 0;
    $out ~= '…'       if $e < @words.end;
    $out
}

react {
    whenever (start {
        my $resp = await Cro::HTTP::Client.get(
            'https://lobste.rs/search',
            query   => { q => 'raku', what => 'comments', order => 'newest' },
            headers => [ User-Agent => 'Mozilla/5.0' ],
        );
        await $resp.body-text
    }) -> $html {
        my $dom  = DOM::Tiny.parse($html);
        my @lis;

        for $dom.find('div.comment') -> $c {
            my $time-link = $c.at('a[href^="/c/"]') or next;
            my $time-el   = $time-link.at('time')   or next;
            my $dt = DateTime.new((~$time-el<datetime>).subst(' ', 'T') ~ 'Z');
            next if $dt < $week;

            my $comment-url = 'https://lobste.rs' ~ ~$time-link<href>;

            my $author-node = $c.find('a[href^="/~"]').grep(*.text.trim).first or next;
            my $author      = %nicks{$author-node.text.trim} // $author-node.text.trim;

            my $story       = $c.at('a[href^="/s/"]') or next;
            my $story-url   = 'https://lobste.rs' ~ ~$story<href>;
            my $story-title = $story.text.trim;

            my $snip = do with $c.at('div.comment_text') { snippet(strip-tags(~$_)) } else { '' };

            @lis.push: li [ a(:href($comment-url), $story-title), ' — ', $snip, ' by ', em($author) ];
        }

        print ul(@lis) if @lis;
    }
}

#!/usr/bin/env raku
use lib '.';
use Cro::HTTP::Client;
use JSON::Fast;
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;
use Weekly::Tools::Nicks;

# --- shared helpers ---

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

sub snippet(Str $text, Int $len = 20) {
    my @words = $text.words;
    return '' unless @words;
    @words.head($len).join(' ') ~ (@words > $len ?? '…' !! '')
}

sub strip-tags(Str $html) {
    $html.subst(/ '<' <-[>]>* '>' /, ' ', :g).subst(/\s+/, ' ', :g).trim
}

sub lobsters-snippet(Str $text) {
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

sub hn-snippet(Str $text) {
    my $clean    = $text.subst(/ 'http' 's'? '://' \S+ /, '[url]', :g);
    my @words    = $clean.words;
    return ''    unless @words;
    my $m        = $clean ~~ m:i/ << raku >> /;
    my $raku-pos = $m ?? $m.from !! 0;
    my $raku-idx = $clean.substr(0, $raku-pos).words.elems;
    my $before   = min(10, $raku-idx);
    my $s        = $raku-idx - $before;
    my $e        = min($s + 19, @words.end);
    my $out      = @words[$s .. $e].join(' ');
    $out = '…' ~ $out if $s > 0;
    $out ~= '…'       if $e < @words.end;
    $out
}

# --- bsky helpers ---

my %month-num = <January 1 February 2 March 3 April 4 May 5 June 6
                  July 7 August 8 September 9 October 10 November 11 December 12>;

sub parse-label(Str $label) {
    return Nil if $label !~~ / (\d+) \s+ (\w+) \s+ (\d+) \s+ 'at' \s+ (\d+) ':' (\d+) /;
    my $mon = %month-num{~$1} or return Nil;
    DateTime.new(day => +$0, month => $mon, year => +$2, hour => +$3, minute => +$4)
}

sub bsky-fetch() {
    my $url = 'https://bsky.app/search?q=%23rakulang&sort=latest';
    my $as = 'tell application "Google Chrome"
        if (count windows) is 0 then make new window
        set w to front window
        set t to make new tab at end of tabs of w with properties {URL:"' ~ $url ~ '"}
        delay 3
        repeat 20 times
            if (execute t javascript "document.readyState") is "complete" then exit repeat
            delay 0.5
        end repeat
        delay 3
        set html to execute t javascript "document.documentElement.outerHTML"
        close t
        return html
    end tell';
    my $proc = run 'osascript', '-e', $as, :out, :err;
    $proc.out.slurp(:close)
}

# --- setup ---

my %nicks = Authors.new.nicks;
my $end   = DateTime.now.posix.Int;
my $start = $end - 7 * 24 * 60 * 60;

my $hn-url = "https://hn.algolia.com/api/v1/search_by_date"
           ~ "?query=raku&tags=comment"
           ~ "&numericFilters=created_at_i>{$start},created_at_i<{$end}"
           ~ "&hitsPerPage=1000";

my $masto-url = "https://mastodon.social/api/v1/timelines/tag/rakulang?limit=40";

# --- collect ---

my @hn-lis;
my @masto-lis;
my @bsky-lis;
my @lobsters-lis;
my @so-lis;

react {
    whenever (start {
        my $resp = await Cro::HTTP::Client.get($hn-url);
        from-json await $resp.body-text;
    }) -> %data {
        my @hits = |%data<hits>;

        my @relevant = @hits.grep: -> %h {
            my $text  = decode-html(%h<comment_text> // '');
            my $title = %h<story_title> // '';
            $text  ~~ m:i/ << raku >> / || $title ~~ m:i/ << raku >> /
        };

        my %seen;
        my @stories = @relevant.grep: -> %h { !%seen{%h<story_id>}++ };

        @hn-lis = @stories.map: -> %h {
            my $url    = "https://news.ycombinator.com/item?id={%h<objectID>}";
            my $snip   = hn-snippet(decode-html(%h<comment_text> // ''));
            my $author = %nicks{%h<author>} // %h<author>;
            li [ a(:href($url), $snip), ' by ', em($author) ];
        };
    }

    whenever (start {
        my $resp = await Cro::HTTP::Client.get($masto-url);
        from-json await $resp.body-text;
    }) -> $data {
        my @posts = |$data;

        @masto-lis = @posts.grep({ DateTime.new($_<created_at>).posix > $start }).map: -> %p {
            my $text   = decode-html(%p<content> // '');
            my $snip   = snippet($text);
            my $url    = %p<url> || %p<uri>;
            next unless $url;
            my $author = %p<account><display_name> || %p<account><acct>;
            li [ a(:href($url), $snip), ' by ', em($author) ];
        };
    }

    whenever (start {
        my $resp = await Cro::HTTP::Client.get(
            'https://lobste.rs/search',
            query   => { q => 'raku', what => 'comments', order => 'newest' },
            headers => [ User-Agent => 'Mozilla/5.0' ],
        );
        await $resp.body-text
    }) -> $html {
        my $dom = DOM::Tiny.parse($html);

        @lobsters-lis = gather for $dom.find('div.comment') -> $c {
            my $time-link = $c.at('a[href^="/c/"]') or next;
            my $time-el   = $time-link.at('time')   or next;
            my $dt = DateTime.new((~$time-el<datetime>).subst(' ', 'T') ~ 'Z');
            next if $dt.posix < $start;

            my $comment-url = 'https://lobste.rs' ~ ~$time-link<href>;
            my $author-node = $c.find('a[href^="/~"]').grep(*.text.trim).first or next;
            my $author      = %nicks{$author-node.text.trim} // $author-node.text.trim;
            my $story       = $c.at('a[href^="/s/"]') or next;
            my $story-title = $story.text.trim;
            my $snip = do with $c.at('div.comment_text') { lobsters-snippet(strip-tags(~$_)) } else { '' };

            take li [ a(:href($comment-url), $story-title), ' — ', $snip, ' by ', em($author) ];
        };
    }

    whenever (start {
        my $resp = await Cro::HTTP::Client.get(
            'https://stackoverflow.com/questions/tagged/raku',
            query   => { tab => 'Newest' },
            headers => [ User-Agent => 'Mozilla/5.0' ],
        );
        await $resp.body-text
    }) -> $html {
        my $dom = DOM::Tiny.parse($html);

        @so-lis = gather for $dom.find('div.s-post-summary') -> $q {
            my $rel = $q.at('span.relativetime') or next;
            my $dt  = DateTime.new((~$rel<title>).subst(' ', 'T'));
            next if $dt.posix < $start;

            my $a      = $q.at('h3 a') or next;
            my $url    = 'https://stackoverflow.com' ~ ~$a<href>;
            my $title  = $a.text.trim;
            my $excerpt = do with $q.at('div.s-post-summary--content-excerpt') { .text.trim } else { '' };
            my $author  = do with $q.at('a[itemprop="url"] span[itemprop="name"]') { .text.trim } else { '' };

            take li [ a(:href($url), $title), ' — ', $excerpt, ($author ?? (' by ', em($author)) !! ()) ];
        };
    }

    whenever (start { bsky-fetch() }) -> $html {
        my $dom = DOM::Tiny.parse($html);

        my %seen;
        my @posts = $dom.find('a').grep({
            my $h = ~$_<href>;
            $h ~~ / '/profile/' .+ '/post/' / && !%seen{$h}++
        }).map({
            %(href => ~$_<href>, label => ~($_<aria-label> // ''))
        }).Array;

        my @post-texts = $dom.find('[data-testid="postText"]').map({ .text.trim }).Array;

        @bsky-lis = gather for @posts Z @post-texts -> (%p, $text) {
            my $dt = parse-label(%p<label>);
            next unless $dt && $dt.posix > $start;
            my $full-href = 'https://bsky.app' ~ %p<href>;
            my $snip      = snippet($text);
            next unless $snip;
            my ($handle)  = $full-href ~~ / '/profile/' (<-[/]>+) '/post/' /;
            my $author    = $handle ?? ~$handle !! '';
            take li [ a(:href($full-href), $snip), ($author ?? (' by ', em($author)) !! ()) ];
        };
    }
}

# --- output ---

my @all-lis = |@hn-lis, |@masto-lis, |@bsky-lis, |@lobsters-lis, |@so-lis;
print h3("Comments about Raku") ~ ul(@all-lis) if @all-lis;

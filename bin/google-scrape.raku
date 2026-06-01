#!/usr/bin/env raku
use lib '.';
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

sub fetch-page(Int $start) {
    my $url = "https://www.google.com/search?q=raku+programming+language&tbs=qdr:w&start=$start&hl=en&num=10";
    my $as = 'tell application "Google Chrome"
        if (count windows) is 0 then make new window
        set w to front window
        set t to make new tab at end of tabs of w with properties {URL:"' ~ $url ~ '"}
        delay 2
        repeat 20 times
            if (execute t javascript "document.readyState") is "complete" then exit repeat
            delay 0.5
        end repeat
        set html to execute t javascript "document.documentElement.outerHTML"
        close t
        return html
    end tell';
    my $proc = run 'osascript', '-e', $as, :out, :err;
    my $html = $proc.out.slurp(:close);
    $html
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

sub find-link($h3) {
    my $node = $h3.parent;
    while $node {
        return $node if $node.tag eq 'a';
        last          if $node.tag eq 'body';
        $node = $node.parent;
    }
    Nil
}

sub result-context($a-node) {
    my $node = $a-node;
    for ^4 {
        last unless $node.parent && $node.parent.tag ne 'body';
        $node = $node.parent;
    }
    (~$node).subst(/ '<' <-[>]>* '>' /, ' ', :g)
             .subst(/\s+/, ' ', :g)
             .trim
}

my @lis;
for 0, 10, 20 -> $start {
    my $html = fetch-page($start);
    my $dom  = DOM::Tiny.parse($html);
    for $dom.find('h3') -> $h3 {
        my $a = find-link($h3) or next;
        my $href = ~$a<href>;
        next unless $href ~~ /^ 'https://' /;
        next if     $href ~~ / 'google.'  /;
        my $title = $h3.text.trim;
        next unless $title;
        my $snip  = snippet(result-context($a));
        @lis.push: li [ a(:href($href), $title), ' — ', $snip ];
    }
}

print ul(@lis) if @lis;

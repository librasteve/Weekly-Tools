#!/usr/bin/env raku
use lib '.';
use DOM::Tiny;
use Air::Functional :BASE;
use Air::Base;

sub fetch-page() {
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

my %month-num = <January 1 February 2 March 3 April 4 May 5 June 6
                  July 7 August 8 September 9 October 10 November 11 December 12>;

sub parse-label(Str $label) {
    return DateTime if $label !~~ / (\d+) \s+ (\w+) \s+ (\d+) \s+ 'at' \s+ (\d+) ':' (\d+) /;
    my $mon = %month-num{~$1} or return DateTime;
    DateTime.new(day => +$0, month => $mon, year => +$2, hour => +$3, minute => +$4)
}

sub snippet(Str $text, Int $len = 20) {
    my @words = $text.words;
    return '' unless @words;
    @words.head($len).join(' ') ~ (@words > $len ?? '…' !! '')
}

my $end   = DateTime.now.posix.Int;
my $start = $end - 7 * 24 * 60 * 60;

my $html = fetch-page();
my $dom  = DOM::Tiny.parse($html);

my %seen;
my @posts = $dom.find('a').grep({
    my $h = ~$_<href>;
    $h ~~ / '/profile/' .+ '/post/' / && !%seen{$h}++
}).map({
    %(href => ~$_<href>, label => ~($_<aria-label> // ''))
}).Array;

my @post-texts = $dom.find('[data-testid="postText"]').map({ .text.trim }).Array;

my @lis;
for @posts Z @post-texts -> (%p, $text) {
    my $dt = parse-label(%p<label>);
    next unless $dt.posix > $start;

    my $full-href = 'https://bsky.app' ~ %p<href>;
    my $snip      = snippet($text);
    next unless $snip;

    my ($handle) = $full-href ~~ / '/profile/' (<-[/]>+) '/post/' /;
    my $author    = $handle ?? ~$handle !! '';

    @lis.push: li [ a(:href($full-href), $snip), ($author ?? (' by ', em($author)) !! ()) ];
}

print ul(@lis) if @lis;

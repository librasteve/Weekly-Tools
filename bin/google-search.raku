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
        .subst('&#x60;', '`',  :g)
        .subst('&nbsp;', ' ',  :g)
        .subst('&#39;',  "'",  :g)
}

sub snippet(Str $text) {
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

my $api-key = %*ENV<GOOGLE_API_KEY> or die "GOOGLE_API_KEY not set";
my $cse-id  = %*ENV<GOOGLE_CSE_ID>  or die "GOOGLE_CSE_ID not set";

my @results;
for 1, 11, 21 -> $start {
    my $resp = await Cro::HTTP::Client.get(
        'https://www.googleapis.com/customsearch/v1',
        query => {
            key         => $api-key,
            cx          => $cse-id,
            q           => 'raku programming language',
            num         => '10',
            start       => ~$start,
            dateRestrict => 'w1',
        }
    );
    my %data = from-json await $resp.body-text;
    my @items = |(%data<items> // []);
    @results.append: @items;
    last unless @items;
}

my @lis;
for @results -> %r {
    my $title = decode-html(%r<title>   // '');
    my $desc  = decode-html(%r<snippet> // '');
    my $text  = "$title $desc";
    next unless $text ~~ m:i/ << raku >> /;

    my $snip   = snippet($desc) || snippet($title);
    my $url    = %r<link>;
    my $domain = %r<displayLink> // $url;

    @lis.push: li [ a(:href($url), $snip), ' by ', em($domain) ];
}

print ul(@lis) if @lis;

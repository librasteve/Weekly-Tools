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

my $token = %*ENV<BRAVE_API_KEY> or die "BRAVE_API_KEY not set in environment";
my $client = Cro::HTTP::Client.new(
    headers => [
        Accept               => 'application/json',
        X-Subscription-Token => $token,
    ]
);

my $resp = await $client.get(
    'https://api.search.brave.com/res/v1/web/search',
    query => {
        q         => '"raku programming language" rakudo rakulang',
        q         => '"raku programming language"',
        freshness => 'pm',   #<pd pw pm py>
        count     => '20',
#        country   => 'us',
    }
);
my %data   = from-json await $resp.body-text;
my @results = |(%data<web><results> // []);

my @lis;
for @results -> %r {
    my $title = decode-html(%r<title>       // '');
    my $desc  = decode-html(%r<description> // '');
    my $text  = "$title $desc";
#    next unless $text ~~ m:i/ << raku >> /;

    my $snip   = snippet($desc) || snippet($title);
    my $url    = %r<url>;
    my $domain = %r<meta_url><hostname> // $url.subst(/^ 'http' 's'? '://' /, '').split('/')[0];

    @lis.push: li [ a(:href($url), $snip), ' by ', em($domain) ];
}

print ul(@lis) if @lis;

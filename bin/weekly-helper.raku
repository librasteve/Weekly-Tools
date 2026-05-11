#!/usr/bin/env raku
use lib '.';
use Weekly::Tools::Dists;
use Weekly::Tools::RakuLand;
use Weekly::Tools::GitHub;

my @tuples = [
    <Raku problem-solving issues>,
    <Raku raku.org pulls>,
    <Raku doc pulls>,
#    <MoarVM MoarVM pulls>,
#    <Raku nqp pulls>,
#    <rakudo rakudo pulls>,
#    <MoarVM MoarVM commits>,
#    <Raku nqp commits>,
#    <rakudo rakudo commits>,
];

my @headings = [
    ['New Problem Solving Issues',  1],
    ['New Doc & Web Pull Requests', 2],
#    ['Core Developments',           0],
];

my ($prev-filename, $latest-filename, $new-names) = load-dists();
note "New dist count: {$new-names.elems} — first few: {$new-names.head(5).join(', ')}";

render-github(@tuples, @headings);
render-rakuland($new-names, :$prev-filename, :$latest-filename);

#!/usr/bin/perl

my $ABOUT = <<___ ;
<h1>Ingress Glyph Quiz</h1>

This little hack provides an interactive quiz to help you learn the "hacking
glyphs" in the game Ingress. Thanks to 
<a href="http://glyphtionary.com">http://glyphtionary.com</a> for the images
you see in this quiz.<P>

It's crude and probably buggy. It was made by <a href="http://twitter.com/spblat">\@spblat</a>.
It's licensed under the <a href="http://opensource.org/licenses/MIT">MIT License</a>, 
which means I don't really care what happens to it but I do retain some basic rights.<P>

This script displays images pulled directly from glyphtionary.com. If this annoys
them they have the ability to break this script by denying access except with 
a proper referrer. If they do that, I'll give them this code and ask them to 
host it themselves, cause that would be cool.<P>

To do maybe (perhaps by someone else):<ul>

<LI> Mobile version
<LI> Track a user's trouble glyphs and focus on those
<LI> Eliminate dependence on glyphtionary.com images</ul>
 
 Features I don't care about:<ul>
 
<LI> Make it so you can't cheat by hacking the URL or looking at the status bar
<LI> Social networking features, score-sharing
<LI> Make it use cookies for some reason</ul>
 
 You can see and contribute to <a href="https://github.com/spblat/ingress-glyph-quiz">the
 perl source at GitHub</a>.

___

# call it from the command line with -i to refresh the data that you see at bottom

use strict;
use warnings;
use Getopt::Std;
our $opt_i;
use vars qw($VAR1  $URL $ABOUT $ME $WIN $LOSS $CSS);

$URL = 'http://glyphtionary.com'; # where to get the glyph images
$CSS = '/ingress-glyph-quiz/glyphquiz.css'; # where to get our CSS

getopts('i');

if ($opt_i) {

	# user asked to reinitialize variables. Scrape the glyphtionary.

	use Data::Dumper;
	use HTTP::Tiny;

	# https://metacpan.org/pod/HTTP::Tiny

	my $response = HTTP::Tiny->new->get($URL);
	die "Failed!\n" unless $response->{success};
	my @glyphs = split '<br />', $response->{content};
	print "Found " . $#glyphs . " glyphs\n";
	
	my @output;

	foreach (@glyphs) {
	
		/alt='(.+?)'/;
		my $name = $1;
	
		/img src='(.+?)'/;
		my $file = $1;
	
		push @output, {
			name => $name,
			file => $file
		};
		# print "$name\t$file\n";
	}
	print Dumper (\@output);
	
	print "\n\nCopy all that crap back into the perl script to update the set of glyphs.\n";
} else { 
	# would you like to play a game?
	use CGI qw/ :standard -debug /; # remove debug when in production
	&initialize or die;
	my $q = CGI->new;
	print $q->header;
	print "<html>\n<head><title>Ingress Glyph Quiz</title>";
	print '<link rel="stylesheet" type="text/css" href="' 
		. $CSS . '" />';
	print '</head><body><div id="content">';
	my $query = CGI->new;
	$ME = url(-relative=>1);
	my $checkforintro = $query->param('rand');

	&Intro unless $checkforintro; # present introduction if no CGI input
	
	# Evaluate answer we got from user (if any)
	# it would be better to use a cookie but who cares
	# test with CGI debug flag and "./glyphquiz.pl q=49 a=49"
	my $guess = $query->param('a');
	my $answer = $query->param('q');
	$WIN = $query->param('w') ? $query->param('w') : 0;
	$LOSS = $query->param('l') ? $query->param('l') : 0;
	if (defined $guess && defined $answer) {
		my $name = ${$VAR1}[$answer]{'name'};
		if ($guess == $answer) {
			print '<div class="result" id="winner">';
			$WIN++;
		} else {
			print '<div class="result" id="loser">';
			$LOSS++;
		}
		# Display the Glyph with the right name
		print "<p class=\"title\">${$VAR1}[$answer]{'name'}</p>\n";
		print "<div class=\"glyph\"><img src='$URL${$VAR1}[$answer]{'file'}'></div>\n";
		print "</div>\n";
	}
	
	&PresentQuiz; # Present a quiz
	
	my $score;
	if ($LOSS > 0) {
		$score = "<li class=\"foot\">W:$WIN</li>"
			. "<li class=\"foot\">L:$LOSS</li>"
			. "<li class=\"foot\">" 
			. int($WIN * 100 / ($WIN + $LOSS)) . "%</li>";
	} else {
		$score = "<li class=\"foot\">100%</li>";
	}
	print<<___;
		<ul class="foot">
		<li class="foot"><a href="$ME">about</a></li>
		$score
		</ul></div></body></html>
___
	
}

sub Intro {
	print "<html><head><title>Ingress Glyph Quiz</title></head><body>$ABOUT";
	print "<P>There are " . scalar(@{$VAR1}) . " glyphs in this quiz.\n";
	print "<p><h1><a href='$ME?rand=1'>Begin</a></h1></body></html>\n";
	exit;
}


sub PresentQuiz {
	my $howmany = scalar(@{$VAR1}); # we go from 0 to $howmany - 1
	# my $last = ${$VAR1}[$howmany - 1]{'name'};
	my $this = int(rand($howmany));
	print "<div id=\"quiz\">\n";
	print "<p class=\"title\">What is it?</p>\n";
	print '<div class="glyph">';
	print "<img src='$URL${$VAR1}[$this]{'file'}'></div>\n";
	my @choices; # array of possible choices
	push @choices, $this;
	for (1 .. 3) {
		my $choice = int(rand($howmany));
		if (rand() > 0.5) { # randomize the choices
			push @choices, $choice;
		} else {
			unshift @choices, $choice;
		}
	}
	my $random = "I";
	$random .= int(rand(10)) foreach (1 .. 50); # so links stay blue
	print '<div class="choices"><ul>';
	foreach (@choices) {
		# display the multiple choices
		print "<li class=\"choice\"><a class=\"guess\" href='$ME?rand=$random&q=$this&a=$_&w=$WIN&l=$LOSS'>${$VAR1}[$_]{'name'}</a></li>\n";
	}
	print "</ul></div></div>\n";
}

sub initialize {
	$VAR1 = [
          {
            'name' => 'Abandon',
            'file' => '/glyphs/thumbs/Abandon.png'
          },
          {
            'file' => '/glyphs/thumbs/Adapt.png',
            'name' => 'Adapt'
          },
          {
            'file' => '/glyphs/thumbs/Advance.png',
            'name' => 'Advance'
          },
          {
            'file' => '/glyphs/thumbs/Again-Repeat.png',
            'name' => 'Again / Repeat'
          },
          {
            'name' => 'All',
            'file' => '/glyphs/thumbs/All.png'
          },
          {
            'name' => 'Answer',
            'file' => '/glyphs/thumbs/Answer.png'
          },
          {
            'name' => 'Attack / War',
            'file' => '/glyphs/thumbs/Attack-War.png'
          },
          {
            'name' => 'Avoid / Struggle',
            'file' => '/glyphs/thumbs/Avoid-Struggle.png'
          },
          {
            'file' => '/glyphs/thumbs/Barrier-Obstacle.png',
            'name' => 'Barrier / Obstacle'
          },
          {
            'name' => 'Begin',
            'file' => '/glyphs/thumbs/Begin.png'
          },
          {
            'file' => '/glyphs/thumbs/Being-Human.png',
            'name' => 'Being / Human'
          },
          {
            'name' => 'Body / Shell',
            'file' => '/glyphs/thumbs/Body-Shell.png'
          },
          {
            'name' => 'Breathe',
            'file' => '/glyphs/thumbs/Breathe.png'
          },
          {
            'name' => 'Capture',
            'file' => '/glyphs/thumbs/Capture.png'
          },
          {
            'name' => 'Change / Modify',
            'file' => '/glyphs/thumbs/Change-Modify.png'
          },
          {
            'name' => 'Chaos / Disorder',
            'file' => '/glyphs/thumbs/Chaos-Disorder.png'
          },
          {
            'file' => '/glyphs/thumbs/Clear.png',
            'name' => 'Clear'
          },
          {
            'name' => 'Close All',
            'file' => '/glyphs/thumbs/Close-All.png'
          },
          {
            'file' => '/glyphs/thumbs/Complex.png',
            'name' => 'Complex'
          },
          {
            'file' => '/glyphs/thumbs/Conflict.png',
            'name' => 'Conflict'
          },
          {
            'file' => '/glyphs/thumbs/Consequence.png',
            'name' => 'Consequence'
          },
          {
            'name' => 'Contemplate',
            'file' => '/glyphs/thumbs/Contemplate.png'
          },
          {
            'file' => '/glyphs/thumbs/Contract.png',
            'name' => 'Contract / Reduce'
          },
          {
            'file' => '/glyphs/thumbs/Courage.png',
            'name' => 'Courage'
          },
          {
            'name' => 'Create / Creation',
            'file' => '/glyphs/thumbs/Create-Creation.png'
          },
          {
            'file' => '/glyphs/thumbs/Creativity.png',
            'name' => 'Creativity'
          },
          {
            'name' => 'Creativity / Mind / Thought / Idea',
            'file' => '/glyphs/thumbs/Creativity-Mind-Thought-Idea.png'
          },
          {
            'file' => '/glyphs/thumbs/Danger.png',
            'name' => 'Danger'
          },
          {
            'file' => '/glyphs/thumbs/Data-Signal-Message.png',
            'name' => 'Data / Signal / Message'
          },
          {
            'name' => 'Defend',
            'file' => '/glyphs/thumbs/Defend.png'
          },
          {
            'name' => 'Destination',
            'file' => '/glyphs/thumbs/Destination.png'
          },
          {
            'file' => '/glyphs/thumbs/Destiny.png',
            'name' => 'Destiny'
          },
          {
            'name' => 'Destroy / Destruction',
            'file' => '/glyphs/thumbs/Destroy-Destruction.png'
          },
          {
            'name' => 'Deteriorate / Erode',
            'file' => '/glyphs/thumbs/Deteriorate-Erode.png'
          },
          {
            'file' => '/glyphs/thumbs/Die.png',
            'name' => 'Die'
          },
          {
            'name' => 'Difficult',
            'file' => '/glyphs/thumbs/Difficult.png'
          },
          {
            'name' => 'Discover',
            'file' => '/glyphs/thumbs/Discover.png'
          },
          {
            'name' => 'Distance / Outside',
            'file' => '/glyphs/thumbs/Distance.png'
          },
          {
            'name' => 'Easy',
            'file' => '/glyphs/thumbs/Easy.png'
          },
          {
            'file' => '/glyphs/thumbs/End-Close.png',
            'name' => 'End / Close / Finality'
          },
          {
            'name' => 'Enlightened / Enlightenment',
            'file' => '/glyphs/thumbs/Enlightened.png'
          },
          {
            'file' => '/glyphs/thumbs/Unknown04.png',
            'name' => 'Enlightened / Enlightenment (Type B)'
          },
          {
            'name' => 'Equal',
            'file' => '/glyphs/thumbs/Equal.png'
          },
          {
            'name' => 'Escape',
            'file' => '/glyphs/thumbs/Escape.png'
          },
          {
            'name' => 'Evolution / Success / Progress / Progression',
            'file' => '/glyphs/thumbs/Evolution.png'
          },
          {
            'file' => '/glyphs/thumbs/Failure.png',
            'name' => 'Failure'
          },
          {
            'name' => 'Fear',
            'file' => '/glyphs/thumbs/Fear.png'
          },
          {
            'name' => 'Follow',
            'file' => '/glyphs/thumbs/Follow.png'
          },
          {
            'file' => '/glyphs/thumbs/Forget.png',
            'name' => 'Forget'
          },
          {
            'file' => '/glyphs/thumbs/Future-Forward-Time.png',
            'name' => 'Future / Forward-Time'
          },
          {
            'file' => '/glyphs/thumbs/Gain.png',
            'name' => 'Gain'
          },
          {
            'name' => 'Government / City / Civilization / Structure',
            'file' => '/glyphs/thumbs/Government-City-Civilization-Structure.png'
          },
          {
            'file' => '/glyphs/thumbs/Grow.png',
            'name' => 'Grow'
          },
          {
            'file' => '/glyphs/thumbs/Harm.png',
            'name' => 'Harm'
          },
          {
            'name' => 'Harmony / Peace',
            'file' => '/glyphs/thumbs/Harmony-Peace.png'
          },
          {
            'name' => 'Have',
            'file' => '/glyphs/thumbs/Have.png'
          },
          {
            'name' => 'Help',
            'file' => '/glyphs/thumbs/Help.png'
          },
          {
            'file' => '/glyphs/thumbs/Hide.png',
            'name' => 'Hide'
          },
          {
            'file' => '/glyphs/thumbs/I-Me-Self.png',
            'name' => 'I / Me / Self'
          },
          {
            'file' => '/glyphs/thumbs/Ignore.png',
            'name' => 'Ignore'
          },
          {
            'name' => 'Imperfect',
            'file' => '/glyphs/thumbs/Imperfect.png'
          },
          {
            'file' => '/glyphs/thumbs/Improve.png',
            'name' => 'Improve'
          },
          {
            'file' => '/glyphs/thumbs/Impure.png',
            'name' => 'Impure'
          },
          {
            'name' => 'Journey',
            'file' => '/glyphs/thumbs/Journey.png'
          },
          {
            'name' => 'Knowledge',
            'file' => '/glyphs/thumbs/Knowledge.png'
          },
          {
            'file' => '/glyphs/thumbs/Lead.png',
            'name' => 'Lead'
          },
          {
            'file' => '/glyphs/thumbs/Legacy.png',
            'name' => 'Legacy'
          },
          {
            'name' => 'Less',
            'file' => '/glyphs/thumbs/Less.png'
          },
          {
            'name' => 'Liberate',
            'file' => '/glyphs/thumbs/Liberate.png'
          },
          {
            'name' => 'Lie',
            'file' => '/glyphs/thumbs/Lie.png'
          },
          {
            'name' => 'Live Again / Reincarnate',
            'file' => '/glyphs/thumbs/Live-Again-Reincarnate.png'
          },
          {
            'name' => 'Lose / Loss',
            'file' => '/glyphs/thumbs/Lose.png'
          },
          {
            'file' => '/glyphs/thumbs/Message.png',
            'name' => 'Message'
          },
          {
            'file' => '/glyphs/thumbs/Mind-Idea-Thought.png',
            'name' => 'Mind / Idea / Thought'
          },
          {
            'file' => '/glyphs/thumbs/More.png',
            'name' => 'More'
          },
          {
            'file' => '/glyphs/thumbs/Mystery.png',
            'name' => 'Mystery'
          },
          {
            'name' => 'Nature',
            'file' => '/glyphs/thumbs/Nature.png'
          },
          {
            'file' => '/glyphs/thumbs/New.png',
            'name' => 'New'
          },
          {
            'name' => 'No / Not / Absent / Inside',
            'file' => '/glyphs/thumbs/No-Not-Absent.png'
          },
          {
            'name' => 'Nourish',
            'file' => '/glyphs/thumbs/Nourish.png'
          },
          {
            'file' => '/glyphs/thumbs/Old.png',
            'name' => 'Old'
          },
          {
            'name' => 'Open / Accept',
            'file' => '/glyphs/thumbs/Open.png'
          },
          {
            'file' => '/glyphs/thumbs/Open-All.png',
            'name' => 'Open All'
          },
          {
            'file' => '/glyphs/thumbs/Opening-Doorway-Portal.png',
            'name' => 'Opening / Doorway / Portal'
          },
          {
            'file' => '/glyphs/thumbs/Past.png',
            'name' => 'Past'
          },
          {
            'name' => 'Path',
            'file' => '/glyphs/thumbs/Path.png'
          },
          {
            'file' => '/glyphs/thumbs/Perfection.png',
            'name' => 'Perfection / Balance'
          },
          {
            'file' => '/glyphs/thumbs/Perspective.png',
            'name' => 'Perspective'
          },
          {
            'file' => '/glyphs/thumbs/Potential.png',
            'name' => 'Potential'
          },
          {
            'file' => '/glyphs/thumbs/Presence.png',
            'name' => 'Presence'
          },
          {
            'file' => '/glyphs/thumbs/Present-Now.png',
            'name' => 'Present / Now'
          },
          {
            'name' => 'Pure / Purity',
            'file' => '/glyphs/thumbs/Pure-Purity.png'
          },
          {
            'name' => 'Pursue / Aspiration',
            'file' => '/glyphs/thumbs/Pursue.png'
          },
          {
            'file' => '/glyphs/thumbs/Pursue-Chase.png',
            'name' => 'Pursue / Chase'
          },
          {
            'file' => '/glyphs/thumbs/Question.png',
            'name' => 'Question'
          },
          {
            'file' => '/glyphs/thumbs/React.png',
            'name' => 'React'
          },
          {
            'file' => '/glyphs/thumbs/Rebel.png',
            'name' => 'Rebel'
          },
          {
            'file' => '/glyphs/thumbs/Recharge.png',
            'name' => 'Recharge'
          },
          {
            'name' => 'Resist / Resistance (Type B)',
            'file' => '/glyphs/thumbs/Unknown03.png'
          },
          {
            'name' => 'Resist / Resistance / Struggle',
            'file' => '/glyphs/thumbs/Resist-Resistance.png'
          },
          {
            'name' => 'Restraint',
            'file' => '/glyphs/thumbs/Restraint.png'
          },
          {
            'name' => 'Retreat',
            'file' => '/glyphs/thumbs/Retreat.png'
          },
          {
            'name' => 'Safety',
            'file' => '/glyphs/thumbs/Safety.png'
          },
          {
            'file' => '/glyphs/thumbs/Save-Rescue.png',
            'name' => 'Save / Rescue'
          },
          {
            'file' => '/glyphs/thumbs/See.png',
            'name' => 'See'
          },
          {
            'file' => '/glyphs/thumbs/Seek-Search.png',
            'name' => 'Seek / Search'
          },
          {
            'name' => 'Self',
            'file' => '/glyphs/thumbs/Self.png'
          },
          {
            'file' => '/glyphs/thumbs/Separate.png',
            'name' => 'Separate'
          },
          {
            'name' => 'Shaper / Collective',
            'file' => '/glyphs/thumbs/Shaper-Collective.png'
          },
          {
            'name' => 'Shaper / Collective + Being / Human',
            'file' => '/glyphs/thumbs/Shaper+Human.png'
          },
          {
            'file' => '/glyphs/thumbs/Share.png',
            'name' => 'Share'
          },
          {
            'file' => '/glyphs/thumbs/Simple.png',
            'name' => 'Simple'
          },
          {
            'file' => '/glyphs/thumbs/Soul-Spirit-Life-Force.png',
            'name' => 'Soul / Spirit / Life Force'
          },
          {
            'name' => 'Stability / Stay',
            'file' => '/glyphs/thumbs/Stability.png'
          },
          {
            'file' => '/glyphs/thumbs/Strong.png',
            'name' => 'Strong'
          },
          {
            'name' => 'Together',
            'file' => '/glyphs/thumbs/Together.png'
          },
          {
            'file' => '/glyphs/thumbs/Truth.png',
            'name' => 'Truth'
          },
          {
            'file' => '/glyphs/thumbs/Use.png',
            'name' => 'Use'
          },
          {
            'name' => 'Victory',
            'file' => '/glyphs/thumbs/Victory.png'
          },
          {
            'file' => '/glyphs/thumbs/Want.png',
            'name' => 'Want / Desire'
          },
          {
            'name' => 'We / Us',
            'file' => '/glyphs/thumbs/We-Us.png'
          },
          {
            'file' => '/glyphs/thumbs/Weak.png',
            'name' => 'Weak'
          },
          {
            'name' => 'Worth',
            'file' => '/glyphs/thumbs/Worth.png'
          },
          {
            'file' => '/glyphs/thumbs/XM.png',
            'name' => 'XM (Exotic Matter)'
          },
          {
            'name' => 'You / Other',
            'file' => '/glyphs/thumbs/You-Other.png'
          },
        ];
}

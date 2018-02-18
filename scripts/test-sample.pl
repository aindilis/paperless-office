#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

use XML::LibXML;

my $timexstring = read_file("sample.xml");

my $parser = XML::LibXML->new;
my $doc = $parser->parse_string($timexstring);
my $dates = {};
my $message = 0;
my $root = $doc->documentElement();
my @sentences;
my @taggedtext;
my @text;
my ($x,$b,$y);
my $i = 0;
foreach my $s ($root->getChildrenByTagName("s")) {
  foreach my $child ($s->nonBlankChildNodes()) {
    if ($child->nodeName eq "TIMEX3") {
      $x = join(" ",@text);
      @text = ();
      foreach my $child ($child->getChildrenByTagName("lex")) {
	push @text, $child->textContent;
      }
      $b = join(" ",@text);

      $date = $child->getAttribute("VAL");
      if (defined $date) {
	my $messageevent = "MESSAGE".$message."-EVENT".$i;
	$dates->{$date}->{$messageevent} =
	  {
	   Message => $message,
	   Event => $i,
	   DateText => CleanText(Text => $b),
	  };
      }
      push @taggedtext,
	CleanText(Text => $x),
	  "<a name=\"EVENT$i\"><font size=\"+2\">",
	    CleanText(Text => $b),
	      "</font><sub>EVENT$i</sub></a>";
      ++$i;

    } elsif ($child->nodeName eq "lex") {
      push @text, $child->toString;
    }
  }
}
if (@text) {
  $y = join(" ",@text);
  push @taggedtext, CleanText(Text => $y);
}

sub CleanText {
  my (%args) = @_;
  my $t = $args{Text};
  if ($t) {
    $t =~ s/<\/?s>//g;
    $t =~ s/<\/?doc>//g;
    $t =~ s/<lex .*?>//g;
    $t =~ s/<TIMEX\d+ .*?>//g;
    $t =~ s/<\/TIMEX\d+>//g;
    $t =~ s/<\/lex>//g;
  }
  return HTMLify(Text => $t);
}

sub HTMLify {
  my (%args) = @_;
  my $t = $args{Text};
  if ($t) {
    $t =~ s/&/&AMP;/g;
    $t =~ s/</&LT;/g;
  }
  return $t;
}

print join(" ",@taggedtext)."\n";
print Dumper($dates);

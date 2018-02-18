#!/usr/bin/perl -w

use Capability::TextAnalysis;
use KBS2::Client;
use KBS2::Util;
use Lingua::EN::Extract::Dates;
use PaperlessOffice::Mod::Calendar;
use PaperlessOffice::Mod::TextAnalysis;
use PerlLib::SwissArmyKnife;
use Sayer;

# first, load all the full texts, then load the calendar, then run

my $client = KBS2::Client->new
  (
   Context => "Org::FRDCSA::PaperlessOffice::Cabinet::paperport",
  );
my $mydates = Lingua::EN::Extract::Dates->new;
my $sayer = Sayer->new
  (
   DBName => "sayer_paperlessoffice",
  );
my $textanalysis =
  Capability::TextAnalysis->new
  (
   Sayer => $sayer,
   DontSkip => {
		# "Tokenization" => 1,
		# "TermExtraction" => 1,
		"GetDatesTIMEX3" => 1,
		# "DateExtraction" => 1,
		# "NamedEntityRecognition" => 1,
		# "NounPhraseExtraction" => 1,
	       },
  );

my $documentcount = 1;
my $documentdir = "/tmp";
my $metadata = {};
my $events = {};

LoadMetadata();

foreach my $key (keys %{$metadata->{"has-fulltext"}}) {
  AnalyzeDocument
    (
     ID => $key,
     FullText => $metadata->{"has-fulltext"}->{$key},
    );
}

sub LoadMetadata {
  my (%args) = @_;
  print "Loading metadata\n";
  my $message = $client->Send
    (
     QueryAgent => 1,
     Command => "all-asserted-knowledge",
     Context => $context,
    );
  if (defined $message) {
    my $assertions = $message->{Data}->{Result};
    foreach my $assertion (@$assertions) {
      my $pred = $assertion->[0];
      if ($assertion->[0] eq "has-fulltext") {
	$metadata->{"has-fulltext"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
    }
  }
}

sub AnalyzeDocument {
  my (%args) = @_;
  my $fulltext = $args{FullText};
  # structure
  # print Dumper($fulltext);
  if (length($fulltext) > 10000) {
    return;
  }
  print "Analyzing: ".$args{ID}."\n";

  # an analysis of dates referenced
  my $res = AnalyzeDocument2
    (
     FullText => $fulltext,
    );
  # print Dumper($res);
  # GetSignalFromUserToProceed();
  if (exists $res->{DateExtraction}) {
    my $timextext = $res->{DateExtraction}->[0];
    print Dumper($timextext);
    my $ref = $mydates->GetDatesTIMEX3
      (
       TIMEX => $timextext,
       # Text => $fulltext,
       Message => $documentcount,
      );
    my $dates = $ref->{Dates};
    my $cleanedtext = $ref->{CleanedText};
    print Dumper
      ({
	Dates => $dates,
	Clean => $cleanedtext,
	Timex => $timextext,
       });

    # if there are any dates to this document, save the document to the website
    # skip this for now
    if (scalar keys %$dates) {
      my $OUT;
      my $rellink = "documents/DOCUMENT".$documentcount.".html";
      my $outputfile = $documentdir."/"."DOCUMENT".$documentcount.".html";
      open(OUT,">$outputfile") or die "Cannot open document file\n";
      print OUT "<html><pre>\n$cleanedtext\n</pre></html>\n";
      close(OUT);
      my $month = "08";
      foreach my $date (keys %$dates) {
	if ($date =~ /^$month(..)$/) {
	  foreach my $documentevent (keys %{$dates->{$date}}) {
	    $events->{$date}->{$documentevent} =
	      {
	       Tag => $document->DocumentID. " :: ". $documentevent,
	       Link => "$rellink#EVENT".$dates->{$date}->{$documentevent}->{Event},
	      };
	  }
	}
      }
      ++$documentcount;
    }
  }
}

sub AnalyzeDocument2 {
  my (%args) = @_;
  return $textanalysis->AnalyzeText
    (
     Text => $args{FullText},
     Overwrite => {
		   # "GetDatesTIMEX3" => 1,
		  },
    );
}

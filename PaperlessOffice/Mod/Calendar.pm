package PaperlessOffice::Mod::Calendar;

use Lingua::EN::Extract::Dates;
use PerlLib::SwissArmyKnife;
use Text::Wrap;

use HTML::Calendar::Simple;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyDocumentManager MyDates Events Dates MyCalendars CalendarRoot
   CalendarFile DocumentDir DocumentCount Month /

  ];

sub init {
  my ($self,%args) = @_;
  my $month = `date "+%Y%m"`;
  # add the ability to do multiple years (later)
  $self->Month($month);
  # $self->Month("201008");
  $self->MyDocumentManager($UNIVERSAL::paperlessoffice->MyDocumentManager);
  $self->MyCalendars({});
  $self->MyDates
    (Lingua::EN::Extract::Dates->new);
  $self->Events({});
  $self->Dates({});
  # get the cabinet directory:
  $self->CalendarRoot(ConcatDir($self->MyDocumentManager->Cabinet->Directory,"web-calendar"));
  MkDirIfNotExists(Directory => $self->CalendarRoot);
  $self->DocumentDir($self->CalendarRoot."/documents");
  MkDirIfNotExists(Directory => $self->DocumentDir);
  $self->DocumentCount(0);
  print Dumper({
		Root => $self->CalendarRoot,
		Dir => $self->DocumentDir,
	       });
}

sub UpdateCalendar {
  my ($self,%args) = @_;
  # this is run when any emails are detected, over UniLang.

  # load the data
  # load any emails that we haven't parsed
  # save the data
  $self->AnalyzeDocuments;
  $self->AddDocuments;
  $self->PrintCalendars;
}

sub AnalyzeDocuments {
  # V2
  my ($self,%args) = @_;
  # determine important mail, maybe using hooks that tell you how important mail is
  # if there are dates, add them to the calendar
  foreach my $document (values %{$self->MyDocumentManager->Documents}) {
    $self->AnalyzeDocument
      (
       Document => $document,
      );
  }
  # print Dumper($self->Events);
}

sub AnalyzeDocument {
  my ($self,%args) = @_;
  my $document = $args{Document};
  # structure
  # print Dumper($document);
  if (length($document->FullText) > 10000) {
    return;
  }
  print "Analyzing: ".$document->DocumentID."\n";

  # an analysis of dates referenced
  $UNIVERSAL::paperlessoffice->MyResources->LoadTextAnalysis;
  my $res = $UNIVERSAL::paperlessoffice->MyResources->MyTextAnalysis->AnalyzeDocument
    (
     Document => $document,
    );
  if (exists $res->{GetDatesTIMEX3}) {
    my $ref = $res->{GetDatesTIMEX3}->[0];
    my $dates = $ref->{Dates};
    my $cleanedtext = $ref->{CleanedText};
    #     print Dumper
    #       ({
    # 	Dates => $dates,
    # 	Clean => $cleanedtext,
    #        });

    # if there are any dates to this document, save the document to the website
    # skip this for now
    if (scalar keys %$dates) {
      my $OUT;
      my $rellink = "documents/DOCUMENT".$self->DocumentCount.".html";
      my $outputfile = $self->DocumentDir."/"."DOCUMENT".$self->DocumentCount.".html";
      open(OUT,">$outputfile") or die "Cannot open document file\n";
      print OUT "<html><pre>\n".wrap("", "", $cleanedtext)."\n</pre></html>\n";
      close(OUT);
      foreach my $date (keys %$dates) {
	$self->Dates->{$date}++;
	my $year;
	my $month;
	if ($date =~ /^(\d{4})(\d\d)(\d\d)$/) {
	  $year = $1;
	  $month = $2;
	  $day = $3;
	}
	if ($date =~ /^(\d{4})(\d\d)(\d\d)T/) {
	  $year = $1;
	  $month = $2;
	  $day = $3;
	}
	foreach my $documentevent (keys %{$dates->{$date}}) {
	  $self->Events->{$year}->{$month}->{$day}->{$documentevent} =
	    {
	     Tag => $document->DocumentID. " :: ". $documentevent,
	     Link => "$rellink#EVENT".$dates->{$date}->{$documentevent}->{Event},
	    };
	}
      }
      $self->DocumentCount
	($self->DocumentCount + 1);
    }
  }
}

sub AddDocuments {
  my ($self,%args) = @_;
  # add new items to the calendar
  print "Generating the calendar\n";
  my $month = $self->Month;
  my %dayinfos;

  foreach my $year (keys %{$self->Events}) {
    foreach my $month (keys %{$self->Events->{$year}}) {
      foreach my $day (keys %{$self->Events->{$year}->{$month}}) {
	my @dayinfo;
	foreach my $event (keys %{$self->Events->{$year}->{$month}->{$day}}) {
	  my $e = $self->Events->{$year}->{$month}->{$day}->{$event};
	  push @dayinfo, "<a href=\"".$e->{Link}."\">".$e->{Tag}."</a><p>";
	}
	if (! exists $self->MyCalendars->{$year}->{$month}) {
	  $self->MyCalendars->{$year}->{$month} =
	    HTML::Calendar::Simple->new
		(
		 year => $year,
		 month => $month,
		);
	}
	$self->MyCalendars->{$year}->{$month}->daily_info
	  ({
	    day => $day,
	    Notes => join("",@dayinfo),
	   });
      }
    }
  }
}

sub PrintCalendars {
  my ($self,%args) = @_;
  foreach my $year (keys %{$self->MyCalendars}) {
    foreach my $month (keys %{$self->MyCalendars->{$year}}) {
      my $calendarfile = $self->CalendarRoot."/$year-$month.html";
      my $OUT;
      open(OUT,">$calendarfile") or die "cannot open calendar file";
      print OUT $self->MyCalendars->{$year}->{$month}->html;
      close(OUT);
    }
  }
}

1;

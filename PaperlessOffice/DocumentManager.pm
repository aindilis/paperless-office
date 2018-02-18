package PaperlessOffice::DocumentManager;

use Capability::TextAnalysis;
use KBS2::Client;
use KBS2::Util;
use Manager::Dialog qw(ApproveCommands);
use PaperlessOffice::Document;
use PerlLib::SwissArmyKnife;
use Sayer;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Cabinet CabinetName Documents DeleteQueue MySayer
   MyTextAnalysis Context MyClient Metadata Count /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Cabinet($args{Cabinet});
  $self->CabinetName($self->Cabinet->Name);
  $self->Context("Org::FRDCSA::PaperlessOffice::Cabinet::".$self->CabinetName);
  $self->MyClient
    (KBS2::Client->new
     (
      Context => $self->Context,
     ));
  $self->Documents({});
  $self->DeleteQueue({});
  $self->Metadata({});
}

sub LoadDocuments {
  my ($self,%args) = @_;
  # go ahead and load the cabinet knowledgebase
  $self->LoadMetadata();

  my $documentdirectory = $self->Cabinet->DocumentDirectory;
  $self->Count(0);
  foreach my $dir (split /\n/, `ls "$documentdirectory"`) {
    $self->Count($self->Count + 1);
    $self->AddDocument
      (
       Directory => $dir,
       DocumentDirectory => $documentdirectory,
       DeleteIfNecessary => 1,
      );
  }
  my $numtobedeleted = scalar keys %{$self->DeleteQueue};
  if ($numtobedeleted > 0) {
    print "There are $numtobedeleted documents that should be deleted.\n";
    my @commands;
    foreach my $doc (values %{$self->DeleteQueue}) {
      push @commands, "mv \"".$doc->Directory."\" /tmp";
    }
    print "PaperlessOffice::DocumentManager->LoadDocuments\n";
    ApproveCommands
      (
       Commands => \@commands,
       Method => "parallel",
      );
  }
  # remove the documents that have been moved
  # print Dumper($self->Documents);
}

sub AddDocument {
  my ($self,%args) = @_;
  my $documentdirectory = $args{DocumentDirectory};
  my $dir = $args{Directory};
  if (exists $UNIVERSAL::paperlessoffice->Conf->{'-s'} and $self->Count > 10) {
    last;
  }
  my $documentfn = DumperQuote2(["document-fn",$self->CabinetName,$dir]);

  my $type;
  if (exists $self->Metadata->{"has-type"}->{$documentfn}) {
    $type = $self->Metadata->{"has-type"}->{$documentfn};
  } else {
    my $res = $self->GetTypeOfDocument
      (
       Directory => $dir,
       DocumentDirectory => $documentdirectory,
      );
    if ($res->{Success}) {
      $type = $res->{Type};
    } else {
      $type = "Unknown";
    }
    $self->SetMetadata
      (
       DocumentID => $dir,
       Predicate => "has-type",
       Value => $type,
      );
  }

  if (defined $type and $type =~ /^(ImagePDF|SearchablePDF|MultipleImages)$/) {
    # load the document data persistence
    # print "$documentdirectory/$dir is of type $type\n";
    require "PaperlessOffice/Document/$type.pm";
    my $doc = "PaperlessOffice::Document::$type"->new
      (
       Directory => "$documentdirectory/$dir",
       Action => "load",
       Folders => $args{Folders},
      );
    $doc->Execute();
    if ($doc->IsEmptyAndShouldBeDeleted) {
      print Dumper({
		    Type => $type,
		    ID => $doc->DocumentID,
		   });
      $self->DeleteQueue->{$doc->DocumentID} = $doc;
    }
    $self->Documents->{$doc->DocumentID} = $doc;
    # go ahead and add it to the folders
    $self->Cabinet->AddDocument
      (
       Document => $doc,
      );
  } else {
    print "Type not found: $documentdirectory/$dir\n";
  }
}

sub RemoveDocument {
  my ($self,%args) = @_;
  print Dumper(\%args);
  my $doc = $args{Document};
  my $documentfn = DumperQuote2(["document-fn",$self->CabinetName,$doc->DocumentID]);
  if ($args{RemoveMetadata}) {

  }
  delete $self->Documents->{$doc->DocumentID};
  $self->Cabinet->RemoveDocument
    (
     Document => $doc,
    );
}

sub LoadMetadata {
  my ($self,%args) = @_;
  my $message = $self->MyClient->Send
    (
     QueryAgent => 1,
     Command => "all-asserted-knowledge",
     Context => $context,
    );

  # "Thumbnail" => "has-thumbnail",
  # "Type" => "has-type",
  # "Folders" => "has-folder",
  # "Title" => "has-title",
  # "Description" => "has-description",
  # "FullText" => "has-fulltext",
  # "DateTimeStamp" => "has-datetimestamp",
  # "Tags" => "has-tag",
  # "Temporal Constraints" => "",
  # "Recurrence" => "",
  # "Status" => "",
  # "Dependencies" => "",
  # "Predependencies" => "",
  # "Eases" => "",
  # "Blocking Issues" => "",
  # "Labor Involved" => "",

  if (defined $message) {
    my $assertions = $message->{Data}->{Result};
    foreach my $assertion (@$assertions) {
      my $pred = $assertion->[0];
      if ($assertion->[0] eq "has-type") {
	$self->Metadata->{"has-type"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-folder") {
	$self->Metadata->{"has-folder"}->{DumperQuote2($assertion->[1])}->{$assertion->[2]} = 1;
      }
      if ($assertion->[0] eq "has-tag") {
	$self->Metadata->{"has-tag"}->{DumperQuote2($assertion->[1])}->{$assertion->[2]} = 1;
      }
      if ($assertion->[0] eq "has-title") {
	$self->Metadata->{"has-title"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-description") {
	$self->Metadata->{"has-description"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-fulltext") {
	$self->Metadata->{"has-fulltext"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-thumbnail") {
	$self->Metadata->{"has-thumbnail"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-pdf") {
	$self->Metadata->{"has-pdf"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-datetimestamp") {
	$self->Metadata->{"has-datetimestamp"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
    }
  }
}

sub DeleteMetadata {
  my ($self,%args) = @_;
  my $docrel = ["document-fn",$self->CabinetName,$args{DocumentID}];
  my $documentfn = DumperQuote2($docrel);
  my @unassertions;
  foreach my $predicate (keys %{$self->Metadata}) {
    if (exists $self->Metadata->{$predicate}->{$documentfn}) {
      push @unassertions, [$predicate,$docrel,$self->Metadata->{$predicate}->{$documentfn}];
      delete $self->Metadata->{$predicate}->{$documentfn};
    }
  }

  # first unassert the old value
  my %sendargs =
    (
     Unassert => \@unassertions,
     Context => $self->Context,
     QueryAgent => 1,
     InputType => "Interlingua",
     Flags => {
	       AssertWithoutCheckingConsistency => 1,
	      },
    );
  print Dumper(\%sendargs);
  my $res = $self->MyClient->Send(%sendargs);
  print Dumper({DeleteResult => $res});
}

sub GetTypeOfDocument {
  my ($self,%args) = @_;
  my $type;
  my $dir = $args{Directory};
  my $documentdirectory = $args{DocumentDirectory};
  # figure out on the basis of the items
  my $quoteddir = shell_quote("$documentdirectory/$dir");
  my $res = `ls -1 $quoteddir | grep -ir pdf -`;
  if ($res =~ /^(.+\.pdf)$/im) {
    # it's a pdf
    my $pdffile = $1;
    my $quotedpdffile = shell_quote("$documentdirectory/$dir/$pdffile");
    my $res2 = `pdftotext $quotedpdffile -`;
    if ($res2 =~ /\w/) {
      # it's a searchable
      $type = "SearchablePDF";
    } else {
      $type = "ImagePDF";
    }
  }
  my $res3 = `ls -1 $quoteddir | grep -ir pnm -`;
  if ($res3 =~ /\.pnm$/is) {
    # it's an multiple images
    $type = "MultipleImages";
  }
  my $fh = IO::File->new;
  $fh->open(">$typefile") or warn "cannot open type file\n";
  print $fh $type;
  $fh->close();
  if (defined $type) {
    return {
	    Success => 1,
	    Type => $type,
	   };
  } else {
    return {
	    Success => 0,
	   };
  }
}

sub GetMetadata {
  my ($self,%args) = @_;
  my $documentfn = DumperQuote2(["document-fn",$self->CabinetName,$args{DocumentID}]);
  if (exists $self->Metadata->{$args{Predicate}}->{$documentfn}) {
    return {
	    Success => 1,
	    Result => $self->Metadata->{$args{Predicate}}->{$documentfn},
	   };
  }
  return {
	  Success => 0,
	 };
}

sub SetMetadata {
  my ($self,%args) = @_;
  my $docrel = ["document-fn",$self->CabinetName,$args{DocumentID}];
  my $documentfn = DumperQuote2($docrel);
  my $assert = 0;
  if (exists $self->Metadata->{$args{Predicate}}->{$documentfn} and ! $args{Multivalued}) {
    if (DumperQuote2($args{Value}) ne DumperQuote2($self->Metadata->{$args{Predicate}}->{$documentfn})) {
      # update the value in the KB and the array

      # first unassert the old value
      my %sendargs =
	(
	 Unassert => [[$args{Predicate},$docrel,$self->Metadata->{$args{Predicate}}->{$documentfn}]],
	 Context => $self->Context,
	 QueryAgent => 1,
	 InputType => "Interlingua",
	 Flags => {
		   AssertWithoutCheckingConsistency => 1,
		  },
	);
      print Dumper(\%sendargs);
      my $res = $self->MyClient->Send(%sendargs);
      print Dumper({UnassertResult => $res});

      # make sure that succeeded
      $assert = 1;
    } else {
      # it's fine, leave it alone
    }
  } else {
    # assert the value into the KB
    $assert = 1;
  }
  if ($assert) {
    # send the new value
    %sendargs =
      (
       Assert => [[$args{Predicate},$docrel,$args{Value}]],
       Context => $self->Context,
       QueryAgent => 1,
       InputType => "Interlingua",
       Flags => {
		 AssertWithoutCheckingConsistency => 1,
		},
      );
    print Dumper(\%sendargs);
    my $res = $self->MyClient->Send(%sendargs);
    print Dumper({AssertResult => $res});

    if ($args{Multivalued}) {
      $self->Metadata->{$args{Predicate}}->{$documentfn}->{$args{Value}} = 1;
    } else {
      $self->Metadata->{$args{Predicate}}->{$documentfn} = $args{Value};
    }
    return {
	    Success => 1,
	    Changes => 1,
	   };
  }
  return {
	  Success => 1,
	 };
}

sub RemoveMetadata {
  my ($self,%args) = @_;
  my $docrel = ["document-fn",$self->CabinetName,$args{DocumentID}];
  my $documentfn = DumperQuote2($docrel);
  if (exists $self->Metadata->{$args{Predicate}}->{$documentfn} and
      exists $self->Metadata->{$args{Predicate}}->{$documentfn}->{$args{Value}}) {
    # first unassert the old value
    my %sendargs =
      (
       Unassert => [[$args{Predicate},$docrel,$args{Value}]],
       Context => $self->Context,
       QueryAgent => 1,
       InputType => "Interlingua",
       Flags => {
		 AssertWithoutCheckingConsistency => 1,
		},
      );
    print Dumper(\%sendargs);
    my $res = $self->MyClient->Send(%sendargs);
    print Dumper({RemoveResult => $res});
    delete $self->Metadata->{$args{Predicate}}->{$documentfn}->{$args{Value}};
  } else {
    # it's fine, leave it alone
  }
}

sub Search {
  my ($self,%args) = @_;
  # build the search index
  # update the index

  # use System::Namazu here

  $self->UpdateIndex;
}

sub UpdateIndex {
  my ($self,%args) = @_;
  my $documentdirectory = $self->Cabinet->DocumentDirectory;
  # `find $documentdirectory | grep '\.txt$'`
}

sub AnalyzeDocuments {
  my ($self,%args) = @_;
  # index all text files using Capability::TextAnalysis
  $UNIVERSAL::paperlessoffice->MyResources->LoadTextAnalysis;
  foreach my $document (values %{$self->Documents}) {
    my $results = $UNIVERSAL::paperlessoffice->MyResources->MyTextAnalysis->AnalyzeText
      (Text => $document->FullText);
    print Dumper($results);
  }
}

sub ShowCalendar {
  my ($self,%args) = @_;
  # we want to load a new object which is the calendar window - which
  # takes the dates extracted from the documents
  $UNIVERSAL::paperlessoffice->MyResources->LoadCalendar;
  $UNIVERSAL::paperlessoffice->MyResources->MyCalendar->UpdateCalendar();
}

sub ClassifyAllUnclassifiedDocuments {
  my ($self,%args) = @_;
  $UNIVERSAL::paperlessoffice->MyResources->ClassifyAllUnclassifiedDocuments(%args);
}

sub RetrainTheDocumentClassifier {
  my ($self,%args) = @_;
  $UNIVERSAL::paperlessoffice->MyResources->RetrainTheDocumentClassifier(%args);
}

sub SetMultivalued {
  my ($self,%args) = @_;
  # check if there
  my $assert = {};
  my $unassert = {};
  my $dontassert = {};

  my $res = $self->GetMetadata
    (
     DocumentID => $args{DocumentID},
     Predicate => $args{Predicate},
    );

  return {
	  Success => 0,
	 } unless $res->{Success};
  my $values = $res->{Result};
  # get the values here
  foreach my $value (keys %$values) {
    if (! exists $args{Values}->{$value}) {
      $unassert->{$value} = 1;
    } else {
      $dontassert->{$value} = 1;
    }
  }
  foreach my $value (keys %{$args{Values}}) {
    if (! exists $dontassert->{$value}) {
      $assert->{$value} = 1;
    }
  }

  # now perform all the movements and redraw affected windows
  my $changes = {};
  foreach my $value (keys %$unassert) {
    $changes->{$value} = 1;
    my $res = $self->RemoveMetadata
      (
       DocumentID => $args{DocumentID},
       Predicate => $args{Predicate},
       Value => $value,
      );
  }
  foreach my $value (keys %$assert) {
    $changes->{$value} = 1;
    my $res = $self->SetMetadata
      (
       DocumentID => $args{DocumentID},
       Predicate => $args{Predicate},
       Value => $value,
       Multivalued => 1,
      );
  }
  return {
	  Success => 1,
	  Changes => $changes,
	 };
}

1;

package PaperlessOffice::GUI::Tab::View::DocumentManager;

use PerlLib::Collection;
use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Documents Data MyView SelectionOrder /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Documents
    (PerlLib::Collection->new
     (Type => "PaperlessOffice::GUI::Tab::View::Document"));
  $self->Documents->Contents({});
  $self->SelectionOrder([]);
  $self->MyView($args{MyView});
  $self->Execute();
}

sub Execute {
  my ($self,%args) = @_;
  foreach my $doc (values %{$UNIVERSAL::paperlessoffice->MyDocumentManager->Documents}) {
    $self->AddDocument
      (Document => $doc);
  }
}

sub AddDocument {
  my ($self,%args) = @_;
  $self->Documents->Add
    (
     $args{Document}->DocumentID => $args{Document},
    );
}

sub RemoveDocument {
  my ($self,%args) = @_;
  $self->Documents->Subtract
    (
     $args{Document}->DocumentID => $args{Document},
    );
}

sub AddDocumentOld {
  my ($self,%args) = @_;
  $self->Documents->AddAutoIncrement
    (
     Item => $args{Document},
    );
}

sub GetDocument {
  my ($self,%args) = @_;
  my @matches;
  if (exists $args{Selected}) {
    if (1) {
      @matches = @{$self->SelectionOrder};
    } else {
      foreach my $document ($self->Documents->Values) {
	if (defined $document->Selected and $document->Selected eq $args{Selected}) {
	  push @matches, $document;
	}
      }
    }
  }
  if (exists $args{Description}) {
    foreach my $document ($self->Documents->Values) {
      if ($document->Description eq $args{Description}) {
	push @matches, $document;
      }
    }
  }
  return \@matches;
}

sub GetDocument {
  my ($self,%args) = @_;
  my @matches;
  if (exists $args{GraphVizNode}) {
    foreach my $document ($self->Documents->Values) {
      if ($document->GraphVizNode eq $args{GraphVizNode}) {
	push @matches, $document;
      }
    }
  }
  if (exists $args{Selected}) {
    foreach my $document ($self->Documents->Values) {
      if (defined $document->Selected and $document->Selected eq $args{Selected}) {
	push @matches, $document;
      }
    }
  }
  return \@matches;
}

sub Select {
  my ($self,%args) = @_;
  my $document1;
  if (exists $args{Document}) {
    $document1 = $args{Document};
  }
  if ($args{Selection} eq "Toggle-Single") {
    # this means to toggle the item selected and deselect everything
    # else
    $self->Select
      (
       Selection => "None",
       Skip => [
		$document1,
	       ],
      );
    # now toggle this document
    $self->ToggleSelected
      (
       Document => $document1,
      );
  }
  if ($args{Selection} eq "Toggle-Union") {
    # this means to toggle the item selected
    $self->ToggleSelected
      (
       Document => $document1,
      );
  }
  if ($args{Selection} eq "All") {
    foreach my $document ($self->Documents->Values) {
      if (! $self->Skip
	  (
	   Skip => $args{Skip},
	   Document => $document,
	  )) {
	$self->AddDocumentToSelection(Document => $document);
      }
    }
  }
  if ($args{Selection} eq "None") {
    foreach my $document ($self->Documents->Values) {
      if (! $self->Skip
	  (
	   Skip => $args{Skip},
	   Document => $document,
	  )) {
	$self->RemoveDocumentFromSelection
	  (
	   Document => $document,
	  );
      }
    }
  }
  if ($args{Selection} eq "Invert") {
    foreach my $document ($self->Documents->Values) {
      if (! $self->Skip
	  (
	   Skip => $args{Skip},
	   Document => $document,
	  )) {
	$self->ToggleSelected
	  (
	   Document => $document,
	  );
      }
    }
  }
  if ($args{Selection} eq "By Search") {
    # pop a window asking for a search, and match by name
    my $regex = QueryUser("Please enter RegEx Search:");
    if ($regex) {
      foreach my $document ($self->Documents->Values) {
	if ($document->FullText =~ /$regex/i) {
	  if (! $self->Skip
	      (
	       Skip => $args{Skip},
	       Document => $document,
	      )) {
	    # go ahead and add this document to the results


	    $self->AddDocumentToSelection(Document => $document);
	  }
	}
      }
    }
  }
  if ($args{Selection} eq "By Regex") {
    # pop a window asking for a search, and match by name
    my $regex = QueryUser("Please enter Regex:");
    if ($regex) {
      foreach my $document ($self->Documents->Values) {
	if ($document->FullText =~ /$regex/i) {
	  if (! $self->Skip
	      (
	       Skip => $args{Skip},
	       Document => $document,
	      )) {
	    $self->AddDocumentToSelection(Document => $document);
	  }
	}
      }
    }
  }
  if ($args{Selection} eq "By Entailment") {
    my $entailment = QueryUser("Please enter Entailment:");
    if ($entailment) {
      foreach my $document ($self->Documents->Values) {
	if (Entails
	    (
	     T => $entailment,
	     H => $document->Description,
	    )) {
	  if (! $self->Skip
	      (
	       Skip => $args{Skip},
	       Document => $document,
	      )) {
	    $self->AddDocumentToSelection(Document => $document);
	  }
	}
      }
    }
  }
  $self->PrintSelectionOrder();
}

sub Entails {
  my ($self,%args) = @_;
  print "Entailment not yet implemented\n";
  return 0;
}

sub Skip {
  my ($self,%args) = @_;
  if ($args{Skip}) {
    foreach my $document2 (@{$args{Skip}}) {
      if ($args{Document}->Equals(Document => $document2)) {
	return 1;
      }
    }
  }
  return 0;
}

sub ToggleSelected {
  my ($self,%args) = @_;
  my $document1 = $args{Document};
  if (defined $document1) {
    if ($document1->Selected) {
      $self->RemoveDocumentFromSelection
	(
	 Document => $document1,
	);
    } else {
      $self->AddDocumentToSelection
	(
	 Document => $document1,
	);
    }
  }
}

sub AddDocumentToSelection {
  my ($self,%args) = @_;
  my $document1 = $args{Document};
  # first remove the document from the selection if it already exists
  $self->RemoveDocumentFromSelection
    (
     Document => $document1,
    );
  # then add it
  push @{$self->SelectionOrder}, $document1;
  $document1->Selected(1);
}

sub RemoveDocumentFromSelection {
  my ($self,%args) = @_;
  my $document1 = $args{Document};

  # could have something here which looked to see if it was already
  # deselected and just skipped it
  if (! $document1->Selected) {
    return;
  }

  my @newqueue;
  foreach my $document2 (@{$self->SelectionOrder}) {
    if (! $document1->Equals(Document => $document2)) {
      push @newqueue, $document2;
    }
  }
  $self->SelectionOrder(\@newqueue);
  $document1->Selected(0);
}


sub PrintSelectionOrder {
  my ($self,%args) = @_;
  foreach my $document (@{$self->SelectionOrder}) {
    # print "[".$document->DocumentID."]\n";
  }
}

1;

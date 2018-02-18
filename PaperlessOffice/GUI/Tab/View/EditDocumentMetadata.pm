package PaperlessOffice::GUI::Tab::View::EditDocumentMetadata;

# Manager::Dialog

use PerlLib::EasyPersist;
use PerlLib::SwissArmyKnife;

use Tk;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Top1 Verbose Data Fields MyView Mapping Order Document
	DocumentID Multivalued /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyView($args{View});
  $self->Verbose($args{Verbose} || 0);
  my $title = "Edit Document Metadata";
  $self->Document($args{Document});
  my $documentid = $self->Document->DocumentID;
  $self->DocumentID($documentid);
  print Dumper($documentid);
  $self->Data({});
  my $multivalued = {
		     "has-folder" => 1,
		     "has-tag" => 1,
		    };
  $self->Multivalued($multivalued);
  my $mapping =
    {
     "Thumbnail" => "has-thumbnail",
     "Type" => "has-type",
     "Folders" => "has-folder",
     "Title" => "has-title",
     "Description" => "has-description",
     "FullText" => "has-fulltext",
     "DateTimeStamp" => "has-datetimestamp",
     "Tags" => "has-tag",
     "Temporal Constraints" => "",
     "Recurrence" => "",
     "Status" => "",
     "Dependencies" => "",
     "Predependencies" => "",
     "Eases" => "",
     "Blocking Issues" => "",
     "Labor Involved" => "",
    };
  $self->Mapping($mapping);
  my @order =
    (

     "Thumbnail","Type","Folders","Title","Description","FullText",
     "DateTimeStamp", "Tags", "Temporal Constraints", "Recurrence",
     "Status", "Dependencies", "Predependencies", "Eases",
     "Blocking Issues", "Labor Involved",

    );
  $self->Order(\@order);
  foreach my $field (@order) {
    if ($mapping->{$field}) {
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
	(
	 DocumentID => $documentid,
	 Predicate => $mapping->{$field},
	);
      if ($res->{Success}) {
	$self->Data->{$field} = $res->{Result};
      } else {
	$self->Data->{$field} = undef;
      }
    } else {
      $self->Data->{$field} = undef;
    }
  }
  $self->Top1
    ($args{MainWindow}->Toplevel
     (
      -title => $title,
      -height => 600,
      -width => 800,
     ));

  # might make more sense just to sql or iterate over the KB here
  # rather than query all of these?  then again, hrm, editable versus
  # consequential?

  my $term = [];
  my $queries =
    [
     # BINARY RELATIONS

     #  cross-term
     ["depends", $term, \*{'::?Term'}],
     ["eases", $term, \*{'::?Term'}],
     ["provides", $term, \*{'::?Term'}],
     ["prefer", $term, \*{'::?Term'}],

     ["depends", \*{'::?Term'}, $term],
     ["eases", \*{'::?Term'}, $term],
     ["provides", \*{'::?Term'}, $term],
     ["prefer", \*{'::?Term'}, $term],

     #  other
     ["has-NL", $term, \*{'::?NatLang'}],
     ["pse-has-property", $term, \*{'::?Property'}],
     ["due-date-for-entry", $term, \*{'::?DueDate'}],
     ["start-date", $term, \*{'::?StartDate'}],
     ["end-date", $term, \*{'::?EndDate'}],
     ["event-duration", $term, \*{'::?EventDuration'}],

     #  fields
     ["costs", $term, \*{'::?Cost'}],
     ["earns", $term, \*{'::?Cost'}],
     ["disputed", $term, \*{'::?Dispute'}],
     ["comment", $term, \*{'::?Cost'}],
     ["solution", $term, \*{'::?Solution'}],
     ["has-feeling", $term, \*{'::?Feeling'}],
     ["assigned-by", $term, \*{'::?AssignedBy'}],
     ["assigned-to", $term, \*{'::?AssignedTo'}],
     ["belongs-to-system", $term, \*{'::?System'}],

     # UNARY RELATIONS
     ["document", $term],

     # editable
     ["paid", $term],
     ["lost-original", $term],

     ["showstopper", $term],
     ["completed", $term],
     ["deleted", $term],
     ["cancelled", $term],
     ["ridiculous", $term],
     ["obsoleted", $term],
     ["rejected", $term],
     ["skipped", $term],
    ];

  # when you do what you need to do when it needs to be done, then you can do what you want to do when you want to"

  my $fields =
    {
     "Thumbnail" => {
		     Description => "The name of the thumbnail file",
		     Args => ["tinytext"],
		     TextVar => $self->Data->{Thumbnail},
		    },
     "Type" => {
		Description => "The type of document (i.e. ImagePDF, MultipleImages, SearchablePDF)",
		Args => ["tinytext"],
		TextVar => $self->Data->{Type},
	       },
     "Folders" => {
		   Description => "The Virtual Folders to which this document belongs",
		   Args => ["text"],
		   TextVar => join("\n", sort keys %{$self->Data->{Folders}}),
		  },
     "Title" => {
		 Description => "Document title if any",
		 Args => ["tinytext"],
		 TextVar => $self->Data->{Title},
		},
     "Description" => {
		       Description => "A user description of the document",
		       Args => ["text"],
		       TextVar => $self->Data->{Description},
		      },
     "FullText" => {
		    Description => "The text of the document likely obtained using OCR",
		    Args => ["text"],
		    TextVar => $self->Data->{FullText},
		   },
     "DateTimeStamp" => {
			 Description => "The creation timestamp",
			 Args => ["tinytext"],
			 TextVar => $self->Data->{DateTimeStamp},
			},

     "Tags" => {
		Description => "Classifying tags",
		Args => ["text"],
		TextVar => $self->Data->{Tags},
	       },
     "Temporal Constraints" => {
				Description => "timing considerations like due date, etc",
				# Args => ["temporal constraints"],
			       },
     "Recurrence" => {
		      Description => "schedule according to which this document repeats",
		     },
     "Status" => {
		  Description => "whether the document has been completed, etc",
		  Args => [["enum",["completed","deleted","etc"]]],
		 },
     "Dependencies" => {
			Description => "documents which this document depends upon for its completion",
			Args => ["array"],
		       },
     "Predependencies" => {
			   Description => "documents which depend upon this document for their completion",
			   Args => ["array"],
			  },
     "Eases" => {
		 Description => "other documents which this document makes easier or enables",
		 Args => ["array"],
		},
     "Blocking Issues" => {
			   Description => "critical reasons this document cannot currently be completed",
			   Args => ["array"],
			  },
     "Labor Involved" => {
			  Description => "the estimated amount of time and/or work required to complete this document",
			  Args => ["array"],
			 },
    };
  $self->Fields($fields);

  $options = $self->Top1->Frame();
  foreach my $field (@order) {
    if (! exists $fields->{$field}->{Args}) {
      $options->Checkbutton
	(
	 -text => $field,
	 -command => sub { },
	)->pack(-fill => "x");	# , -anchor => 'left');
    } else {
      my $frame = $options->Frame(-relief => 'raised', -borderwidth => 2);
      my @items;
      foreach my $arg2 (@{$fields->{$field}->{Args}}) {
	my $ref = ref $arg2;
	if ($ref eq "ARRAY") {
	  # skip for now
	  $options->Checkbutton
	    (
	     -text => $field,
	     -command => sub { },
	    )->pack(-fill => "x");
	} elsif ($ref eq "") {
	  if ($arg2 eq "tinytext") {
	    my $frame2 = $frame->Frame();
	    my $nameLabel = $frame2->Label
	      (
	       -text => $field,
	       -state => 'disabled',
	      );
	    my $name = $frame2->Entry
	      (
	       -state => 'disabled',
	       -relief       => 'sunken',
	       -borderwidth  => 2,
	       -textvariable => \$fields->{$field}->{TextVar},
	       -width        => 25,
	      );
	    push @items, {
			  frame => $frame2,
			  nameLabel => $nameLabel,
			  name => $name,
			 };
	    $nameLabel->pack(-side => 'left');
	    $name->pack(-side => 'right');
	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
	    # $self->Fields->{$field}->{Widget} = $name;
	    if ($self->Fields->{$field}->{TakeFocus}) {
	      $name->focus;
	    }
	  } elsif ($arg2 eq "text") {
	    my $frame2 = $frame->Frame();
	    my $state;
	    if ($fields->{$field}->{Normal}) {
	      $state = "normal";
	    } else {
	      $state = "disabled";
	    }
	    my $nameLabel = $frame2->Label
	      (
	       -text => $field,
	       -state => $state,
	      );
	    my $name = $frame2->Text
	      (
	       -relief       => 'sunken',
	       -borderwidth  => 2,
	       -width        => 80,
	       -height        => 5,
	      );
	    $name->Contents($fields->{$field}->{TextVar});
	    $name->configure(-state => $state);
	    push @items, {
			  frame => $frame2,
			  nameLabel => $nameLabel,
			  name => $name,
			 };
	    $nameLabel->pack(-side => 'left');
	    $name->pack(-side => 'right');
	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
	    $self->Fields->{$field}->{Widget} = $name;
	    if ($self->Fields->{$field}->{TakeFocus}) {
	      $name->focus;
	    }
	  } else {
	    # print Dumper({Huh => $arg2});
	  }
	}
      }
      my $checkbutton = $frame->Checkbutton
	(
	 -text => $field,
	 -command => sub {
	   foreach my $item (@items) {
	     if ($item->{name}->cget('-state') eq 'disabled') {
	       $item->{name}->configure(-state => "normal");
	       $item->{nameLabel}->configure(-state => "normal");
	     } else {
	       $item->{name}->configure(-state => "disabled");
	       $item->{nameLabel}->configure(-state => "disabled");
	     }
	   }
	 },
	);
      if ($fields->{$field}->{Normal}) {
	$checkbutton->{'Value'} = 1;
      } else {
	$checkbutton->{'Value'} = 0;
      }

      $checkbutton->pack(-fill => "x");
      foreach my $item (@items) {
	$item->{frame}->pack;
      }
      $frame->pack();
    }
  }
  $options->pack;

  $buttons = $self->Top1->Frame();
  $buttons->Button
    (
     -text => "Apply",
     -command => sub {$self->ActionApply},
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Save",
     -command => sub {$self->ActionSave},
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Cancel",
     -command => sub { $self->ActionCancel(); },
    )->pack(-side => "right");
  $buttons->pack;
  $self->Top1->bind
    (
     "all",
     "<Escape>",
     sub {
       $self->ActionCancel();
     },
    );
}

sub ActionApply {
  my ($self,%args) = @_;
  my $changes = 0;
  foreach my $field (@{$self->Order}) {
    my $predicate = $self->Mapping->{$field};
    my $value = $self->GetValueForField(Field => $field);
    if ($field eq "Title") {
      $self->Document->Title($value);
    }
    if ($predicate =~ /./) {
      if (exists $self->Multivalued->{$predicate}) {
	next;
	my %setargs =
	  (
	   DocumentID => $self->DocumentID,
	   Predicate => $predicate,
	   Values => $value,
	  );
	$UNIVERSAL::paperlessoffice->MyDocumentManager->SetMultivalued
	  (
	   %setargs,
	  );
      } else {
	my %setargs =
	  (
	   DocumentID => $self->DocumentID,
	   Predicate => $predicate,
	   Value => $value,
	  );
	print Dumper(\%setargs);
	 my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	  (
	   %setargs,
	  );
	if ($res->{Changes}) {
	  $changes = 1;
	}
      }
    }
  }
  if ($changes) {
    $self->Document->RedrawMyFolders();
  }
}

sub ActionSave {
  my ($self,%args) = @_;
  # just print out the configuration for now
  # print Dumper($self->Fields);
  $self->ActionApply();
  $self->DESTROY();
}

sub ActionCancel {
  my ($self,%args) = @_;
  # check for changes

  # if there are changes, prompt to determine whether to really cancel
  # or not
  $self->DESTROY();
}

sub DESTROY {
  my ($self,%args) = @_;
  $self->Top1->destroy;
}

1;

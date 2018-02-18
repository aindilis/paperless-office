package PaperlessOffice::GUI::Tab::View::Menus;

use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyMenu Menus Functions MyView Debug /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Debug($args{Debug});
  $self->MyView($args{View});
  $self->MyMenu({});
  $self->MyMenu->{Document} = $args{MainWindow}->Menu(-tearoff => 0);
  $self->MyMenu->{Blank} = $args{MainWindow}->Menu(-tearoff => 0);
  # have a draggable selection for goals, along with shift, etc,
  # clicking to select, etc
  # have zoom be bound to a control and something
  # Document
  $self->Menus
    ({
      Document =>
      [
       "Dismiss Menu", [],
       "Actions",
       [
	"View", [],
	"View Text", [],
	"Edit Image(s)", [],
	"Edit Page(s)", [],
	"Edit Metadata", [],
	"Form Filler", [],
	"Modify Folders", [],
	"Process",
	[
	 "Redo",
	 [
	  "OCR", [],
	  "Thumbnail", [],
	  "Classify", [],
	 ],
	 "Convert To",
	 [
	  "ImagePDF", [],
	  "SearchablePDF", [],
	  "MultipleImages", [],
	 ],
	 "Extract Dates", []
	],
	"Delete", [],
       ],
       "Flags",
       [
	"Set",
	[
	 "Showstopper", [],
	 "Complete", [],
	 "Incomplete", [],
	 "Deleted", [],
	 "Cancelled", [],
	 "Ridiculous", [],
	 "Obsolete", [],
	 "Rejected", [],
	 "Skipped", [],
	],
	"Remove",
	[
	 "Showstopper", [],
	 "Complete", [],
	 "Incomplete", [],
	 "Deleted", [],
	 "Cancelled", [],
	 "Ridiculous", [],
	 "Obsolete", [],
	 "Rejected", [],
	 "Skipped", [],
	],
       ],
       "Fields",
       [
	"Dispute", [],
	"Comment", [],
	"Describe Solution", [],
	"Assigned By", [],
	"Has Feeling", [],
	"Assigned By", [],
	"Assigned To", [],
	"Belongs to System", [],
       ],
       "Temporal Constraints",
       [
	"Duration",
	[
	 "Add", [],
	 "Clear", [],
	 "View Duration", [],
	 "Set Event Duration", [],
	],
	"Remit",
	[
	 "10 minutes", [],
	 "30 minutes", [],
	 "1 hour", [],
	 "3 hours", [],
	 "9 hours", [],
	 "1 day", [],
	 "3 days", [],
	 "1 week", [],
	 "1 month", [],
	],
	"Due Date",
	[
	 "Set", [],
	 "Remove", [],
	 "Set Start Date", [],
	 "Set End Date", [],
	 "Set Hard Deadline", [],
	 "Set Due Date From Calendar", [],
	 "Edit Due Date", [],
	 "Set Due Date Duration", [],
	],
       ],
      ],
      Blank =>
      [
       "Dismiss Menu", [],
       "Create",
       [
	"New Goal", [],
       ],
       "Quick",
       [
	"Goal",
	[
	 "10 minutes", [],
	 "30 minutes", [],
	 "1 hour", [],
	 "3 hours", [],
	 "9 hours", [],
	 "1 day", [],
	 "3 days", [],
	 "1 week", [],
	 "1 month", [],
	 "completed", [],
	],
	"New goal depends on this goal", [],
	"New goal eases this goal", [],
	"New goal is a precondition for this goal", [],
       ],
      ],
     });
  $self->Functions
    ({
      "Edit Metadata" => sub {
	$self->MyView->MenuActionEditMetadata(@_);
      },
      "View" => sub {
	$self->MyView->MenuActionView(@_);
      },
      "View Text" => sub {
	$self->MyView->MenuActionViewText(@_);
      },
      "Edit Image(s)" => sub {
	$self->MyView->MenuActionEditImages(@_);
      },
      "Edit Page(s)" => sub {
	$self->MyView->MenuActionEditPages(@_);
      },
      "Form Filler" => sub {
	$self->MyView->MenuActionFormFiller(@_);
      },
      "OCR" => sub {
	$self->MyView->MenuActionRedoOCR(@_);
      },
      "Thumbnail" => sub {
	$self->MyView->MenuActionRedoThumbnail(@_);
      },
      "Delete" => sub {
	$self->MyView->MenuActionDelete(@_);
      },
      "Classify" => sub {
	$self->MyView->MenuActionRedoClassify(@_);
      },
      "Modify Folders" => sub {
	$self->MyView->MenuActionModifyFolders(@_);
      },
      "ImagePDF" => sub {
	$self->MyView->MenuActionConvertTo(Type => "ImagePDF", @_);
      },
      "SearchablePDF" => sub {
	$self->MyView->MenuActionConvertTo(Type => "SearchablePDF", @_);
      },
      "MultipleImages" => sub {
	$self->MyView->MenuActionConvertTo(Type => "MultipleImages", @_);
      },
      "Action For Goal" => sub {},
      "Actions" => sub {},
      "Add" => sub {},
      "Agenda Editor" => sub {},
      "Assigned By" => sub {},
      "Assigned To" => sub {},
      "Belongs to System" => sub {},
      "Blank Menu" => sub {},
      "Cancelled" => sub {},
      "Clear" => sub {},
      "Comment" => sub {},
      "Complete" => sub {},
      "completed" => sub {},
      "Deleted" => sub {},
      "Depends on" => sub {},
      "Describe Solution" => sub {},
      "Dismiss Menu" => sub {},
      "Dispute" => sub {},
      "Due Date" => sub {},
      "Duration" => sub {},
      "Eases" => sub {},
      "Process" => sub {},
      "Edit Due Date" => sub {},
      "Fields" => sub {},
      "File" => sub {},
      "Fit Graph" => sub {},
      "Flags" => sub {},
      "Generate" => sub {},
      "Goal" => sub {},
      "Goal Menu" => sub {},
      "Has Feeling" => sub {},
      "Has Similar Goals" => sub {},
      "Hide" => sub {},
      "Incomplete" => sub {},
      "Load Data" => sub {},
      "LPG" => sub {},
      "Main Menu" => sub {},
      "Document" => sub {},
      "Obsolete" => sub {},
      "Options" => sub {},
      "Plan" => sub {},
      "Planner" => sub {},
      "Precondition for" => sub {},
      "Predepends on" => sub {},
      "Query Completed" => sub {},
      "Quick" => sub {},
      "Rejected" => sub {},
      "Relations" => sub {},
      "Remit" => sub {},
      "Remove" => sub {},
      "Ridiculous" => sub {},
      "Save Data" => sub {},
      "Set" => sub {},
      "Set Due Date Duration" => sub {},
      "Set Due Date From Calendar" => sub {},
      "Set End Date" => sub {},
      "Set Event Duration" => sub {},
      "Set Hard Deadline" => sub {},
      "Set Start Date" => sub {},
      "Showstopper" => sub {},
      "Skipped" => sub {},
      "Temporal Constraints" => sub {},
      "Uncancelled" => sub {},
      "Undeleted" => sub {},
     });
  # go ahead and add the folders/cabinets for the current cabinet here
}

sub LoadMenus {
  my ($self,%args) = @_;
  $self->AddMenus
    (
     Menu => $self->MyMenu->{Document},
     Spec => $self->Menus->{Document},
    );
  $self->AddMenus
    (
     Menu => $self->MyMenu->{Blank},
     Spec => $self->Menus->{Blank},
    );
}

sub AddMenus {
  my ($self,%args) = @_;
  my $spec = $args{Spec};
  my $ref = ref $spec;
  if ($ref eq "ARRAY") {
    while (scalar @$spec) {
      my $name = shift @$spec;
      my $newspec = shift @$spec;
      my $ref2 = ref $newspec;
      if ($ref2 eq "ARRAY") {
	if (! scalar @$newspec) {
	  # this is an empty menu item, so we should go ahead and
	  # look
	  print Dumper({NAME => $name}) if $self->Debug;
	  if (exists $self->Functions->{$name}) {
	    # construct new menus
	    print "<<<$name>>>\n" if $self->Debug;
	    $args{Menu}->command
	      (
	       -label => $name,
	       -command => $self->Functions->{$name},
	      );
	  } else {
	    print "Error 1\n" if $self->Debug;
	  }
	} else {
	  print "<$name>\n" if $self->Debug;
	  my $newmenu = $args{Menu}->cascade
	    (
	     -label => $name,
	     -tearoff => 0,
	    );
	  print Dumper({Newspec => $newspec}) if $self->Debug;
	  $self->AddMenus
	    (
	     Menu => $newmenu,
	     Spec => $newspec,
	    );
	}
      } else {
	print "Error 2\n" if $self->Debug;
      }
    }
  } else {
    print "Error 3\n" if $self->Debug;
  }
}

1;

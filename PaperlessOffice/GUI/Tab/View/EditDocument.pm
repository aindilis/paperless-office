package PaperlessOffice::GUI::Tab::View::EditDocument;

use PerlLib::EasyPersist;
use PerlLib::SwissArmyKnife;

use Tk;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Top1 Verbose Data /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Verbose($args{Verbose} || 0);
  $self->Data
    ($args{Data} ||
    {
     Source => "unilang",
     Name => "new-entry",
     Description => "Sample entry",
    });
  if (exists $args{Document}) {
    my $document = $args{Document};
    $self->Data->{Source} = $document->Source;
    # $self->Data->{Name} = $document->Name;
    $self->Data->{Description} = $document->Description;
  }
  $self->Top1
    ($args{MainWindow}->Toplevel
     (
      -title => "Edit Document",
      -height => 600,
      -width => 800,
     ));

  # when you do what you need to do when it needs to be done, then you can do what you want to do when you want to"
  my @order = ("Source", "Name", "Description",
	       "Temporal Constraints", "Recurrence", "Status", "Dependencies",
	       "Predependencies", "Eases", "Blocking Issues", "Labor Involved");

  my $fields =
    {
     "Source" => {
		  Description => "source from which this document came",
		  Args => ["tinytext"],
		  TextVar => $self->Data->{Source},
		 },
     "Name" => {
		Description => "document name",
		Args => ["tinytext"],
		  TextVar => $self->Data->{Name},
	       },
     "Description" => {
		       Description => "document description",
		       Args => ["text"],
		       TextVar => $self->Data->{Description},
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

  $options = $self->Top1->Frame();
  foreach my $field (@order) {
    if (! exists $fields->{$field}->{Args}) {
      $options->Checkbutton
	(
	 -text => $field,
	 -command => sub { },
	)->pack(-fill => "x");# , -anchor => 'left');
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
	  } elsif ($arg2 eq "text") {
	    my $frame2 = $frame->Frame();
	    my $nameLabel = $frame2->Label
	      (
	       -text => $field,
	       -state => 'disabled',
	      );
	    my $name = $frame2->Text
	      (
	       # -state => 'disabled',
	       -relief       => 'sunken',
	       -borderwidth  => 2,
	       -width        => 80,
	       -height        => 5,
	      );
	    $name->Contents($fields->{$field}->{TextVar});
	    $name->configure(-state => "disabled");
	    push @items, {
			  frame => $frame2,
			  nameLabel => $nameLabel,
			  name => $name,
			 };
	    $nameLabel->pack(-side => 'left');
	    $name->pack(-side => 'right');
	    $name->bind('<Return>' => [ $middle, 'color', Ev(['get'])]);
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
     -text => "Defaults",
     -command => sub { },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Save Configuration",
     -command => sub { },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Cancel",
     -command => sub { $self->Top1->destroy; },
    )->pack(-side => "right");
  $buttons->pack;
}

sub Execute {
  my ($self,%args) = @_;
}

sub ExecuteCommand {
  my ($self,%args) = @_;
  # get all the options, and run them
  # print join(" ",@args)."\n";
  # iterate over all the frames contained here
  foreach my $child ($self->Top1->children) {
    print Dumper($child);
  }
}

1;

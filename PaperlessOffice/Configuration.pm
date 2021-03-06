package PaperlessOffice::Configuration;

use Manager::Dialog qw(Approve ApproveCommands Choose Message QueryUser SubsetSelect);
use PerlLib::EasyPersist;
use PerlLib::SwissArmyKnife;

use Config::General;
use Tk;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Top1 Verbose Data MyConfig CurrentProfile MyMainWindow /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyMainWindow($args{MainWindow});
  $self->Verbose($args{Verbose} || 0);
  # use the data
  $self->MyConfig
    (Config::General->new
     (  $self->FindConfigFile));
  $self->Data
    ($args{Data} ||
     {
      Source => "unilang",
      Name => "new-entry",
      Description => "Sample entry",
     });
  $self->CurrentProfile($args{Profile});

  # when you do what you need to do when it needs to be done, then you
  # can do what you want to do when you want to"
}

sub FindConfigFile {
  my ($self,%args) = @_;
  my @files =
    (
     # $ENV{HOME}."/.config/frdcsa/paperless-office.conf",
     # $ENV{HOME}."/.paperless-office.conf",
     "paperless-office.conf",
    );
  foreach my $file (@files) {
    if (-f $file) {
      return $file;
    } else {
      print "no $file\n";
    }
  }
  die "No config file found!\n";
}

sub SelectProfile {
  my ($self,%args) = @_;
  my %profiles = $self->MyConfig->getall;
  my @profiles = keys %{$profiles{profiles}};
  my $profilename = Choose(@profiles);
  my $profile = $profiles{profiles}{$profilename};
  $self->CurrentProfile($profile);
}

sub EditProfile {
  my ($self,%args) = @_;
  my $profile = $self->CurrentProfile();
  $self->Top1
    ($self->MyMainWindow->Toplevel
     (
      -title => "Edit Profile",
      -height => 600,
      -width => 800,
     ));
  my @order = ();
  my $fields =
    {
     "Name" => {
		Description => "The user's name",
		Args => ["tinytext"],
		TextVar => $profile->{name},
	       },
     "Default Scanner" => {
			   Description => "The scanner to use",
			   Args => ["tinytext"],
			   TextVar => $profile->{mail}->{hostname},
			  },
     "Default OCR Agent" => {
			     Description => "The OCR engine",
			     # have an option to take one of a few args here
			     Args => ["tinytext"],
			     TextVar => $profile->{mail}->{hostname},
			    },
     "Default Classifier" => {
			      Description => "The classifying to classify new entries with",
			      Args => ["tinytext"],
			      TextVar => $profile->{mail}->{hostname},
			     },
     "Default Cabinet" => {
			   Description => "The cabinet to start out with",
			   Args => ["tinytext"],
			   TextVar => $profile->{url},
			  },
     "Default Folders" => {
			   Description => "The names of all the folders you want to have",
			   Args => ["text"],
			   TextVar => $profile->{mail}->{hostname},
			  },
    };

  $options = $self->Top1->Frame();
  foreach my $field (@order) {
    if (! exists $fields->{$field}->{Args}) {
      $options->Checkbutton
	(
	 -text => $field,
	 -command => sub { },
	)->pack(-fill => "x");
    } else {
      my $frame = $options->Frame(-relief => 'raised', -borderwidth => 2);
      my @items;
      foreach my $arg2 (@{$fields->{$field}->{Args}}) {
	my $ref = ref $arg2;
	if ($ref eq "ARRAY") {
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
	      );
	    my $name = $frame2->Entry
	      (
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
	  } elsif ($arg2 eq "mediumtext") {
	    my $frame2 = $frame->Frame();
	    my $nameLabel = $frame2->Label
	      (
	       -text => $field,
	      );
	    my $name = $frame2->Entry
	      (
	       -relief       => 'sunken',
	       -borderwidth  => 2,
	       -textvariable => \$fields->{$field}->{TextVar},
	       -width        => 80,
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
	      );
	    my $name = $frame2->Text
	      (
	       -relief       => 'sunken',
	       -borderwidth  => 2,
	       -width        => 80,
	       -height        => 5,
	      );
	    $name->Contents($fields->{$field}->{TextVar});
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
      foreach my $item (@items) {
	$item->{frame}->pack;
      }
      $frame->pack();
    }
  }
  $options->pack;

  $buttons = $self->Top1->Frame();
  #   $buttons->Button
  #     (
  #      -text => "Defaults",
  #      -command => sub { },
  #     )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Save Configuration",
     -command => sub {  },
    )->pack(-side => "left");
  $buttons->Button
    (
     -text => "Cancel",
     -command => sub { $self->Top1->destroy; },
    )->pack(-side => "right");
  $buttons->pack;
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

sub ProfileEmailAddress {
  my ($self,%args) = @_;
  return $self->CurrentProfile->{name}." <".
    $self->CurrentProfile->{mail}->{username}."@".
      $self->CurrentProfile->{mail}->{hostname}.">";
}

sub ListScanners {
  my ($self,%args) = @_;
  if (defined $self->CurrentProfile and
      defined $self->CurrentProfile->{scanners}) {
    if (ref($self->CurrentProfile->{scanners}{scanner}) eq "HASH") {
      return [$self->CurrentProfile->{scanners}{scanner}];
    } elsif (ref($self->CurrentProfile->{scanners}{scanner}) eq 'ARRAY') {
      return $self->CurrentProfile->{scanners}{scanner};
    } else {
      # throw error, unexpected parse result
    }
  } else {
    # throw error, no scanners
  }
}

sub PrintScannerName {
  my ($self,%args) = @_;
  my $scanner = $args{Scanner};
  $scanner->{'scanner-type'}.": ".$scanner->{'scanner-string'}
}

1;

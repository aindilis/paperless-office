package PaperlessOffice::GUI::Tab::View::DocumentEditor;

use Manager::Dialog qw(Approve ApproveCommands QueryUser);
use PaperlessOffice::Document::MultipleImages;
use PaperlessOffice::GUI::Tab::View::Folder;
use PerlLib::SwissArmyKnife;

use Event;
use File::Temp qw/ tempfile tempdir /;
# use Linux::Inotify2;
# use Term::ReadKey;
use Tk;
use Tk::JComboBox;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyView Top1 MyMainWindow ScanDir Book Resolution Pages
	ScanFinishedWatcher MyCanvas MyFolder MyCabinet Counter
	MyDocumentManager Data DocumentID /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyView($args{View});
  $self->MyCabinet($args{MyCabinet});
  $self->DocumentID($args{DocumentID});
  $self->MyMainWindow
    ($UNIVERSAL::paperlessoffice->MyGUI->MyMainWindow);
  $self->Top1
    ($self->MyMainWindow->Toplevel
     (
      # FIXME: add the title to the title
      -title => $self->FolderName,
     ));
  # pack all the buttons
  # we want to first
  $self->Pages([]);
  $self->Counter(0);
  $self->Data({});
}

sub FolderName {
  my ($self,%args) = @_;
  return "Edit Document ".$self->DocumentID;
}

sub Execute {
  my ($self,%args) = @_;
  # check the scanner connection
  print "Jebadiah\n";

  my $resaddfoldercabinet = $self->MyCabinet->AddFolder
    (
     FolderName => $self->FolderName,
    );

  my $resaddfolderview = $self->MyView->AddFolder
    (
     Name => $self->FolderName,
    );

  my $doview;

  # if the folder was already existing in the cabinet and was already
  # existing in the view, then we want to
  if ($resaddfoldercabinet->{PreexistingCabinet} and
      $resaddfoldercabinet->{PreexistingView}) {
    print "
  # if the folder was already existing in the cabinet and was already
  # existing in the view, then we want to
";
    $doview = 0;
  }

  # if the folder was already existing in the cabinet but was not
  # already existing in the view, then we want to add the folder to
  # the view
  if ($resaddfoldercabinet->{PreexistingCabinet} and
      ! $resaddfoldercabinet->{PreexistingView}) {
    print "
  # if the folder was already existing in the cabinet but was not
  # already existing in the view, then we want to add the folder to
  # the view
";
    $doview = 1;
  }

  # if the folder was not already existing in the cabinet but was
  # already existing in the view, then we want to flag an error,
  # because this should not occur
  if ($resaddfoldercabinet->{PreexistingCabinet} and
      $resaddfoldercabinet->{PreexistingView}) {
    # throw error
    print "
  # if the folder was not already existing in the cabinet but was
  # already existing in the view, then we want to flag an error,
  # because this should not occur
";

  }

  # if the folder was not already existing in the cabinet and was not
  # already existing in the view, then we want to create both for the
  # first time
  if (! $resaddfoldercabinet->{PreexistingCabinet} and
      ! $resaddfoldercabinet->{PreexistingView}) {
    print "
  # if the folder was not already existing in the cabinet and was not
  # already existing in the view, then we want to create both for the
  # first time
";
    $doview = 1;
  }

  my $folderframe;
  my $folder;
  if ($doview) {
    $folderframe = $self->Top1->Frame();
    $folder = PaperlessOffice::GUI::Tab::View::Folder->new
      (
       Name => $self->FolderName,
       Frame => $folderframe,
       Cabinet => $self->MyCabinet,
       MainWindow => $self->MyMainWindow,
       DocumentManager => $self->MyView->MyDocumentManager,
       View => $self->MyView,
       Detached => 1,
       Hidden => 1,
      );
    $folder->Execute();

    $folderframe->pack
      (
       -expand => 1,
       -fill => 'both',
      );

    # add have buttons here for

    $buttonframe = $self->Top1->Frame();
    $buttonframe->Button
      (
       -text => "Blah",
       -command => sub {$self->ActionBlah},
      )->pack(-side => "left");
    $buttonframe->Button
      (
       -text => "Done",
       -command => sub {$self->ActionDone},
      )->pack(-side => "left");
    $buttonframe->Button
      (
       -text => "Cancel",
       -command => sub {$self->ActionCancel},
      )->pack(-side => "left");
    $buttonframe->pack
      (
       # -expand => 1,
       -fill => 'x',
      );

    $self->Top1->bind
      (
       "all",
       "<Escape>",
       sub {
	 $self->Cancel();
       },
      );
    $self->Top1->geometry('1280x480');

    $self->LoadDocument();

  } else {
    print "Preexisting View\n";
    $folder = $resaddfoldercabinet->{Folder};
  }
  $self->MyFolder($folder);
}

sub LoadDocument {
  my ($self,%args) = @_;
  my $counter = 0;

  my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$self->DocumentID};

  my $editpagedir = '/tmp/paperless-office/edit-pages';
  $doc->GetPageImages;
  foreach my $page (@{$doc->PageIndexes}) {
    print "Page: <$page>\n";
    # create a new temporary document
    if (exists $doc->PageImages->[$page]) {
      my $targetdir = ConcatDir($editpagedir,'holding-area');
      if (! -d $editpagedir) {
	my $command1 = "mkdir -p ".shell_quote($targetdir);
	print "COMMAND: $command1\n";
	system $command1."\n";
      }
      my $command2 = "cp ".shell_quote($doc->PageImages->[$page])." ".shell_quote(ConcatDir($targetdir,'0.pnm'));
      print "COMMAND: $command2\n";
      system $command2."\n";

      my $directory = $UNIVERSAL::paperlessoffice->Cabinets->{$UNIVERSAL::paperlessoffice->CabinetName}->DocumentDirectory;
      my $tempdir = tempdir ( DIR => $directory );
      my $doc2 = PaperlessOffice::Document::MultipleImages->new
	(
	 Title => 'page: '.$page.' of '.$self->DocumentID,
	 File => ConcatDir($targetdir,'0.pnm'),
	 Directory => $tempdir,
	 Folders => {
		     $self->FolderName => 1,
		    },
	);
      print Dumper({Doc2DocumentID => $doc2->DocumentID});
      $doc2->GenerateThumbnail;
      $UNIVERSAL::paperlessoffice->MyDocumentManager->AddDocument
	(
	 Directory => basename($tempdir),
	 DocumentDirectory => $directory,
	);
      push @{$self->Pages}, $doc2;
      $self->Counter($self->Counter + 1);
    }
  }

  $self->MyFolder->Redraw
    (
     Redraw => 1,
     # Documents => [map {$_->DocumentID} @{$self->Pages}],
    );
}

sub ActionDone {
  my ($self,%args) = @_;
  # take all the docs and union them together into one

  my $incomingfolder = "Incoming";
  $self->MyView->AddFolder
    (
     Name => $incomingfolder,
    );

  # create a new document
  my $directory = $UNIVERSAL::paperlessoffice->Cabinets->{$UNIVERSAL::paperlessoffice->CabinetName}->DocumentDirectory;
  my $tempdir = tempdir ( DIR => $directory );

  # copy over the individual image files
  my $counter = 0;
  foreach my $doc (@{$self->Pages}) {
    if (! $counter) {
      # copy over the thumbnail
      push @commands, "cp ".shell_quote(ConcatDir($doc->Dir,"thumbnail.gif"))." ".shell_quote($tempdir);
    }
    push @commands, "cp ".shell_quote(ConcatDir($doc->Dir,"0.pnm"))." ".shell_quote(ConcatDir($tempdir,$counter.".pnm"));
    ++$counter;
  }
  ApproveCommands
    (
     Commands => \@commands,
     Method => "parallel",
     AutoApprove => 1,
    );
  foreach my $doc (@{$self->Pages}) {
    $doc->Delete();
  }
  my $doc = PaperlessOffice::Document::MultipleImages->new
    (
     Action => "load",
     File => $args{Filename},
     Directory => $tempdir,
     Folders => {
		 $incomingfolder => 1,
		},
    );

  $UNIVERSAL::paperlessoffice->MyDocumentManager->AddDocument
    (
     Directory => basename($tempdir),
     DocumentDirectory => $directory,
    );

  my $epoch = time;
  $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
    (
     DocumentID => basename($tempdir),
     Predicate => "has-datetimestamp",
     Value => $epoch,
    );

  $self->MyView->Folders->{$incomingfolder}->Redraw();
  $self->DESTROY();
}

sub ActionCancel {
  my ($self,%args) = @_;
  # remove the all the items from the directory
  foreach my $doc (@{$self->Pages}) {
    $doc->Delete();
  }
  $self->DESTROY;
}

sub DESTROY {
  my ($self,%args) = @_;
  $self->Top1->destroy;
}

# UpdateWithNewScannedItem

1;

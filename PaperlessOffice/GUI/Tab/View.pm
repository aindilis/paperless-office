package PaperlessOffice::GUI::Tab::View;

use Capability::TextSummarization;
use KBS2::Client;
use Manager::Dialog qw(Approve ApproveCommands Message QueryUser2);
use PerlLib::SwissArmyKnife;

use PaperlessOffice::GUI::Tab::View::Document;
use PaperlessOffice::GUI::Tab::View::DocumentEditor;
use PaperlessOffice::GUI::Tab::View::DocumentManager;
use PaperlessOffice::GUI::Tab::View::EditDocument;
use PaperlessOffice::GUI::Tab::View::Folder;
use PaperlessOffice::GUI::Tab::View::Importer;
use PaperlessOffice::GUI::Tab::View::Menus;
use PaperlessOffice::GUI::Tab::View::ScanNewDocuments;

use File::Temp qw(tempdir);
use Text::Wrap;
use Tk;
use Tk::Canvas;
use Tk::FileDialog;

use base qw(PaperlessOffice::GUI::Tab);

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyCabinet MyCabinetName MyFrame MyMainWindow MyDocumentManager
   MyDocumentEditor MyNoteBook MyImporter Folders MyScanNewDocuments
   AllowScrollingOfNotebookTabs /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyMainWindow($UNIVERSAL::paperlessoffice->MyGUI->MyMainWindow);
  $self->MyDocumentManager
    (PaperlessOffice::GUI::Tab::View::DocumentManager->new
     (MyView => $self));
  $self->AllowScrollingOfNotebookTabs(); # can be either "Canvas", "Frame", or undef
  if (defined $self->AllowScrollingOfNotebookTabs) {
    my $canvas = $args{Frame}->Scrolled
      (
       $self->AllowScrollingOfNotebookTabs,
       -background => 'white',
       -scrollbars => 'n',
      );
    $self->MyFrame($canvas);
    $args{Frame}->pack(-expand => 1, -fill => 'both');
  } else {
    $self->MyFrame($args{Frame});
  }
  $self->MyScanNewDocuments({});

  $UNIVERSAL::managerdialogtkwindow = $UNIVERSAL::paperlessoffice->MyGUI->MyMainWindow;
  $self->MyFrame->pack(-expand => 1, -fill => 'both');
  $self->SetCabinet
    (CabinetName => $UNIVERSAL::paperlessoffice->CabinetName);
  $self->Generate();
}

sub Generate {
  my ($self,%args) = @_;
  # unpack existing notebook if one exists
  if (defined $self->MyNoteBook) {
    foreach my $page ($self->MyNoteBook->pages) {
      $self->MyNoteBook->delete($page);
      $self->Folders->{$page}->DESTROY();
    }
  } else {
    $self->MyNoteBook
      ($self->MyFrame->NoteBook
       (
       ));
    if (defined $self->AllowScrollingOfNotebookTabs) {
      if ($self->AllowScrollingOfNotebookTabs eq "Canvas") {
	### embed the notebook widget into the canvas
	my $nb_in_canvas = $self->MyFrame->createWindow
	  ( 0, 0, -window => $self->MyNoteBook, -anchor => 'nw' );

	$self->MyFrame->update;
	### the whole notebook is larger than what can be initially displayed
	### so we'll have to sroll it later on in the program

	$self->MyFrame->configure
	  (
	   -scrollregion => [0,0,$self->MyNoteBook->reqwidth,$self->MyNoteBook->reqheight]
	  );
      }
    }
  }
  $self->Folders({});
  foreach my $foldername (sort keys %{$self->MyCabinet->Folders}) {
    $self->AddFolder
      (
       Name => $foldername,
      );
  }
  $self->MyNoteBook->pack(-expand => 1, -fill => 'both');
}

sub AddFolder {
  my ($self,%args) = @_;
  my $foldername = $args{Name};
  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->AddFolder
    (
     FolderName => $foldername,
    );
  if ($res->{Success}) {
    if (! exists $self->Folders->{$foldername}) {
      my $hidden = 0;
      if ($foldername eq 'Incoming from Scanner' or
	  $foldername =~ /^Edit Document .+$/) {
	$hidden = 1;
      }
      if (! $hidden) {
	# print Dumper({MyDocumentManager => [keys %{$self->MyDocumentManager}]});
	my $myframe = $self->MyNoteBook->add
	  (
	   $foldername,
	   -label => $foldername,
	  );
	my $folder = PaperlessOffice::GUI::Tab::View::Folder->new
	  (
	   Name => $foldername,
	   Frame => $myframe,
	   Cabinet => $self->MyCabinet,
	   MainWindow => $self->MyMainWindow,
	   DocumentManager => $self->MyDocumentManager,
	   View => $self,
	  );
	$self->Folders->{$foldername} = $folder;
	$folder->Execute();
	$res->{Hidden} = 0;
      } else {
	$res->{Hidden} = 1;
      }
      $res->{PreexistingView} = 0;
    } else {

      $res->{PreexistingView} = 1;
      $res->{Folder} = $self->Folders->{$foldername};
    }
    return $res;
  } else {
    return $res;
  }
}

sub Execute {
  my ($self,%args) = @_;
}

sub LoadCabinet {
  my ($self,%args) = @_;
  if (Approve("Close Existing Cabinet?")) {
    if ($args{CabinetName}) {
      $self->MyCabinetName($args{CabinetName});
    } else {
      $self->ChooseCabinet;
    }
  }
}

sub ChooseCabinet {
  my ($self,%args) = @_;
  my @set = ();
  my $cabinet = Choose(@set);
  $self->SetCabinet
    (CabinetName => $cabinet);
}

sub SetCabinet {
  my ($self,%args) = @_;
  $self->MyCabinetName
    ($args{CabinetName});
  $self->MyCabinet
    ($UNIVERSAL::paperlessoffice->Cabinets->{$self->MyCabinetName});
}

sub Import {
  my ($self,%args) = @_;
  my $importer = PaperlessOffice::GUI::Tab::View::Importer->new
    (
     View => $self,
    );
  $importer->Execute();
}

sub Select {
  my ($self,%args) = @_;
  $self->MyDocumentManager->Select
    (%args);
  foreach my $folder (values %{$self->Folders}) {
    $folder->Redraw();
  }
}

sub ProcessAllIncomingDocuments {
  my ($self,%args) = @_;
  # load the document with the instructions
  $self->ScanNewDocuments();
}

sub ScanNewDocuments {
  my ($self,%args) = @_;
  # we want to load a new object which is the scannewdocuments window
  my $scannerString = $args{ScannerData}->{'scanner-string'};
  $self->MyScanNewDocuments->{$scannerString} =
    PaperlessOffice::GUI::Tab::View::ScanNewDocuments->new
     (
      View => $self,
      MyCabinet => $self->MyCabinet,
      ScannerData => $args{ScannerData},
     );
  $self->MyScanNewDocuments->{$scannerString}->Execute();
}

sub MenuActionEditPages {
  my ($self,%args) = @_;
  # we want to load a new object which is the scannewdocuments window
  $self->MyDocumentEditor
    (PaperlessOffice::GUI::Tab::View::DocumentEditor->new
     (
      View => $self,
      MyCabinet => $self->MyCabinet,
      DocumentID => $args{DocumentID},
     ));
  $self->MyDocumentEditor->Execute();
}

sub SortBy {
  my ($self,%args) = @_;
  # okay, update the folders
  my @folders;
  if ($args{Scope} eq "All Folders") {
    push @folders, values %{$self->Folders};
  } elsif ($args{Scope} eq "Current Folder") {
    push @folders, $self->GetCurrentFolder;
  }
  foreach my $folder (@folders) {
    $folder->SortType($args{Type});
    $folder->SortDirection($args{Direction});
  }
  foreach my $folder (values %{$self->Folders}) {
    $folder->Redraw();
  }
}

sub GetCurrentFolder {
  my ($self,%args) = @_;
  return $self->Folders->{$self->MyNoteBook->raised()};
}

sub Backup {
  my ($self,%args) = @_;
  # go ahead and backup the item
  # figure out where they want to back up to, use the directory finder thing
  my $cabinetname = $self->MyCabinetName;
  my $datetimestamp = DateTimeStamp();
  my $defaultname = "backup-$cabinetname-$datetimestamp.tgz";
  # make a new toplevel
  my $choosebackupfile = $self->MyMainWindow->FileDialog
    (
     -Title => 'Choose Backup File',
     -File => $defaultname,
     -Create => 1,
    );
  $choosebackupfile->configure
    (
     -ShowAll => 'NO',
    );
  my $backupfile = $choosebackupfile->Show
    (
     -Horiz => 1,
    );
  if ($backupfile =~ /\.tgz$/) {
    my $contextname = $UNIVERSAL::paperlessoffice->MyDocumentManager->Context;
    my $cabinetlocation = $self->MyCabinet->Directory;
    my $tmpdir = tempdir( DIR => "/tmp/paperless-office" );
    write_file_dumper
      (
       File => ConcatDir($tmpdir,"metadata.dat"),
       Data => {
		CabinetName => $cabinetname,
		CabinetLocation => $cabinetlocation,
		Context => $contextname,
		BackupFileName => $backupfile,
		DateTimeStamp => $datetimestamp,
	       },
      );
    my $commands =
      [
       "cp -ar ".shell_quote($cabinetlocation)." ".shell_quote($tmpdir),
       "kbs2 -c ".shell_quote($contextname)." show > ".shell_quote(ConcatDir($tmpdir,$contextname.".kbs")),
       "cd ".shell_quote($tmpdir)." && tar czf ".shell_quote($backupfile)." .",
       "mv ".shell_quote($tmpdir)." /tmp/paperless-office/trash",
      ];
    ApproveCommands
      (
       Commands => $commands,
       Method => "serial",
       AutoApprove => $args{AutoApprove} || 1,
      );
  }
}

sub Restore {
  my ($self,%args) = @_;
  # figure out which file they wish to restore using the file finder thing
  my $choosebackupfile = $self->MyMainWindow->FileDialog
    (
     -Title => 'Choose Backup File',
    );
  $choosebackupfile->configure
    (
     -ShowAll => 'NO',
    );
  my $backupfile = $choosebackupfile->Show
    (
     -Horiz => 1,
    );
  if ($backupfile =~ /\.tgz$/) {
    # extract to a temp dir, and then swap with the current cabinet -
    # but not before asking...
    my $extractiondir = "/tmp/paperless-office/backup-extraction";
    my $commands =
      [
       "rm -rf /tmp/paperless-office/trash/*",
       "mv ".shell_quote($extractiondir)." /tmp/paperless-office/trash",
       "mkdir -p ".shell_quote($extractiondir),
       "cd ".shell_quote($extractiondir)." && tar xzf ".shell_quote($backupfile),
      ];
    ApproveCommands
      (
       Commands => $commands,
       Method => "serial",
      );
    my $metadatafilename = ConcatDir($extractiondir,"metadata.dat");
    if (-f $metadatafilename) {
      my $metadata = read_file_dedumper($metadatafilename);
      my $cabinetname = $metadata->{CabinetName};
      my $cabinetlocation = $metadata->{CabinetLocation};
      my $context = $metadata->{Context};
      my $datetimestamp = $metadata->{DateTimeStamp};

      my $cabinetdir;

      # figure out where, etc.
      if (Approve("Overwrite files for Cabinet $cabinetname with one from date-time $datetimestamp")) {
	# figure out the cabinet containing folder
	if (-d ConcatDir($UNIVERSAL::systemdir,"data","cabinets")) {
	  $cabinetdir = ConcatDir($UNIVERSAL::systemdir,"data","cabinets");
	} elsif (-d dirname($cabinetlocation)) {
	  $cabinetdir = dirname($cabinetlocation);
	} else {
	  Message(Message => "Unknown location of cabinet");
	}
      }
      if (defined $cabinetdir) {
	if (-d ConcatDir($cabinetdir,$cabinetname)) {
	  if (Approve("Overwrite cabinet $cabinetname with one from date-time $datetimestamp?")) {
	    my $commands =
	      [
	       "mv ".shell_quote(ConcatDir($cabinetdir,$cabinetname))." /tmp/paperless-office/trash",
	      ];
	    if (ApproveCommands
		(
		 Commands => $commands,
		 Method => "serial",
		)) {
	      if (Approve("Overwrite context $context with one from date-time $datetimestamp?")) {
		my $commands =
		  [
		   "mv ".shell_quote(ConcatDir($extractiondir,$cabinetname))." ".shell_quote($cabinetdir),
		   "kbs2 -c ".shell_quote($context)." clear",
		   "kbs2 -c ".shell_quote($context)." --no-checking --input-type \"Emacs String\" import ".shell_quote(ConcatDir($extractiondir,$context.".kbs")),
		   "rm -rf /tmp/paperless-office/trash/*",
		   "mv ".shell_quote($extractiondir)." /tmp/paperless-office/trash",
		  ];
		ApproveCommands
		  (
		   Commands => $commands,
		   Method => "serial",
		  );
	      }
	    }
	  }
	}
      }
    }
  }
}

sub EmptyTrash {
  my ($self,%args) = @_;
  # remove the files from /tmp/paperless-office/trash
  ApproveCommands
    (
     Commands => ["rm -rf /tmp/paperless-office/trash/*"],
     Method => "parallel",
    );
}

1;

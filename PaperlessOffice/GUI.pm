package PaperlessOffice::GUI;

use Manager::Dialog qw(Approve ApproveCommands);
use PerlLib::SwissArmyKnife;
use PaperlessOffice::Configuration;
use PaperlessOffice::GUI::TabManager;

use Tk;
use Tk::Menu;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyMainWindow MyTabManager MyConfiguration /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyMainWindow
    (MainWindow->new
     (
      -title => "Paperless Office",
      -width => 800,
      -height => 600,
     ));
  $UNIVERSAL::managerdialogtkwindow = $self->MyMainWindow;
  $self->MyConfiguration
    (PaperlessOffice::Configuration->new
     (MainWindow => $self->MyMainWindow));
  $self->MyConfiguration->SelectProfile();
  $self->LoadMenus();
}

sub Execute {
  my ($self,%args) = @_;
  $self->MyTabManager
    (PaperlessOffice::GUI::TabManager->new());
  $self->MyTabManager->Execute
    (MyMainWindow => $self->MyMainWindow);
  $self->MyMainWindow->geometry('1280x768');

  my $conf = $UNIVERSAL::paperlessoffice->Config->CLIConfig;
  if (exists $conf->{'-W'}) {
    $self->MyMainWindow->repeat
      (
       $conf->{'-W'} || 1000,
       sub {
	 $UNIVERSAL::agent->Deregister;
	 exit(0);
       },
      );
  }

  MainLoop();
}

sub LoadMenus {
  my ($self,%args) = @_;
  $menu = $self->MyMainWindow->Frame(-relief => 'raised', -borderwidth => '1');
  $menu->pack(-side => 'top', -fill => 'x');
  $menu_file_1 = $menu->Menubutton
    (
     -text => 'File',
     -tearoff => 0,
     -underline => 0,
    );

  my $newmenu = $menu_file_1->cascade
    (
     -label => 'New',
     -tearoff => 0,
     -underline => 0,
    );
  $newmenu->command
    (
     -label => "Folder",
     -command => sub {
       $UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->AddFolder();
       $self->GetCurrentTab->Generate();
     },
    );

  my $loadmenu = $menu_file_1->cascade
    (
     -label => 'Load Cabinet',
     -tearoff => 0,
     -underline => 0,
    );

  foreach my $cabinetname (sort keys %{$UNIVERSAL::paperlessoffice->Cabinets}) {
    print "$cabinetname\n";
    $loadmenu->command
      (
       -label => $cabinetname,
       -command => sub {
	 $self->GetCurrentTab->LoadCabinet
	   (CabinetName => $cabinetname);
       },
      );
  }

  $menu_file_1->command
    (
     -label => 'Import',
     -command => sub {
       $self->GetCurrentTab->Import();
     },
     -underline => 0,
    );
  $menu_file_1->command
    (
     -label => 'Backup',
     -command => sub {
       $self->GetCurrentTab->Backup();
     },
     -underline => 0,
    );
  $menu_file_1->command
    (
     -label => 'Restore',
     -command => sub {
       $self->GetCurrentTab->Restore();
     },
     -underline => 0,
    );
  $menu_file_1->command
    (
     -label => 'Exit',
     -command => sub {
       $self->Exit();
     },
     -underline => 0,
    );
  $menu_file_1->pack
    (
     -side => 'left',
    );

  ############################################################

  $menu_file_4 = $menu->Menubutton
    (
     -text => 'Select',
     -tearoff => 0,
     -underline => 0,
    );
  foreach my $action ("All","None","Invert","By Search","By Regex","By AGrep","By Entailment") {
    $menu_file_4->command
      (
       -label => $action,
       -command => sub {
	 $self->GetCurrentTab->Select
	   (Selection => $action);
       },
       -underline => 0,
      );
  }
  $menu_file_4->pack
    (
     -side => 'left',
    );

  ############################################################

  $menu_file_2 = $menu->Menubutton
    (
     -text => 'View',
     -tearoff => 0,
     -underline => 0,
    );

  my $sortmenu = $menu_file_2->cascade
    (
     -label => 'Sort',
     -tearoff => 0,
     -underline => 0,
    );

  foreach my $scope ("Current Folder","All Folders") {
    my $sortscope = $sortmenu->cascade
      (
       -label => $scope,
       -tearoff => 0,
       -underline => 0,
      );
    foreach my $type ("By Scan Date", "By File Date", "By First Mentioned Date", "By Average Mentioned Date", "By Last Mentioned Date") {
      my $sortdirection = $sortscope->cascade
	(
	 -label => $type,
	 -tearoff => 0,
	 -underline => 0,
	);
      foreach my $direction (qw(Ascending Descending)) {
	$sortdirection->command
	  (
	   -label => $direction,
	   -command => sub {
	     $self->GetCurrentTab->SortBy
	       (
		Type => $type,
		Direction => $direction,
		Scope => $scope,
	       );
	   },
	  );
      }
    }
  }

  $menu_file_2->command
    (
     -label => "Configuration",
     -command => sub {
       $self->EditConfiguration;
     },
     -underline => 0,
    );
  $menu_file_2->command
    (
     -label => "Calendar",
     -command => sub {
       $UNIVERSAL::paperlessoffice->MyDocumentManager->ShowCalendar();
     },
     -underline => 0,
    );
  $menu_file_2->command
    (
     -label => "Redraw Folder",
     -command => sub {
       $self->GetCurrentTab->GetCurrentFolder->Redraw();
     },
     -underline => 0,
    );
  $menu_file_2->pack
    (
     -side => 'left',
    );

  ############################################################

  $menu_file_3 = $menu->Menubutton
    (
     -text => 'Action',
     -tearoff => 0,
     -underline => 0,
    );
  $menu_file_3->command
    (
     -label => 'Process All Incoming Documents',
     -command => sub {
       # $self->GetCurrentTab->ProcessAllIncomingDocuments();
     },
     -underline => 0,
    );
  $menu_scan_new_documents = $menu_file_3->cascade
    (
     -label => 'Scan New Documents',
     -tearoff => 0,
     -underline => 0,
    );
  foreach my $scanner (@{$self->MyConfiguration->ListScanners}) {
    $menu_scan_new_documents->command
      (
       -label => $self->MyConfiguration->PrintScannerName(Scanner => $scanner),
       -command => sub {
  	 $self->GetCurrentTab->ScanNewDocuments(ScannerData => $scanner);
       },
       -underline => 0,
      );
  }
  $menu_file_3->command
    (
     -label => 'Classify All',
     -command => sub {
       $UNIVERSAL::paperlessoffice->MyDocumentManager->ClassifyAllUnclassifiedDocuments();
     },
     -underline => 0,
    );
  $menu_file_3->command
    (
     -label => 'Retrain',
     -command => sub {
       $UNIVERSAL::paperlessoffice->MyDocumentManager->RetrainTheDocumentClassifier();
     },
     -underline => 0,
    );
  $menu_file_3->command
    (
     -label => 'Analyze',
     -command => sub {
       $UNIVERSAL::paperlessoffice->MyDocumentManager->AnalyzeDocuments();
     },
     -underline => 0,
    );
  $menu_file_3->pack
    (
     -side => 'left',
    );

  $self->MyMainWindow->bind
    (
     'all',
     '<Control-s>',
     sub {
       $self->GetCurrentTab->Select
	 (
	  Selection => "By Search",
	 );
     },
    );
  $self->MyMainWindow->bind
    (
     'all',
     '<Control-n>',
     sub {
       # $self->GetCurrentTab->ScanNewDocuments();
     },
    );
  $self->MyMainWindow->bind
    (
     'all',
     '<Control-r>',
     sub {
       $self->GetCurrentTab->Redraw();
     },
    );
  $self->MyMainWindow->bind
    (
     'all',
     '<Control-q>',
     sub {
       $self->Exit();
     },
    );
}

sub GetCurrentTab {
  my ($self,%args) = @_;
  return $self->MyTabManager->Tabs->{$self->MyTabManager->MyNoteBook->raised()};
}

sub Exit {
  my ($self,%args) = @_;
  if (1) {
    my $dialog = $UNIVERSAL::managerdialogtkwindow->Dialog
      (
       -text => "Please Choose",
       -buttons => ["Exit", "Restart", "Reinvoke", "Cancel"],
      );
    my $res = $dialog->Show;
    if ($res eq "Exit") {
      exit(0);
    } elsif ($res eq "Restart") {
      # kill it and start a new one
      system "(sleep 1; /var/lib/myfrdcsa/codebases/minor/paperless-office/paperless-office) &";
      exit(0);
    } elsif ($res eq "Reinvoke") {
      # kill it and start a new one
      my $cli = GetCommandLineForCurrentProcess();
      system "(sleep 1; cd /var/lib/myfrdcsa/codebases/minor/paperless-office && $cli) &";
      exit(0);
    } elsif ($res eq "Cancel") {
      # do nothing
    }
  } else {
    if (Approve("Exit FRDCSA Applet?")) {
      exit(0);
    }
  }
}

sub EditConfiguration {
  my ($self,%args) = @_;
  $self->MyConfiguration->EditProfile();
}

1;

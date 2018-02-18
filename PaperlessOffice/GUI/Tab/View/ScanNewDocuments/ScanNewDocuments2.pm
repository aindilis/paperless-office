package PaperlessOffice::GUI::Tab::View::ScanNewDocuments2;

use Manager::Dialog qw(Approve ApproveCommands QueryUser);
use PaperlessOffice::Document::MultipleImages;
use PaperlessOffice::GUI::Tab::View::Folder;
use PerlLib::SwissArmyKnife;

use Event;
use File::Temp qw/ tempfile tempdir /;
use Linux::Inotify2;
use Term::ReadKey;
use Tk;
use Tk::JComboBox;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyView Top1 MyMainWindow ScanDir Book Resolution Pages
   ScanFinishedWatcher MyCanvas MyFolder MyCabinet Counter
   MyDocumentManager Data /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyView($args{View});
  $self->MyCabinet($args{MyCabinet});
  $self->MyMainWindow
    ($UNIVERSAL::paperlessoffice->MyGUI->MyMainWindow);
  $self->Top1
    ($self->MyMainWindow->Toplevel
     (
      -title => "Scan New Documents",
     ));
  # pack all the buttons
  # we want to first
  $self->Pages([]);
  $self->Counter(0);
  $self->Data({});
}

sub Execute {
  my ($self,%args) = @_;
  # check the scanner connection
  $self->CheckScannerConnection();

  # skip complicated stuff for now, just get something that runs

  # now we need to ask the user to sort his papers into the categories
  # that are important - where did I put that category list

  # Generate a process diagram for this using SPSE2

  # we first want to pop up and ask the user to sort papers into the
  # following categories

  # then process the scanning categories correctly

  # don't worry about the complex scan process for now, just implement
  # a basic one, can reimplement scannewdocuments2 later on

  # add cancel buttons, etc

  # we'll want a canvas here

  # document title (auto populate)

  # image location for thumbnails

  my $folderframe = $self->Top1->Frame();
  my $folder = PaperlessOffice::GUI::Tab::View::Folder->new
    (
     Name => "Incoming from Scanner",
     Frame => $folderframe,
     Cabinet => $self->MyCabinet,
     MainWindow => $self->MyMainWindow,
     # DocumentManager => $UNIVERSAL::paperlessoffice->MyDocumentManager,
     # I think this should be
     DocumentManager => $self->MyView->MyDocumentManager,
     # was View => $self,
     View => $self->MyView,
     Detached => 1,
    );
  $folder->Execute();

  $self->MyFolder($folder);
  $folderframe->pack
    (
     -expand => 1,
     -fill => 'both',
    );

  # go ahead and add new documents here

  my $optionframe = $self->Top1->Frame();
  my $mode = $optionframe->JComboBox
    (
     -choices =>
     [
      {-name => "Color Document", -selected => 1},
      {-name => "Black and White Document"},
      {-name => "Photo"},
     ],
    )->pack;
  my $resolution = $optionframe->JComboBox
    (
     -choices =>
     [
      {-name => "75 DPI"},
      {-name => "150 DPI", -selected => 1},
      {-name => "300 DPI"},
      {-name => "600 DPI"},
     ],
    )->pack;
  my $papersize = $optionframe->JComboBox
    (
     -choices =>
     [
      {-name => "Letter"},
      {-name => "Basic", -selected => 1},
      {-name => "A4"},
      {-name => "Legal"},
      {-name => "Full"},
     ],
    )->pack;
  $optionframe->pack();
  $self->Data->{Mode} = $mode;
  $self->Data->{Resolution} = $resolution;
  $self->Data->{PaperSize} = $papersize;

  # add an option for photo scanning

  $buttonframe = $self->Top1->Frame();
  $buttonframe->Button
    (
     -text => "Scan Next Page",
     -command => sub {$self->ActionScanNextPage},
    )->pack(-side => "left");
  $buttonframe->Button
    (
     -text => "Scan Next Page (ADF)",
     -command => sub {$self->ActionScanNextPageADF},
    )->pack(-side => "left");
  $buttonframe->Button
    (
     -text => "Scan Other Side",
     -command => sub {$self->ActionScanOtherSide},
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
  $self->Top1->geometry('640x480');
}

sub CheckScannerConnection {
  my ($self,%args) = @_;
  print "not yet implemented\n";
  # "scanimage -L";
}

sub ActionScanNextPage {
  my ($self,%args) = @_;
  $self->ScanNewImage
    ();
}

sub ActionScanNextPageADF {
  my ($self,%args) = @_;
  $self->ScanNewImage
    (
     Mode => "hp-adf",
    );
}

sub ActionScanOtherSide {
  my ($self,%args) = @_;
  $self->ScanNewImage
    ();
}

sub ActionDone {
  my ($self,%args) = @_;
  # take all the docs and union them together into one
  my $incomingfolder = "Incoming";
  my $res = $self->MyView->AddFolder
    (
     Name => $incomingfolder,
    );

  # FIXME: use return value of res, specifically, preexisting, and if
  # it already exists, figure out what to do whether that is balk or
  # what.

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

sub ScanNewImage {
  my ($self,%args) = @_;
  my $fn = "/tmp/paperless-office/0.pnm";

  my $tmp1 = $self->Data->{Mode}->getSelectedValue();;
  my $mode = "Color";
  if ($tmp1 eq "Color Document") {
    $mode = "Color";
  } elsif ($tmp1 eq "Grey Document") {
    $mode = "Gray";
  } elsif ($tmp1 eq "Black and White Document") {
    $mode = "Lineart";
  } elsif ($tmp1 eq "Photos") {
    $mode = "Color";
  }

  my $tmp2 = $self->Data->{Resolution}->getSelectedValue();
  my $resolution = 150;
  if ($tmp2 eq "75 DPI") {
    $resolution = 75;
  } elsif ($tmp2 eq "150 DPI") {
    $resolution = 150;
  } elsif ($tmp2 eq "300 DPI") {
    $resolution = 300;
  } elsif ($tmp2 eq "600 DPI") {
    $resolution = 600;
  }

  my $tmp3 = $self->Data->{PaperSize}->getSelectedValue();
  my $papersize;
  if ($args{Mode} eq "hp-adf") {
    $papersize = "0,0,215.9,297";
    if ($tmp2 eq "Letter") {
      $papersize = "0,0,215.9,279";
    } elsif ($tmp2 eq "A4") {
      $papersize = "0,0,210,297";
    } elsif ($tmp2 eq "Basic") {
      $papersize = "0,0,215.9,297";
    } elsif ($tmp2 eq "Legal") {
      $papersize = "0,0,215.9,356";
    } elsif ($tmp2 eq "Full") {
      $papersize = "0,0,215.9,381";
    }
  } else {
    $papersize = "-x 215.9 -y 297";
    if ($tmp2 eq "Letter") {
      $papersize = "-x 215.9 -y 279";
    } elsif ($tmp2 eq "A4") {
      $papersize = "-x 210 -y 297";
    } elsif ($tmp2 eq "Basic") {
      $papersize = "-x 215.9 -y 297";
    } elsif ($tmp2 eq "Legal") {
      $papersize = "-x 215.9 -y 356";
    } elsif ($tmp2 eq "Full") {
      $papersize = "-x 215.9 -y 381";
    }
  }

  # to obtain options:
  # sudo scanimage --help -d "hpaio:/net/Officejet_6300_series?ip=192.168.1.202"
  #  -l 0..215.9mm [0]
  #      Top-left x position of scan area.
  #  -t 0..381mm [0]
  #      Top-left y position of scan area.
  #  -x 0..215.9mm [215.9]
  #      Width of scan-area.
  #  -y 0..381mm [381]
  #      Height of scan-area.

  # $c = "sudo scanimage --resolution 300 -x 215 -y 297 > $fn";

  if ($args{Mode} eq "hp-adf") {
    $self->StartScanFinishedWatcherFn
      (
       FilenameTemplate => "/tmp/paperless-office/hpscan_pg\%s_001.png",
      );
  } else {
    $self->StartScanFinishedWatcherFn
      (
       Filename => $fn,
      );
  }
  my $scanfinishedtimestamp = $self->ScanFinishedWatcher->{ScanFinishedTimestamp};
  my @commands;

  # create a dialog warning about the scan in progress, with the option of cancelling
  if (exists $UNIVERSAL::paperlessoffice->Conf->{'-f'}) {
    push @commands, "cp /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport/documents/u24vqNMLnh/0.pnm ".shell_quote($fn)."; touch ".shell_quote($scanfinishedtimestamp),
  } else {
    if ($args{Mode} eq "hp-adf") {
      push @commands, "(cd /tmp/paperless-office && /var/lib/myfrdcsa/codebases/minor/paperless-office/scripts/hp-scan-paperless-office --adf --device=\"hpaio:/net/Officejet_6300_series?ip=192.168.1.202\" --res=$resolution --area=$papersize --mode ".lc($mode)." > ".shell_quote($fn)."; touch ".shell_quote($scanfinishedtimestamp).") &";
    } else {
      push @commands, "(sudo scanimage -d \"hpaio:/net/Officejet_6300_series?ip=192.168.1.202\" --resolution $resolution $papersize --mode $mode > ".shell_quote($fn)."; touch ".shell_quote($scanfinishedtimestamp).") &";
    }
  }
  ApproveCommands
    (
     Commands => \@commands,
     Method => "parallel",
     AutoApprove => 1,
    );
}

sub StartScanFinishedWatcherFn {
  my ($self,%args) = @_;
  $self->ScanFinishedWatcher({});
  $self->ScanFinishedWatcher->{Filename} = $args{Filename};
  if ($args{FilenameTemplate}) {
    $self->ScanFinishedWatcher->{FilenameTemplate} = $args{FilenameTemplate};
  }
  $self->ScanFinishedWatcher->{ScanFinishedTimestamp} = "/tmp/paperless-office/scan-finished.timestamp";
  $self->ScanFinishedWatcher->{Object} = $self->Top1->repeat
    (
     1,
     sub {$self->ScanFinishedWatcherFn()},
    );
  my $toplevel = $self->Top1->Toplevel
      (
       -title => "Scan New Documents",
      );
  $toplevel->Label
    (
     -text => "Scanning in progress",
    )->pack();
  $toplevel->Button
    (
     -text => "Cancel",
     -command => sub {$self->CancelScan},
    )->pack();
  $toplevel->geometry('200x70');
  $self->ScanFinishedWatcher->{Dialog} = $toplevel;
}

sub CancelScan {
  my ($self,%args) = @_;
  system "sudo killall -9 scanimage";
}

sub ScanFinishedWatcherFn {
  my ($self,%args) = @_;
  if (-f $self->ScanFinishedWatcher->{ScanFinishedTimestamp}) {
    if ($self->ScanFinishedWatcher->{FilenameTemplate}) {
      my $continue = 1;
      my $i = 1;
      while ($continue) {
	my $tmpfn = sprintf($self->ScanFinishedWatcher->{FilenameTemplate},$i);
	if (-f $tmpfn) {
	  system "convert ".shell_quote($tmpfn)." /tmp/paperless-office/$i.pnm";
	  system "rm ".shell_quote($tmpfn);
	  ++$i;
	} else {
	  $continue = 0;
	}
      }
    }
    $self->ScanFinishedWatcher->{Dialog}->destroy();
    $self->ScanFinishedWatcher->{Object}->cancel();
    system "rm ".shell_quote($self->ScanFinishedWatcher->{ScanFinishedTimestamp});
    $self->UpdateWithNewScannedItem
      (
       Filenames => $self->ScanFinishedWatcher->{Filename},
      );
  }
}

sub UpdateWithNewScannedItem {
  my ($self,%args) = @_;
  if (-f $args{Filename}) {
    my $directory = $UNIVERSAL::paperlessoffice->Cabinets->{$UNIVERSAL::paperlessoffice->CabinetName}->DocumentDirectory;
    my $tempdir = tempdir ( DIR => $directory );
    my $doc = PaperlessOffice::Document::MultipleImages->new
      (
       File => $args{Filename},
       Directory => $tempdir,
       Folders => {
		   "Incoming from Scanner" => 1,
		  },
      );
    $UNIVERSAL::paperlessoffice->MyDocumentManager->AddDocument
      (
       Directory => basename($tempdir),
       DocumentDirectory => $directory,
      );
    push @{$self->Pages}, $doc;
    $self->Counter($self->Counter + 1);
    $self->MyFolder->Redraw
      (
       Redraw => 1,
       Documents => [map {$_->DocumentID} @{$self->Pages}],
      );

    $self->Counter($self->Counter + 1);
    # use the same technique as importer to import a given raw document
    # however, store these items in a way that marks them as temporary
    # until the new item can be built by unifying them

    # for the initial phase, simply store them separately

    # default to putting them in incoming, unless the user allows them
    # to be auto classified

    # have the user place them in a particular folder in a particular
    # filing cabinet then.
  } else {
    print "Page missing!\n";
  }
}

sub GetCurrentImage {
  my ($self,%args) = @_;
  my $imagedir = $args{Directory};
  my @f = split /\n/,`ls -1 $imagedir/ | grep '\.pnm\$'`;
  if (! scalar @f) {
    return {
	    FN => "$imagedir/0.pnm",
	    PageNo => 0,
	   };
  } else {
    my $max = 0;
    foreach my $fi (@f) {
      $fi =~ s/\.pnm$//;
      if ($fi > $max) {
	$max = $fi;
      }
    }
    $max += 1;
    return {
	    FN => "$imagedir/$max.pnm",
	    PageNo => $max,
	   };
  }
}

1;

# sub GetUsersAttention {
#   my ($self,%args) = @_;
#   print "Waiting for your approval to continue.  Press return exactly once.\n";
#   ReadMode "cbreak";
#   my $okayed = 0;
#   while (!$okayed) {
#     foreach my $i (1..3) {
#       next if $okayed;
#       system "sudo beep";
#       if (defined ($key = ReadKey(-1))) {
# 	$okayed = 1;
#       } else {
# 	sleep 1;
#       }
#     }
#     if (defined ($key = ReadKey(-1))) {
#       $okayed = 1;
#     } else {
#       sleep 3;
#     }
#   }
#   ReadMode "normal";
#   print "Approved.\n";
# }

# (System
#  (Hardware
#   (Scanner)
#   (Buckets
#    (To Scan
#     )
#    (To Scan Backup)
#    (To be classified into To Scan or To Dispose)
#    (To Dispose)
#    )
#   (Filing Cabinets
#    (Top Unit
#     (Top Shelf
#      )
#     (Bottom Shelf)
#     )
#    (Bottom Unit
#     (Top Shelf)
#     (Bottom Shelf)
#     )
#    )
#   )
#  (Software
#   (Paperless-Office software)
#   (Paperport)
#   )
#
#  (Processes
#
#   )
#  )

# (paperwork
#  (finish the system that processes scanned mail for dates and stuff)
#  (solution
#   (write a program that collates scanned in documents appropriately
#    when I have double sided pages and I do the multiple scans)
#   (this can be done manually for now with unstack and stack)
#   )
#  (fix those files that need reordering, write those scripts that do that)
#  (put a movie on in the background while scanning)
#  (periodically clean surface of flatbed scanner)

# sort your papers into different piles

#  (here is the deal with scanning
#   (categories
#    (automatic tray feeder
#     (single page single sided a4)
#     (single page double sided a4)
#     (multi page)
#     )
#    (flatbed
#     (single page single sided)
#     (single page double sided)
#     (multi page)
#     )
#    )
#   )

#  (come up with explanation of the filing cabinet, along with a map of all the different type of folders
#   (label everything)
#   (have a "to read" folder)
#   )
#  (shredder)
#  )

# (here is the process for scanning documents
#  (take the to-scan bin and go through documents
#   (if the document is in an envelope, rip out of envelope and put envelope into to-shred bin)
#   (if the document is an opened envelope, put in the to-shred pile)
#   (if the document is multipaged)

#   )

#  (separate all files)
#  (for receipts)
#  )

# sub CheckIfFileIsFinished {
#   my ($self,%args) = @_;
#   # check on the existence of this file, check on its size
#   if (-e $args{File}) {
#     $stat = File::Stat->new($args{File});
#     my $size = $stat->size;
#     if (($size > 0) and ($size == $lastsize)) {
#       ++$count;
#       print "Looking good...\n";
#     } else {
#       if ($count) {
# 	print "Oops, still more...\n";
#       }
#       $count = 0;
#     }
#     $lastsize = $size;
#     sleep 5;
#   }
#   if ($count >= 5) {
#     return {
# 	    Success => 1,
# 	   };
#   }
#   return {
# 	  Success => 0,
# 	 };
# }

# sub StartScanFinishedWatcherFnOriginal {
#   my ($self,%args) = @_;
#   $self->ScanFinishedWatcher({});
#   $self->ScanFinishedWatcher->{Filename} = $args{Filename};
#   $self->ScanFinishedWatcher->{ScanFinishedTimestamp} = "/tmp/paperless-office/scan-finished.timestamp";
#   $self->ScanFinishedWatcher->{Object} = $self->Top1->repeat
#     (
#      1,
#      sub {$self->ScanFinishedWatcherFn()},
#     );
#   $self->ScanFinishedWatcher->{Inotify} = Linux::Inotify2->new();
#   #   Event->io
#   #     (
#   #      fd => $self->ScanFinishedWatcher->{Inotify}->fileno,
#   #      poll => 'r',
#   #      cb => sub { $self->ScanFinishedWatcher->{Inotify}->poll },
#   #     );
#   $self->ScanFinishedWatcher->{Inotify}->watch
#     (
#      $self->ScanFinishedWatcher->{ScanFinishedTimestamp},
#      IN_ACCESS,
#      sub {
#        my $e = shift;
#        my $name = $e->fullname;
#        print "$name was accessed\n" if $e->IN_ACCESS;
#        print "$name is no longer mounted\n" if $e->IN_UNMOUNT;
#        print "$name is gone\n" if $e->IN_IGNORED;
#        print "events for $name have been lost\n" if $e->IN_Q_OVERFLOW;
#        # cancel this watcher: remove no further events
#        $e->w->cancel;
#        $self->ScanFinishedWatcher->{Object}->cancel();
#        system "rm ".shell_quote($self->ScanFinishedWatcher->{ScanFinishedTimestamp});

#        $self->UpdateWithNewScannedItem
# 	 (
# 	  Filename => $self->ScanFinishedWatcher->{Filename},
# 	 );
#      },
#     );
# }

# sub ScanFinishedWatcherFnOrig {
#   my ($self,%args) = @_;
#   $self->ScanFinishedWatcher->{Inotify}->poll;
# }

# use the same technique as importer to import a given raw document
# however, store these items in a way that marks them as temporary
# until the new item can be built by unifying them

# for the initial phase, simply store them separately

# default to putting them in incoming, unless the user allows them
# to be auto classified

# have the user place them in a particular folder in a particular
# filing cabinet then.

# set it to incoming for now

# then
# my $doc =
# $self->LoadOCR;
# $doc->OCR;
# $self->LoadDocumentClassifier;
# $self->MyDocumentClassifier->Classify
#   (Document => $doc);
# return $doc;

package PaperlessOffice::GUI::Tab::View::Folder;

use Manager::Dialog qw(Choose2);
use PaperlessOffice::GUI::Tab::View::EditDocumentMetadata;
use PaperlessOffice::GUI::Tab::View::Menus;
use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Name MyFrame MyCabinet MyMainWindow MyViewDocumentManager
	MyCanvas Text SkipCanvasBind Offset Columns HorizontalSpacing
	VerticalSpacing MyMenus LastTags LastEvent LastDocID MyView
	Photos Detached SortType SortDirection Images Thumbnails
	Hidden MyFolders /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Name($args{Name});
  $self->MyFrame($args{Frame});
  $self->MyCabinet($args{Cabinet});
  $self->MyMainWindow($args{MainWindow});
  $self->MyViewDocumentManager($args{DocumentManager});
  $self->MyView($args{View});
  $self->MyCanvas
    ($self->MyFrame->Scrolled
     (
      "Canvas",
      -background => 'white',
      -scrollbars => 'sw',
     ))->pack( -expand => 1,  -fill => 'both' );

  $Text::Wrap::columns = 40;
  $self->Text({});
  $self->Images({});
  $self->Photos({});
  $self->Thumbnails({});
  $self->SkipCanvasBind(0);
  $self->Offset(20);
  $self->Columns(10);
  $self->HorizontalSpacing(120);
  $self->VerticalSpacing(200);
  $self->Detached($args{Detached});
  $self->SortType($args{SortType} || "By Scan Date");
  $self->SortDirection($args{SortType} || "Descending");
  $self->Hidden($args{Hidden});
}

sub Execute {
  my ($self,%args) = @_;
  $self->MyMenus
    (PaperlessOffice::GUI::Tab::View::Menus->new
     (
      MainWindow => $self->MyCanvas,
      View => $self,
     ));
  $self->MyMenus->LoadMenus;
  $self->Display();
  $self->Generate();
  # $self->MyCanvas->repeat(1, sub {$self->Check()});
}

sub Display {
  my ($self,%args) = @_;
  $self->MyCanvas->bind
    (
     'all',
     '<Button-1>',
     sub {
       my $docid = $self->GetDocumentID
	 (
	  Canvas => $self->MyCanvas,
	 );

       # print Dumper(keys %{$UNIVERSAL::paperlessoffice->MyDocumentManager->Documents});
       if (defined $docid) {
	 my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
	 # go ahead and toggle the item
	 # print Dumper({AndyDocumentID => $doc->DocumentID});
	 $self->MyViewDocumentManager->Select
	   (
	    Selection => "Toggle-Single",
	    Document => $doc
	   );
	 $self->Redraw;
       }
     },
    );

  $self->MyCanvas->bind
    (
     'all',
     '<Shift-Button-1>',
     sub {
       my $docid = $self->GetDocumentID
	 (
	  Canvas => $self->MyCanvas,
	 );
       # print Dumper(keys %{$UNIVERSAL::paperlessoffice->MyDocumentManager->Documents});
       if (defined $docid) {
	 my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
	 # go ahead and toggle the item
	 $self->MyViewDocumentManager->Select
	   (
	    Selection => "Toggle-Union",
	    Document => $doc
	   );
	 $self->Redraw;
       }
     },
    );

  $self->MyCanvas->bind
    (
     'all',
     '<3>',
     sub {
       my $docid = $self->GetDocumentID
	 (
	  Canvas => $self->MyCanvas,
	 );
       # print Dumper(keys %{$UNIVERSAL::paperlessoffice->MyDocumentManager->Documents});
       if (defined $docid) {
         $self->ShowMenu
	   (
	    Items => \@_,
	    Type => "Document",
	   );
       } else {
         $self->ShowMenu
	   (
	    Items => \@_,
	    Type => "Blank",
	   );
       }
     },
    );
}

sub GetDocumentID {
  my ($self, %args) = @_;
  my $item = $args{Canvas}->find('withtag', 'current');
  my @taglist = $args{Canvas}->gettags($item);
  my $docid;
  foreach (@taglist) {
    next if ($_ eq 'current');
    next if ($_ eq 'image');
    $docid = $_;
    last;
  }
  print "<DocID: $docid>\n";
  $self->LastDocID($docid);
  return $docid;
}


sub SetLastTags {
  my ($self,%args) = @_;
  my @lasttags = $self->MyCanvas->gettags('all');
  # print Dumper(\@lasttags);
  pop @lasttags;
  $self->LastTags({@lasttags});
}

sub Check {
  my ($self,%args) = @_;
}

sub ShowMenu {
  my ($self,%args) = @_;
  # print Dumper({Args => \%args});

  my $w = shift @{$args{Items}};
  my $Ev = $w->XEvent;
  $self->LastEvent($Ev);
  # unpost any other menus
  foreach my $menutype (keys %{$self->MyMenus->MyMenu}) {
    $self->MyMenus->MyMenu->{$menutype}->unpost();
  }
  $self->MyMenus->MyMenu->{$args{Type}}->post($Ev->X, $Ev->Y);
  # and set the menu information to contain this
}

sub Generate {
  my ($self,%args) = @_;
  $self->Redraw
    (
     Redraw => 0,
    );
}

sub GetPositionForImage {
  my ($self,%args) = @_;
  my $y1 = int($args{Number} / $self->Columns) * $self->VerticalSpacing + $self->Offset;
  my $x1 = ($args{Number} % $self->Columns) * $self->HorizontalSpacing + $self->Offset;
  return ($x1,$y1);
}

sub AddDocument {
  my ($self,%args) = @_;
  # print Dumper($args{DocumentID});
  my $document = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$args{DocumentID}};
  # print Dumper($document);
  my $imagename = "thumbnail-".$self->Name."-".$document->DocumentID;
  if (! exists $self->Thumbnails->{$imagename}) {
    $self->Thumbnails->{$imagename} = $document->GetThumbnail;
  }
  my $thumbnail = $self->Thumbnails->{$imagename};
  my ($x1,$y1) = $self->GetPositionForImage
    (Number => $args{Number});
  if (! exists $self->Photos->{$imagename}) {
    $self->Photos->{$imagename} = $self->MyCanvas->Photo
      (
       $imagename,
       -file => $thumbnail->File,
      );
  }
  my $imagex = $x1 + $thumbnail->Width / 2;
  my $imagey = $y1 + $thumbnail->Height / 2;
  if (1) {
    my $id = $self->MyCanvas->createImage
      ($imagex, $imagey,
       -image => $imagename,
       -tags => [$document->DocumentID,"image"],
      );
  } else {
    if (! exists $self->Images->{$imagename}) {
      my $id = $self->MyCanvas->createImage
	($imagex, $imagey,
	 -image => $imagename,
	 -tags => [$document->DocumentID,"image"],
	);
      $self->Images->{$imagename} = {
				     ID => $id,
				     ImageX => $imagex,
				     ImageY => $imagey,
				    };
    } else {
      # mv it to the new location
      my $entry = $self->Images->{$imagename};
      my $id = $entry->{ID};
      my $oldimagex = $entry->{ImageX};
      my $oldimagey = $entry->{ImageY};
      $self->MyCanvas->move($id, $imagex - $oldimagex, $imagey - $oldimagey);
      $self->Images->{$imagename} = {
				     ID => $id,
				     ImageX => $imagex,
				     ImageY => $imagey,
				    };
    }
  }
  if ($document->Selected) {
    $self->MyCanvas->createRectangle
      (
       $x1,$y1,$x1+$thumbnail->Width,$y1+$thumbnail->Height,
       -fill => 'black',
       -stipple => 'gray50',
       -tags => [$document->DocumentID,"selection"],
      );
  }

  # if document has a title, display it at the bottom
  if (defined $document->Title and $document->Title =~ /./) {
    $self->MyCanvas->createText
      (
       $x1+($thumbnail->Width/2),$y1+$thumbnail->Height + 5,
       -anchor => 'n',
       -text => $document->Title,
       -width => $thumbnail->Width,
       -tags => ["text"],
      );
  }

  # # add tags here
  # $self->MyCanvas->addtag($args{Number}, "withtag", $id);
  # $self->MyCanvas->addtag($id, "withtag", $id);

  # print Dumper({No => $args{Number}});

  # draw a border
  $self->MyCanvas->createLine
    (
     $x1+$thumbnail->Width,$y1,
     $x1,$y1,
     $x1,$y1+$thumbnail->Height,
     -width => 1,
     -tags => ["topline"],
    );
  $self->MyCanvas->createLine
    (
     $x1,$y1+$thumbnail->Height,
     $x1+$thumbnail->Width,$y1+$thumbnail->Height,
     $x1+$thumbnail->Width,$y1,
     -width => 2,
     -tags => ["bottomline"],
    );
}

sub RemoveDocument {
  my ($self,%args) = @_;
  # ???
}

sub EditDocument {
  my ($self,@tmp) = @_;
  # get the document from the click and then view it or something...
  $self->MyView->EditDocument();
  # $self->Redraw();
}

sub ViewDocument {
  my ($self,@tmp) = @_;
  # get the document from the click and then view it or something...
}

sub ProcessDocument {
  my ($self,@tmp) = @_;
  # get the document from the click and then view it or something...
}

sub Select {
  my ($self,%args) = @_;
  $self->MyViewDocumentManager->Select(%args);
  $self->Redraw();
}

sub Redraw {
  my ($self,%args) = @_;
  # probably have to clear the canvas somehow

  # have to have a better way of sorting these than randomly like this
  # by date, etc

  # delete everything but the images

  # print Dumper($self->MyCanvas->find('all'));

  #   foreach my $id ($self->MyCanvas->find('all')) {
  #     my @taglist = $self->MyCanvas->gettags($id);
  #     print Dumper({$id => \@taglist});
  #     # $self->MyCanvas->delete($id);
  #   }
  if (0) {
    foreach my $id ($self->MyCanvas->find('withtag', 'text^bottomline^topline^selection')) {
      $self->MyCanvas->delete($id);
      # my @taglist = $self->MyCanvas->gettags($id);
      # print Dumper({$id => \@taglist});
    }
  } else {
    $self->MyCanvas->delete('all');
  }
  my $i = 0;
  my @documents;
  if (exists $args{Documents}) { #  or $self->Detached) {
    @documents = @{$args{Documents} || []};
  } else {
    my $folderdocs = exists $self->MyCabinet->Folders->{$self->Name} ? $self->MyCabinet->Folders->{$self->Name}->Documents : {};
    # "By Scan Date", "By File Date", "By First Mentioned Date", "By Average Mentioned Date", "By Last Mentioned Date"
    if ($self->SortType eq "Unsorted") {
      @documents = sort keys %$folderdocs;
    } elsif ($self->SortType eq "By Scan Date") {
      @documents = sort {$folderdocs->{$a}->GetDate(Type => "Scan") <=> $folderdocs->{$b}->GetDate(Type => "Scan")} keys %$folderdocs;
    } elsif ($self->SortType eq "By File Date") {
      @documents = sort {$folderdocs->{$a}->GetDate(Type => "File") <=> $folderdocs->{$b}->GetDate(Type => "File")} keys %$folderdocs;
    } elsif ($self->SortType eq "By First Mentioned Date") {
      @documents = sort {$folderdocs->{$a}->GetDate(Type => "First Mentioned") <=> $folderdocs->{$b}->GetDate(Type => "First Mentioned")} keys %$folderdocs;
    } elsif ($self->SortType eq "By Average Mentioned Date") {
      @documents = sort {$folderdocs->{$a}->GetDate(Type => "Average Mentioned") <=> $folderdocs->{$b}->GetDate(Type => "Average Mentioned")} keys %$folderdocs;
    } elsif ($self->SortType eq "By Last Mentioned Date") {
      @documents = sort {$folderdocs->{$a}->GetDate(Type => "Last Mentioned") <=> $folderdocs->{$b}->GetDate(Type => "Last Mentioned")} keys %$folderdocs;
    }
    if ($self->SortDirection eq "Descending") {
      @documents = reverse @documents;
    }
  }
  print Dumper({FolderDocs => \@documents});
  foreach my $docid (@documents) {
    $self->AddDocument
      (
       Redraw => $args{Redraw} || 1,
       DocumentID => $docid,
       Number => $i,
      );
    ++$i;
  }
}

sub MenuActionView {
  my ($self,%args) = @_;
  print "Viewing\n";
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    $doc->MenuActionView();
  }
}

sub MenuActionViewText {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->MenuActionViewText();
    }
  }
}

sub MenuActionEditImages {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->MenuActionEditImages();
    }
  }
}

sub MenuActionEditPages {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->MenuActionEditPages();
    }
  }
}

sub MenuActionEditMetadata {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      my $editmetadata = PaperlessOffice::GUI::Tab::View::EditDocumentMetadata->new
	(
	 Document => $doc,
	 View => $self,
	 MainWindow => $self->MyMainWindow,
	);
    }
  }
}

sub MenuActionFormFiller {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->MenuActionFormFiller();
    }
  }
}

sub MenuActionRedoOCR {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->OCR;
    }
  }
}

sub MenuActionRedoThumbnail {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->GenerateThumbnail
	(Regenerate => 1);
    }
  }
}

sub MenuActionRedoClassify {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $UNIVERSAL::paperlessoffice->MyResources->LoadDocumentClassifier();
      $UNIVERSAL::paperlessoffice->MyResources->MyClassifier->Classify
	(
	 Document => $doc
	);
    }
  }
}


sub MenuActionDelete {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      if (Approve("Delete Document ".$docid."?")) {
	$doc->Delete();
      }
    }
  }
}

sub MenuActionModifyFolders {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      my $newfolderlabel = "*** New Folder ***";
      # my $incomingfromscannerlabel = "Incoming from Scanner";
      my $createnew = 1;
      my %originalfolders = %{$doc->Folders};
      my %copy = %originalfolders;;
      my $folders = \%copy;
      while ($createnew) {
	$createnew = 0;
	my @folders = grep {exists $self->MyCabinet->Folders->{$_} and ! $self->MyCabinet->Folders->{$_}->Hidden}
	  keys %{$UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->Folders};
	# my @folders = SubtractList
	#   (
	#    A => [keys %{$UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->Folders}],
	#    B => [$incomingfromscannerlabel],
	#   );
	my @res = SubsetSelect
	  (
	   Title => "Please choose the folders for this item",
	   Set => [$newfolderlabel, sort @folders],
	   Selection => $folders,
	  );

	foreach my $foldername (@res) {
	  if ($foldername eq $newfolderlabel) {
	    $createnew = 1;
	  }
	}

	$folders = {};
	foreach my $foldername (@res) {
	  if (exists $UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->Folders->{$foldername}) {
	    $folders->{$foldername} = 1;
	  }
	}

	if ($createnew) {
	  # my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->AddFolder();
	  my $res = $self->MyView->AddFolder();
	  if ($res->{Success}) {
	    $folders->{$res->{Result}} = 1;
	  }
	}
      }

      my $res = $doc->MoveToFolders
	(
	 Folders => $folders,
	);
      if ($res->{Success}) {
	foreach my $foldername (keys %originalfolders) {
	  if (exists $self->MyCabinet->Folders->{$foldername}) {
	    next if $self->MyCabinet->Folders->{$foldername}->Hidden;
	    print "Skipping foldername: <$foldername>\n";
	  } else {
	    print "Unknown foldername: <$foldername>\n";
	    next;
	  }
	  # next if $foldername eq $incomingfromscannerlabel;
	  print "Redrawing foldername: <$foldername>\n";
	  $UNIVERSAL::paperlessoffice->MyGUI->MyTabManager->Tabs->{"View"}->Folders->{$foldername}->Redraw();
	}
	$doc->RedrawMyFolders();
      }
    }
  }
}

sub MenuActionConvertTo {
  my ($self,%args) = @_;
  my $docid = $self->LastDocID;
  if (defined $docid) {
    my $doc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$docid};
    if (defined $doc) {
      $doc->ConvertTo(%args);
    }
  }
}

sub DESTROY {
  my ($self,%args) = @_;
}

1;

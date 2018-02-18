package PaperlessOffice::Document::MultipleImages;

use base qw(PaperlessOffice::Document);

use Manager::Dialog qw(ApproveCommands Message);
use PaperlessOffice::GUI::Tab::View::Image;
use PerlLib::SwissArmyKnife;

use File::DirList;
use File::Stat;
use IO::File;
use String::ShellQuote;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / PageIndexes /

  ];

sub init {
  my ($self,%args) = @_;
  $self->PageIndexes([]);
  $self->SUPER::init(%args);
  if ($args{Action} ne "load") {
    # check for more filenames similar to the starting one
    if ($args{FileTemplate}) {
      my $i = 1;
      my $continue = 1;
      while ($continue) {
	my $dir = dirname($args{File});
	my $tmpfn = ConcatDir($dir,sprintf($args{FileTemplate},$i));
	print "FILE IS ".$tmpfn."\n";
	if (-f $tmpfn) {
	  my $quotedfile = shell_quote($tmpfn);
	  my $quoteddir = $self->QuotedDir;
	  ApproveCommands
	    (
	     Commands => ["mv $quotedfile $quoteddir"],
	     Method => "parallel",
	     AutoApprove => $args{AutoApprove} || 1,
	    );
	  ++$i;
	} else {
	  $continue = 0;
	}
      }
    }
  }
}

sub Classify {
  my ($self,%args) = @_;
  # $self->SUPER::Classify(%args);
}

sub Summary {
  my ($self,%args) = @_;
  # handle all filenames
  # $self->SUPER::Summary(%args);
}

sub IsEmptyAndShouldBeDeleted {
  my ($self,%args) = @_;
  return 0;
  # $self->SUPER::IsEmptyAndShouldBeDeleted(%args);
  my $count = scalar @{$self->PageImages};
  if ($count == 0) {
    return 1;
  } elsif ($count == 1) {
    my $stat =  File::Stat->new($self->PageImages->[0]);
    return ($stat->size == 0);
  }
}

sub InitializeDocument {
  my ($self,%args) = @_;
  $self->GetPageImages;
}

sub GetPageImages {
  my ($self,%args) = @_;
  my $documentdirectory = $self->Directory;
  my @f = split /\n/,`ls -1 $documentdirectory/ | grep '\.pnm\$'`;
  if (! scalar @f) {
    # nothing to do
  } else {
    foreach my $fi (@f) {
      $fi =~ s/\.pnm$//;
      $self->PageImages->[$fi] = "$documentdirectory/$fi.pnm";
      $self->PageIndexes->[$fi] = $fi;
      if (-f "$documentdirectory/$fi.pnm.txt") {
	$self->PageTexts->[$fi] = "$documentdirectory/$fi.pnm.txt";
      }
    }
  }
}

sub FullText {
  my ($self,%args) = @_;
  if (! $self->SUPER::FullTextContents) {
    my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
      (
       DocumentID => $self->DocumentID,
       Predicate => "has-fulltext",
      );
    if (! $res->{Success}) {
      $self->OCR;
      $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-fulltext",
	);
    }
    if ($res->{Success}) {
      $self->SUPER::FullTextContents($res->{Result});
    } else {
      print "Error obtaining FullText for document ".$self->DocumentID."\n";
    }
  }
  return $self->SUPER::FullTextContents;
}

sub GeneratePDF {
  my ($self,%args) = @_;

}

sub GenerateThumbnail {
  my ($self,%args) = @_;
  my $thumbnailfile = ConcatDir($self->Directory,"thumbnail.gif");
  if (! -f $thumbnailfile or $args{Regenerate}) {
    # try to convert the image
    # get 0.pnm and convert that to a thumbnail
    my $res = ApproveCommands
      (
       Commands =>
       [
	"convert -thumbnail 100 ".shell_quote(ConcatDir($self->Directory,"0.pnm"))." ".shell_quote($thumbnailfile),
       ],
       Method => "parallel",
       AutoApprove => $args{AutoApprove} || 1,
      );
    if ($res) {
      if (-f $thumbnailfile) {
	# assert this as the thumbnail file
	my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	  (
	   DocumentID => $self->DocumentID,
	   Predicate => "has-thumbnail",
	   Value => "thumbnail.gif",
	  );
      } else {
	# assert that the thumbnail file could not be generated
	my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	  (
	   DocumentID => $self->DocumentID,
	   Predicate => "has-thumbnail",
	   Value => "Generation failed",
	  );
      }
    } else {
      # assert that we haven't attempted to generate the thumbnailfile
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-thumbnail",
	 Value => "Not yet generated",
	);
    }
  } else {
    my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
      (
       DocumentID => $self->DocumentID,
       Predicate => "has-thumbnail",
       Value => "thumbnail.gif",
      );
  }
}

sub GetThumbnail {
  my ($self,%args) = @_;
  $self->SUPER::GetThumbnail(%args);
}

sub MenuActionView {
  my ($self,%args) = @_;
  my $quoteddir = $self->QuotedDir;
  my @commands;
  foreach my $file (split /\n/, `ls $quoteddir`) {
    if ($file =~ /\.pnm$/) {
      my $tmp = shell_quote(ConcatDir($self->Dir,$file));
      push @commands, "xview $tmp &";
    }
  }
  ApproveCommands
    (
     Commands => \@commands,
     Method => "parallel",
     AutoApprove => 1,
    );
}

sub MenuActionViewText {
  my ($self,%args) = @_;
  my $fh = IO::File->new();
  my $tmpfile = "/tmp/paperless-office/doc.txt";
  $fh->open(">$tmpfile") or warn "cannot open";
  print $fh $self->FullText;
  $fh->close();
  ApproveCommands
    (
     Commands => [
		  "gedit ".shell_quote($tmpfile)." &",
		 ],
     Method => "parallel",
     AutoApprove => 1,
    );
}

sub MenuActionEditImages {
  my ($self,%args) = @_;
  my $quoteddir = $self->QuotedDir;
  my @files;
  foreach my $file (split /\n/, `ls $quoteddir`) {
    if ($file =~ /\.pnm$/) {
      push @files, shell_quote(ConcatDir($self->Dir,$file));
    }
  }
  my $command = "gimp ".join(" ", @files)." &";
  ApproveCommands
    (
     Commands => [$command],
     Method => "parallel",
     AutoApprove => 1,
    );
}

sub MenuActionEditPages {
  my ($self,%args) = @_;
  $UNIVERSAL::paperlessoffice->MyGUI->MyTabManager->Tabs->{"View"}->MenuActionEditPages
    (DocumentID => $self->{DocumentID});
}

sub MenuActionFormFiller {
  my ($self,%args) = @_;
  # convert image to PDF?
  Message(Message => "Convert image to PDF first please");
}

sub ConvertTo {
  my ($self,%args) = @_;
  if ($args{Type} eq "ImagePDF") {
    $self->ConvertToImagePDF();
  }
}

sub ConvertToImagePDF {
  my ($self,%args) = @_;
  # set the type to the new one
  # my $documentdirectory = $self->Directory;

  # FIXME: this should care about the ordering of the pnm files
  ApproveCommands
    (
     Commands => ["cd ".shell_quote($self->Dir)." && convert -define pdf:use-trimbox=true *.pnm document.pdf"],
     Method => "parallel",
     AutoApprove => $args{AutoApprove} || 1,
    );

  if (-f ConcatDir($self->Dir,"document.pdf")) {
    ApproveCommands
      (
       Commands => ["mv ".ConcatDir($self->Dir,"*.pnm")." /tmp/paperless-office/trash"],
       Method => "parallel",
       AutoApprove => $args{AutoApprove} || 1,
      );
    # now, edit the metadata, then reload
    my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
      (
       DocumentID => $self->DocumentID,
       Predicate => "has-type",
       Value => "ImagePDF",
      );
    # now we need to simply reload everything?  or how do we do this?
    # first we delete references to this document
    $UNIVERSAL::paperlessoffice->MyGUI->GetCurrentTab->MyDocumentManager->RemoveDocument
      (
       Document => $self,
      );
    $UNIVERSAL::paperlessoffice->MyDocumentManager->RemoveDocument
      (
       Document => $self,
      );
    $UNIVERSAL::paperlessoffice->MyDocumentManager->AddDocument
      (
       Directory => $self->Dir,
       DocumentDirectory => $documentdirectory,
       DeleteIfNecessary => 1,
      );
    my $newdoc = $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$self->{DocumentID}};
    $UNIVERSAL::paperlessoffice->MyGUI->GetCurrentTab->MyDocumentManager->AddDocument
      (
       Document => $newdoc,
      );
    foreach my $foldername (keys %{$newdoc->Folders}) {
      $UNIVERSAL::paperlessoffice->MyGUI->GetCurrentTab->Folders->{$foldername}->Redraw();
    }
    $self->DESTROY();
  } else {
    Message(Message => "Conversion failed");
  }
}

sub OCR {
  my ($self,%args) = @_;
  # do we put in a thing to test whether fulltext already exists?  I
  # think we did

  my $quoteddir = $self->QuotedDir;
  my @text;


  my $list = File::DirList::list($quoteddir, 'n', 1, 1, 0);
  foreach my $file (sort {$a <=> $b} grep /\.pnm$/, map {$_->[13]} @$list) {
    my $res = $UNIVERSAL::paperlessoffice->MyResources->MyOCR->OCRImage
      (
       ImageFile => ConcatDir($self->Dir,$file),
       SkipRotations => 1,
      );
    print Dumper($res);
    if ($res->{Success}) {
      push @text, $res->{Text};
    }
  }
  my $fulltext = join
    (
     # "\n\f",
     "\n",
     map {
       s/[[:^ascii:]]/ /g;
       s/[[:cntrl:]]/ /g;
       $_;
     } @text);
  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-fulltext",
     Value => $fulltext,
    );
  $self->SUPER::FullTextContents
    ($fulltext);
}

sub DESTROY {
  my ($self,%args) = @_;
}

1;

# PaperlessOffice::GUI::Tab::View::DocumentManager->Documents->{$docid} = $newdoc;

# PaperlessOffice::DocumentManager->Documents->{$docid} = $newdoc;
# PaperlessOffice::Cabinet->Documents->{$docid} = $newdoc;
# PaperlessOffice::Cabinet::Folder->Documents->{$docid} = $newdoc;

# $UNIVERSAL::paperlessoffice->MyDocumentManager->RemoveDocument
# then we create a new document and put it's references in there
#     my $newdoc = PaperlessOffice::Document::ImagePDF->new
#       (
#        File => ConcatDir($self->Dir,"document.pdf"),
#        Directory => $self->Dir,
#        Folders => $self->Folders,
#        Action => "load",
#        AutoApprove => 0,
#       );
#     $newdoc->Execute();

#     my $docid = $newdoc->DocumentID;

# PaperlessOffice::DocumentManager->Documents->{$docid} = $newdoc;
# PaperlessOffice::Cabinet->Documents->{$docid} = $newdoc;
# PaperlessOffice::Cabinet::Folder->Documents->{$docid} = $newdoc;

# we want to first change the metadata regarding this item


# $self->GetCurrentTab->PaperlessOffice::GUI::Tab::View::DocumentManager->Documents->{$self->DocumentID} =
# $UNIVERSAL::paperlessoffice->MyDocumentManager->Documents->{$self->{DocumentID}};

# then we redraw containing folders
# foreach my $foldername ($newdoc->Folders) {

# }

# then we destroy this document

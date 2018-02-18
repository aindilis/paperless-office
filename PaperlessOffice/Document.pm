package PaperlessOffice::Document;

use Manager::Dialog qw(ApproveCommands Message);
use PaperlessOffice::GUI::Tab::View::Image;
use PerlLib::SwissArmyKnife;

use File::Stat;
use IO::File;
use String::ShellQuote;
use SUPER;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Directory PhysicalLocation Categories OCRedP FullTextContents
	QuotedFile QuotedDir TargetFile QuotedTargetFile File Dir
	Title Initialized PageImages PageTexts Folders DocumentID
	Selected /

  ];

sub init {
  my ($self,%args) = @_;
  print "PaperlessOffice::Document->init\n" if $UNIVERSAL::paperlessoffice->Debug;

  $self->PageImages([]);
  $self->PageTexts([]);
  $self->Directory($args{Directory});

  # figure out what type of file this is and run the appropriate import
  # just use pdf for now
  $self->DocumentID(basename($self->Directory));
  $self->Dir($self->Directory);
  my $dir = $self->Dir;
  $self->File($args{File});
  $self->QuotedDir(shell_quote($self->Directory));
  my $quoteddir = $self->QuotedDir;
  my $file = $self->File;
  $self->QuotedFile(shell_quote($file));
  my $quotedfile = $self->QuotedFile;
  my $targetfile = $file;
  $targetfile =~ s/^.*\///;
  $targetfile = $self->Directory."/".$targetfile;
  $self->TargetFile($targetfile);
  $self->QuotedTargetFile(shell_quote($targetfile));

  my $folders;
  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-folder",
     Multivalued => 1,
    );
  if ($res->{Success}) {
    if (ref $res->{Result} eq "HASH") {
      $folders = $res->{Result};
    } else {
      die "Error with result ".Dumper($res->{Result});
    }
  } else {
    $folders = $args{Folders} || { Incoming => 1 };
    foreach my $foldername (keys %$folders) {
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-folder",
	 Value => $foldername,
	 Multivalued => 1,
	);
    }
  }
  $self->Folders($folders);
  if ($args{Action} ne "load") {
    if (ApproveCommands
	(
	 Commands => ["cp $quotedfile $quoteddir"],
	 Method => "parallel",
	 AutoApprove => $args{AutoApprove} || 1,
	)) {
      # go ahead and assert metadata for the title as being possible title
      my $potentialtitle = basename($file);
      $potentialtitle =~ s/\.(pdf|jpg|gif|pnm|html|htm)$//i;
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-title",
	 Value => defined $args{Title} ? $args{Title} : $potentialtitle,
	);
    }
  }
  my $res2 = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-title",
     Multivalued => 1,
    );
  if ($res2->{Success}) {
    $self->Title($res2->{Result});
  }
}

sub Execute {
  my ($self,%args) = @_;
}

sub Classify {
  my ($self,%args) = @_;
  $UNIVERSAL::paperlessoffice->LoadDocumentClassifier;
  $UNIVERSAL::paperlessoffice->MyDocumentClassifier->Classify
    (Document => $self);
}

sub Summary {
  my ($self,%args) = @_;
  # generate a short auto summary of the document
  # summarize the full text
  my $res = $UNIVERSAL::paperlessoffice->SummarizeText
    ($self->FullText);
  if ($res->{Success}) {
    return $res->{Result};
  } else {
    print "ERROR Summarizing\n";
  }
}

sub IsEmptyAndShouldBeDeleted {
  my ($self,%args) = @_;
  return 0;

  if (! $self->Initialized) {
    # $self->InitializeDocument;
  }
  if (! scalar @{$self->PageImages}) {

  }
}

sub Delete {
  my ($self,%args) = @_;
  my $documentid = $self->DocumentID;
  system "mv ".shell_quote($self->Dir)." /tmp/paperless-office/trash";
  # now unassert all of the metadata about this item
  $UNIVERSAL::paperlessoffice->MyDocumentManager->DeleteMetadata
    (
     DocumentID => $documentid,
    );
  # $self->RemoveDocument
  # ();
}

sub RemoveDocument {
  my ($self,%args) = @_;
}

sub GetThumbnail {
  my ($self,%args) = @_;
  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-thumbnail",
    );
  if ($res->{Success}) {
    if ($res->{Result} eq "Not yet generated") {
      $self->GenerateThumbnail;
      return $self->GetThumbnail;
    } elsif ($res->{Result} eq "Generation failed") {
      # do nothing
    } else {
      my $file = ConcatDir($self->Directory,$res->{Result});
      if (-f $file) {
	return PaperlessOffice::GUI::Tab::View::Image->new
	  (
	   File => $file,
	  );
      }
    }
  } else {
    $self->GenerateThumbnail;
    return $self->GetThumbnail;
  }
  return PaperlessOffice::GUI::Tab::View::Image->new
    (
     File => "/var/lib/myfrdcsa/codebases/minor/paperless-office/thumbnail.gif",
    );

}

sub Equals {
  my ($self,%args) = @_;
  return $args{Document}->DocumentID eq $self->DocumentID;
}

sub OCR {
  my ($self,%args) = @_;
  Message(Message =>  "Not yet implemented");
}

sub GetDate {
  my ($self,%args) = @_;
  if ($args{Type} eq "Scan") {
    my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-datetimestamp",
	);
    if ($res->{Success}) {
      return $res->{Result};
    }
  } elsif ($args{Type} eq "File") {
    return 0;
  } elsif ($args{Type} eq "First Mentioned") {
    return 0;
  } elsif ($args{Type} eq "Average Mentioned") {
    return 0;
  } elsif ($args{Type} eq "Last Mentioned") {
    return 0;
  }
}

sub MoveToFolders {
  my ($self,%args) = @_;
  # check if there
  my $assert = {};
  my $unassert = {};
  my $dontassert = {};
  foreach my $foldername (keys %{$self->Folders}) {
    if (! exists $args{Folders}->{$foldername}) {
      $unassert->{$foldername} = 1;
    } else {
      $dontassert->{$foldername} = 1;
    }
  }
  foreach my $foldername (keys %{$args{Folders}}) {
    if (! exists $dontassert->{$foldername}) {
      $assert->{$foldername} = 1;
    }
  }

  # now perform all the movements and redraw affected windows
  my $changes = {};
  foreach my $foldername (keys %$unassert) {
    $changes->{$foldername} = 1;
    my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->RemoveMetadata
      (
       DocumentID => $self->DocumentID,
       Predicate => "has-folder",
       Value => $foldername,
      );
    # remove the item from that folder
    $UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->Folders->{$foldername}->RemoveDocument
      (
       Document => $self,
      );
  }
  foreach my $foldername (keys %$assert) {
    $changes->{$foldername} = 1;
    my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
      (
       DocumentID => $self->DocumentID,
       Predicate => "has-folder",
       Value => $foldername,
       Multivalued => 1,
      );
    $UNIVERSAL::paperlessoffice->MyDocumentManager->Cabinet->Folders->{$foldername}->AddDocument
      (
       Document => $self,
      );
  }
  $self->Folders
    (
     $args{Folders},
    );
  return {
	  Success => 1,
	  Changes => $changes,
	 };
}

sub ConvertTo {
  my ($self,%args) = @_;
  print "Not yet implemented\n";
}

sub RedrawMyFolders {
  my ($self,%args) = @_;
  foreach my $foldername (keys %{$self->Folders}) {
    $UNIVERSAL::paperlessoffice->MyGUI->MyTabManager->Tabs->{"View"}->Folders->{$foldername}->Redraw();
  }
}

1;

#   my $folders;
#   my $foldersfile = "$dir/folders";
#   if (-f $foldersfile) {
#     $folders = read_file_dedumper($foldersfile);
#   } else {
#     $folders = $args{Folders} || { Incoming => 1 };
#     write_file_dumper
#       (
#        Data => $folders,
#        File => $foldersfile,
#       );
#   }
#   $self->Folders($folders);


#     write_file_dumper
#       (
#        Data => $folders,
#        File => $foldersfile,
#       );
# }

#   my $foldersfile = "$dir/folders";
#   if (-f $foldersfile) {
#     $folders = read_file_dedumper($foldersfile);
#     # put this information into the knowledgebase
#     foreach my $foldername (keys %$folders) {
#       my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
# 	(
# 	 DocumentID => $self->DocumentID,
# 	 Predicate => "has-folder",
# 	 Value => $foldername,
# 	 Multivalued => 1,
# 	);
#     }
#     # now remove the file
#     system "mv ".shell_quote($foldersfile)." /tmp/paperless-office/trash";
#   } else {

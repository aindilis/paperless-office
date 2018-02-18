package PaperlessOffice::Document::SearchablePDF;

use base qw(PaperlessOffice::Document);

use Manager::Dialog qw(ApproveCommands Message);
use PerlLib::SwissArmyKnife;

use Data::Dumper;
use File::Slurp;
use File::Stat;
use IO::File;
use String::ShellQuote;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / /

  ];

sub init {
  my ($self,%args) = @_;
  print "PaperlessOffice::Document::SearchablePDF->init\n" if $UNIVERSAL::paperlessoffice->Debug;

  $self->SUPER::init(%args);
  my $dir = $self->SUPER::Dir;
  my $quoteddir = $self->SUPER::QuotedDir;

  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-pdf",
    );
  if ($res->{Success}) {
    if ($res->{Result} eq "__unknown") {
      print "Big problem with: ".$self->DocumentID."\n";
    } else {
      $self->SUPER::TargetFile($res->{Result});
    }
  } else {
    my $res = `ls -1 $quoteddir | grep -ir pdf -`;
    if ($res =~ /^(.+\.pdf)$/im) {
      my $pdffile = $1;
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-pdf",
	 Value => $pdffile,
	);
      $self->SUPER::TargetFile($pdffile);
    } else {
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-pdf",
	 Value => "__unknown",
	);
    }
  }

  my $file = $self->SUPER::TargetFile;
  my $quotedtargetfile = shell_quote($file);
  $self->SUPER::QuotedTargetFile($quotedtargetfile);

  my $fulltext;
  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-fulltext",
    );
  if ($res->{Success}) {
    $fulltext = $res->{Result};
    if (-f "$dir/full.txt") {
      system "rm ".shell_quote("$dir/full.txt");
    }
  }

  if (! defined $fulltext) {
    # need to fix this in order to handle base and head names properly
    if (! -f "$dir/full.txt") {
      my $c = "cd $quoteddir && pdftotext $quotedtargetfile full.txt";
      ApproveCommands
	(
	 Commands => [$c],
	 Method => "parallel",
	 AutoApprove => $args{AutoApprove} || 0,
	);
    }
    if (-f "$dir/full.txt") {
      $fulltext = read_file(shell_quote("$dir/full.txt"));
      $fulltext =~ s/[[:^ascii:]]/ /g;
      $fulltext =~ s/[[:cntrl:]]/ /g;
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-fulltext",
	 Value => $fulltext,
	);
      system "rm ".shell_quote("$dir/full.txt");
    } else {
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-fulltext",
	 Value => '',
	);
      $fulltext = "";
    }
  }
  $self->SUPER::FullTextContents
      ($fulltext);
  $self->SUPER::OCRedP(1);
}

sub OCR {
  my ($self,%args) = @_;
  # no need
}

sub IsEmptyAndShouldBeDeleted {
  my ($self,%args) = @_;
  return 0;
}

sub FullText {
  my ($self,%args) = @_;
  return $self->SUPER::FullTextContents;
}

sub GeneratePDF {
  my ($self,%args) = @_;

}

sub GenerateThumbnail {
  my ($self,%args) = @_;
  my $thumbnailfile = ConcatDir($self->Directory,"thumbnail.gif");
  my $quotedtargetfile = $self->SUPER::QuotedTargetFile;
  if (! -f $thumbnailfile or $args{Regenerate}) {
    my $quotedppmfile = shell_quote(ConcatDir($self->Directory,"output-1.ppm"));
    my $res = ApproveCommands
      (
       Commands =>
       [

	"cd ".shell_quote($self->Directory)." && pdftoppm $quotedtargetfile -f 1 -l 1 output",
	"convert -thumbnail 100 $quotedppmfile ".shell_quote($thumbnailfile),
	"rm $quotedppmfile",
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
  my $command = "xdg-open ".shell_quote(ConcatDir($self->Directory,$self->TargetFile))." &";
  ApproveCommands
    (
     Commands => [$command],
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
  my $command = "pdfedit ".shell_quote(ConcatDir($self->Directory,$self->TargetFile))." &";
  ApproveCommands
    (
     Commands => [$command],
     Method => "parallel",
     AutoApprove => 1,
    );
}

sub MenuActionEditPages {
  my ($self,%args) = @_;
  Message("Must convert to MultipleImages format to edit the pages.  (Will add automatic conversion in the future.)");
}


sub MenuActionFormFiller {
  my ($self,%args) = @_;
  my $command = "flpsed ".shell_quote(ConcatDir($self->Directory,$self->TargetFile))." &";
  ApproveCommands
    (
     Commands => [$command],
     Method => "parallel",
     AutoApprove => 1,
    );
}

1;

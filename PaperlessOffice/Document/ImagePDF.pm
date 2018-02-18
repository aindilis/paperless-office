package PaperlessOffice::Document::ImagePDF;

use base qw(PaperlessOffice::Document);

use Manager::Dialog qw(ApproveCommands Message);
use PerlLib::SwissArmyKnife;

use Data::Dumper;
use File::Slurp;
use File::Stat;
use IO::File;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / /

  ];

sub init {
  my ($self,%args) = @_;
  print "PaperlessOffice::Document::ImagePDF->init\n" if $UNIVERSAL::paperlessoffice->Debug;

  $self->PageImages($args{PageImages} || []);
  $self->PageTexts($args{PageTexts} || []);

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
    my $command = "ls -1 $quoteddir | grep -ir pdf -";
    my $res = `$command`;
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

  if (0 and ! -f "$dir/full.txt") {
    my $c = "cd $quoteddir && pdftoppm $quotedfile convert";
    ApproveCommands
      (
       Commands => [$c],
       Method => "parallel",
       # AutoApprove => 1,
      );

    # now convert the filenames
    my $i = 1;
    my $j = 1;
    my $exitj = 0;
    while (! $exitj) {
      my $exiti = 0;
      while (! $exiti) {
	my $file = sprintf("%s/convert-%0".$j."i.ppm",$quoteddir,$i);
	if (! -f $file) {
	  $exiti = 1;
	} else {
	  my $fn = "$quoteddir/".($i-1).".pnm";
	  my $qfile = shell_quote($file);
	  my $qfn = shell_quote($fn);
	  my $c2 = "mv $qfile $qfn";
	  print "PaperlessOffice::Document::ImagePDF->init 2\n";
	  ApproveCommands
	    (
	     Commands => [$c2],
	     Method => "parallel",
	     # AutoApprove => 1,
	    );
	  $doc->PageImages->[$i-1] = $fn;
	  ++$i;
	  $exitj = 1;
	}
      }
      if ($j > 9) {
	$exitj = 1;
      }
      ++$j;
    }
    $self->OCR;
  }
}

sub AddImage {
  my ($self,%args) = @_;
  if (-f $args{Image}) {
    push @{$self->PageImages}, $args{Image};
  }
}

sub OCR {
  my ($self,%args) = @_;
  my $last = scalar @{$self->PageImages} - 1;
  foreach my $i (0..$last) {
    my $fn = $self->PageImages->[$i].".txt";
    my $fn2 = $self->PageImages->[$i].".badresults.txt";
    if (! -f $fn) {
      print "OCRing page ".($i + 1)."\n";
      my $res = $UNIVERSAL::paperlessoffice->MyResources->MyOCR->OCRImage
	(ImageFile => $self->PageImages->[$i]);
      if (scalar @{$res->{BadResults}}) {
	my $fh2 = IO::File->new;
	if ($fh2->open(">$fn2")) {
	  print $fh2 Dumper($res->{BadResults});
	  $fh2->close;
	} else {
	  print "cannot open file <$fn2> for writing OCR badresults output\n";
	}
      }
      if ($res->{Success}) {
	$self->PageTexts->[$i] = $res->{Text};
	my $fh = IO::File->new;
	if ($fh->open(">$fn")) {
	  print $fh $res->{Text};
	  $fh->close;
	} else {
	  print "cannot open file <$fn> for writing OCR output\n";
	}
      } else {
	$self->PageTexts->[$i] = undef;
      }
    }
  }
  $self->SUPER::OCRedP(1);
}

sub IsEmptyAndShouldBeDeleted {
  my ($self,%args) = @_;
  return 0;
  #   my $count = scalar @{$self->PageImages};
  #   if ($count == 0) {
  #     return 1;
  #   } elsif ($count == 1) {
  #     my $stat =  File::Stat->new($self->PageImages->[0]);
  #     return ($stat->size == 0);
  #   }
}

# all sorts of other glorious functions here

sub FullText {
  my ($self,%args) = @_;
  my @contents;
  for (my $i = 0; $i < scalar @{$self->PageTexts}; ++$i) {
    if (exists $self->PageTexts->[$i]) {
      my $f = $self->PageTexts->[$i];
      if (-f $f) {
	push @contents, read_file($f);
      }
    }
  }
  return join("\n",@contents);
}

sub GeneratePDF {
  my ($self,%args) = @_;

}

sub GenerateThumbnail {
  my ($self,%args) = @_;
  my $thumbnailfile = ConcatDir($self->Directory,"thumbnail.gif");
  if (! -f $thumbnailfile or $args{Regenerate}) {
    my $quotedppmfile = shell_quote(ConcatDir($self->Directory,"output-1.ppm"));
    my $res = ApproveCommands
      (
       Commands =>
       [
	"cd ".shell_quote($self->Directory)." && pdftoppm ".shell_quote($file)." -f 1 -l 1 output",
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

sub ConvertTo {
  my ($self,%args) = @_;
  if ($args{Type} eq "MultipleImages") {
    $self->ConvertToMultipleImages();
  }
}

sub ConvertToMultipleImages {
  my ($self,%args) = @_;
  # print "Not yet implemented\n";
  # return;

  # <Chose:profile>
  # <DocID: _qFb_YRDov>
  # Converting pages to ppm(s)
  # cd /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov && pdftoppm document.pdf document
  # Converting ppm(s) to pnm(s)
  # cd /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov && convert /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov/document-1.ppm -1.pnm; done)
  # sh: -c: line 0: syntax error near unexpected token `done'
  # sh: -c: line 0: `cd /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov && convert /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov/document-1.ppm -1.pnm; done)'
  # cd /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov && convert /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov/document-2.ppm -1.pnm; done)
  # sh: -c: line 0: syntax error near unexpected token `done'
  # sh: -c: line 0: `cd /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov && convert /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov/document-2.ppm -1.pnm; done)'
  # $VAR1 = {
  #           "Flags" => {
  #                        "AssertWithoutCheckingConsistency" => 1
  #                      },
  #           "InputType" => "Interlingua",
  #           "Context" => "Org::FRDCSA::PaperlessOffice::Cabinet::paperport2",
  #           "QueryAgent" => 1,
  #           "Unassert" => [
  #                           [
  #                             "has-type",
  #                             [
  #                               "document-fn",
  #                               "paperport2",
  #                               "_qFb_YRDov"
  #                             ],
  #                             "ImagePDF"
  #                           ]
  #                         ]
  #         };
  # $VAR1 = {
  #           "UnassertResult" => bless( {
  #                                        "Contents" => "",
  #                                        "ID" => 0,
  #                                        "DataFormat" => "Perl",
  #                                        "Date" => "Sun Oct 30 09:17:45 CDT 2011",
  #                                        "Sender" => "KBS2",
  #                                        "MyXMLDumper" => bless( {
  #                                                                  "perldata" => {},
  #                                                                  "xml" => {},
  #                                                                  "xml_parser_params" => {}
  #                                                                }, 'XML::Dumper' ),
  #                                        "Receiver" => "KBS2-client-0.308327741778584",
  #                                        "Data" => {
  #                                                    "Result" => "",
  #                                                    "_DoNotLog" => 1,
  #                                                    "_TransactionSequence" => 1,
  #                                                    "_TransactionID" => "0.321675207746509"
  #                                                  }
  #                                      }, 'UniLang::Util::Message' )
  #         };
  # $VAR1 = {
  #           "Assert" => [
  #                         [
  #                           "has-type",
  #                           [
  #                             "document-fn",
  #                             "paperport2",
  #                             "_qFb_YRDov"
  #                           ],
  #                           "MultipleImages"
  #                         ]
  #                       ],
  #           "Flags" => {
  #                        "AssertWithoutCheckingConsistency" => 1
  #                      },
  #           "InputType" => "Interlingua",
  #           "Context" => "Org::FRDCSA::PaperlessOffice::Cabinet::paperport2",
  #           "QueryAgent" => 1
  #         };
  # $VAR1 = {
  #           "AssertResult" => bless( {
  #                                      "Contents" => "",
  #                                      "ID" => 0,
  #                                      "DataFormat" => "Perl",
  #                                      "Date" => "Sun Oct 30 09:17:45 CDT 2011",
  #                                      "Sender" => "KBS2",
  #                                      "MyXMLDumper" => bless( {
  #                                                                "perldata" => {},
  #                                                                "xml" => {},
  #                                                                "xml_parser_params" => {}
  #                                                              }, 'XML::Dumper' ),
  #                                      "Receiver" => "KBS2-client-0.308327741778584",
  #                                      "Data" => {
  #                                                  "Result" => {
  #                                                                "Success" => 1
  #                                                              },
  #                                                  "_DoNotLog" => 1,
  #                                                  "_TransactionSequence" => 1,
  #                                                  "_TransactionID" => "0.809233932093459"
  #                                                }
  #                                    }, 'UniLang::Util::Message' )
  #         };
  # $VAR1 = {
  #           "Document" => bless( {
  #                                  "TargetFile" => "document.pdf",
  #                                  "Dir" => "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov",
  #                                  "DocumentID" => "_qFb_YRDov",
  #                                  "QuotedFile" => "''",
  #                                  "QuotedTargetFile" => "document.pdf",
  #                                  "Directory" => "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov",
  #                                  "Folders" => {
  #                                                 "Incoming" => 1
  #                                               },
  #                                  "PageImages" => [],
  #                                  "PageTexts" => [],
  #                                  "File" => undef,
  #                                  "QuotedDir" => "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov"
  #                                }, 'PaperlessOffice::Document::ImagePDF' )
  #         };
  # $VAR1 = {
  #           "DocumentDirectory" => undef,
  #           "Dir" => "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov"
  #         };
  # cannot open type file
  # $VAR1 = {
  #           "Assert" => [
  #                         [
  #                           "has-type",
  #                           [
  #                             "document-fn",
  #                             "paperport2",
  #                             "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/_qFb_YRDov"
  #                           ],
  #                           "ImagePDF"
  #                         ]
  #                       ],
  #           "Flags" => {
  #                        "AssertWithoutCheckingConsistency" => 1
  #                      },
  #           "InputType" => "Interlingua",
  #           "Context" => "Org::FRDCSA::PaperlessOffice::Cabinet::paperport2",
  #           "QueryAgent" => 1
  #         };
  # $VAR1 = {
  #           "AssertResult" => bless( {
  #                                      "Contents" => "",
  #                                      "ID" => 0,
  #                                      "DataFormat" => "Perl",
  #                                      "Date" => "Sun Oct 30 09:17:46 CDT 2011",
  #                                      "Sender" => "KBS2",
  #                                      "MyXMLDumper" => bless( {
  #                                                                "perldata" => {},
  #                                                                "xml" => {},
  #                                                                "xml_parser_params" => {}
  #                                                              }, 'XML::Dumper' ),
  #                                      "Receiver" => "KBS2-client-0.308327741778584",
  #                                      "Data" => {
  #                                                  "Result" => {
  #                                                                "Success" => 1
  #                                                              },
  #                                                  "_DoNotLog" => 1,
  #                                                  "_TransactionSequence" => 1,
  #                                                  "_TransactionID" => "0.112675736174559"
  #                                                }
  #                                    }, 'UniLang::Util::Message' )
  #         };



  # set the type to the new one
  # get the document that we need to operate on
  my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->GetMetadata
    (
     DocumentID => $self->DocumentID,
     Predicate => "has-pdf",
    );
  if ($res->{Success}) {
    my $filename = $res->{Result};
    if (-f ConcatDir($self->Dir,$filename)) {
      print "Converting pages to ppm(s)\n";
      ApproveCommands
	(
	 Commands => ["cd ".shell_quote($self->Dir)." && pdftoppm ".shell_quote($filename)." document"],
	 Method => "parallel",
	 AutoApprove => $args{AutoApprove} || 1,
	);
      print "Converting ppm(s) to pnm(s)\n";
      # for it in `seq 1 8`; do ((it2 = $it - 1)) ; convert document-$it.ppm $it2.pnm ; done
      my $dir = $self->Dir;
      my $files = [split /\n/, `ls $dir/*.ppm`];
      my @commands;
      foreach my $file (@$files) {
	if ($file =~ /^.*?\/document-(\d+).ppm$/) {
	  my $tmp = $1;
	  my $int = int($tmp) - 1;
	  push @commands, "cd ".shell_quote($self->Dir)." && convert ".shell_quote($file)." ".shell_quote("$int.pnm")." && rm ".shell_quote($file);
	} else {
	  die "ERROR $file\n";
	}
      }
      ApproveCommands
	(
	 Commands => \@commands,
	 Method => "parallel",
	 AutoApprove => $args{AutoApprove} || 1,
	);

      print Dumper({
		    Dir => $self->Dir,
		    DocumentID => $self->DocumentID,
		    DocumentDirectory => $documentdirectory,
		   });

      # now, edit the metadata, then reload
      my $res = $UNIVERSAL::paperlessoffice->MyDocumentManager->SetMetadata
	(
	 DocumentID => $self->DocumentID,
	 Predicate => "has-type",
	 Value => "MultipleImages",
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
  } else {
    Message(Message => "Conversion failed");
  }
}

sub DESTROY {
  my ($self,%args) = @_;
}

1;

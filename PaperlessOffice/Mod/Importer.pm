package PaperlessOffice::Mod::Importer;

use Manager::Dialog qw(Approve ApproveCommands);
use PaperlessOffice::Document::ImagePDF;
use PaperlessOffice::Document::SearchablePDF;
use PerlLib::SwissArmyKnife;

use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use String::ShellQuote;
use Term::ReadKey;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Debug / ];

sub init {
  my ($self,%args) = @_;
  # get a new document location for the imports
  $self->Debug($args{Debug} || 0);
}

# distinguish between one with folders and one without

sub ImportFileOrDir {
  my ($self,%args) = @_;
  my $it = $args{FileOrDir};
  $it =~ s/\/$//;
  print "<<<$it>>>\n";
  if (-f $it) {
    $self->ImportDocument
      (
       File => $it,
       Directory => $args{Directory},
      );
  } elsif (-d $it) {
    if ($args{UseParentDirsAsFolders}) {
      # go ahead and do a find in this directory, and extract all the
      # PDFs for instance, and their basenames relative to the current
      # path, but just print these and then exit for now
      foreach my $file (split /\n/, `find $it`) {
	my $dirname = dirname($file);
	my $basename = basename($file);
	my $front = length($it) + 1;
	$dirname =~ s/^.{$front}//;
	if ($basename =~ /\.pdf$/i) {
	  $self->ImportDocument
	    (
	     File => $file,
	     Folders => {
			 $dirname => 1,
			},
	     Directory => $args{Directory},
	     AutoApprove => 1,
	    );
	}
      }
    } else {
      my $quoted = shell_quote($it);
      foreach my $it2 (split /\n/, `ls -1 $quoted`) {
	print "<<$it2>>\n";
	print "$it2\n" if $self->Debug;
	$self->ImportFileOrDir
	  (
	   FileOrDir => "$it/$it2",
	   Directory => $args{Directory},
	  );
      }
    }
  }
}

sub ImportDocument {
  my ($self,%args) = @_;
  # make sure it is an acceptable format
  if ($args{File} !~ /\.pdf$/) {
    print "cannot import file <<<".$args{File}.">>>\n" if $self->Debug;
    return;
  }
  print "Importing ".$args{File}."\n";

  # actually, first verify that we don't already have this exact item
  # in the system

  # how do we do this?  We must obviously store a list of all the
  # sizes and hash values, and if these match, check the bytewise
  # contents of the file

  # verify that we don't have a copy in the collection

  # okay we need to create a new unique document

  # maybe implement some of KBFS here

  my $tempdir = tempdir ( DIR => $args{Directory} );

  # determine what type of document it is
  my $res = $self->GetDocumentClass
    (
     File => $args{File},
    );

  if ($res->{Success}) {
    my $class = $res->{Class};
    my $doc = "PaperlessOffice::Document::$class"->new
      (
       File => $args{File},
       Directory => $tempdir,
       Folders => $args{Folders},
       AutoApprove => $args{AutoApprove},
      );
    return {
	    Success => 1,
	    Result => $doc,
	   };
  } else {
    return $res;
  }
}

sub GetDocumentClass {
  my ($self,%args) = @_;
  my $file = $args{File};
  my $type;
  if ($file =~ /\.pdf$/) {	# use MIME tests here
    # it's a PDF, find out whether it is text, image, or image w/ text
    # for now, just return searchable PDF
    my $quotedpdffile = shell_quote("$file");
    my $res2 = `pdftotext $quotedpdffile -`;
    if ($res2 =~ /\w/) {
      # it's a searchable
      $type = "SearchablePDF";
    } else {
      $type = "ImagePDF";
    }
  }
  if (defined $type) {
    return {
	    Success => 1,
	    Class => "SearchablePDF",
	   };
  } else {
    return {
	    Success => 0,
	   };
  }
}

1;

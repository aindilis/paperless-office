package PaperlessOffice::Scanner;

use PaperlessOffice::Document;
use Manager::Dialog qw(Approve ApproveCommands);

use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use Term::ReadKey;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / ScanDir Book Resolution / ];

sub init {
  my ($self,%args) = @_;
  # get a new document location for the scans
}

sub AcquireDocument {
  my ($self,%args) = @_;
  # okay we need to create a new unique document
  my $tempdir = tempdir ( DIR => $args{Directory} );
  my $doc = PaperlessOffice::Document->new
    (Directory => $tempdir);
  do {
    $self->ScanNewImage
      (
       Document => $doc,
      );
    # $self->GetUsersAttention();
  } while (Approve("Scan another page?"));
  return $doc;
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

sub ScanNewImage {
  my ($self,%args) = @_;
  my $doc = $args{Document};
  my $res = $self->GetCurrentImage
    (Directory => $doc->Directory);
  my ($pageno,$fn) = ($res->{PageNo},$res->{FN});
  # to obtain options:
  # sudo scanimage --help -d "hpaio:/net/Officejet_6300_series?ip=192.168.1.106"

  #  -l 0..215.9mm [0]
  #      Top-left x position of scan area.
  #  -t 0..381mm [0]
  #      Top-left y position of scan area.
  #  -x 0..215.9mm [215.9]
  #      Width of scan-area.
  #  -y 0..381mm [381]
  #      Height of scan-area.

  # $c = "sudo scanimage --resolution 300 -x 215 -y 297 > $fn";
  my $resolution = $self->Resolution || 150;
  print "PaperlessOffice::Scanner->ScanNewImage\n";
  ApproveCommands
    (
     Commands => [
		  "sudo scanimage -d \"hpaio:/net/Officejet_6300_series?ip=192.168.1.107\" --resolution $resolution -x 215.9 -y 381 > $fn",
		  # 		  "pnmtojpeg $fn --quality=30 > $fn.jpg",
		  # 		  "rm $fn",
		  # 		  "touch $fn",
		  # 		  "xview $fn.jpg -shrink",
		 ],
     Method => "parallel",
     AutoApprove => 1,
    );
  if (-f $fn) {
    $doc->PageImages->[$pageno] = $fn;
  }
}

sub GetUsersAttention {
  my ($self,%args) = @_;
  print "Waiting for your approval to continue.  Press return exactly once.\n";
  ReadMode "cbreak";
  my $okayed = 0;
  while (!$okayed) {
    foreach my $i (1..3) {
      next if $okayed;
      system "sudo beep";
      if (defined ($key = ReadKey(-1))) {
	$okayed = 1;
      } else {
	sleep 1;
      }
    }
    if (defined ($key = ReadKey(-1))) {
      $okayed = 1;
    } else {
      sleep 3;
    }
  }
  ReadMode "normal";
  print "Approved.\n";
}

1;

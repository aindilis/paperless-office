#!/usr/bin/perl -w

# first copy all the files to a new location

# foreach file, try to convert it to text using pdftotext.

# If we cannot find any words, we assume that it is not searchable

# we then use the Capability::OCR module, with the options for
# Searchable PDF, and the Capability::OCR profile for this script

# this module moves it to the correct directory, and then watches the
# output.  once it sees the correct file, it checks it for a while to
# see if it has stopped growing in size.  when it is has stopped for a
# long time, it moves it to the proper location as specified in the
# profile

# when all files have been converted it writes an output file saying
# that it is done.  We then proceed to replace the items by manually
# swapping out the directories, and then starting paperport to test

use Capability::OCR;

use Data::Dumper;
use String::ShellQuote;

my $mypaperportdocumentsdir = "/home/andrewdo/Media/shared/My PaperPort Documents";
my $copydir = "/home/andrewdo/Media/shared/Copy of My PaperPort Documents";

my $ocr = Capability::OCR->new
  (
   EngineName => "NonFreeOmnipageBatchAgent",
   Rewrite => sub {
     my %args = @_;
     return $args{Head};
   },
   Origin => $mypaperportdocumentsdir,
   Destination => $copydir,
   OCRFolderWatch => "/home/andrewdo/Media/shared/data/paperless-office/ocr-folder-watch",
   OCRFolderWatchOutput => "/home/andrewdo/Media/shared/data/paperless-office/ocr-folder-watch-output",
  );

if (! -d $copydir) {
  # system "mkdir ".shell_quote($copydir);
}

my $regex = $mypaperportdocumentsdir;
$regex =~ s/([^[:alnum:]])/\\$1/g;
print $regex;
foreach my $item (split /\n/, `find "$mypaperportdocumentsdir"`) {
  # need to fix this
  if ($item =~ /^($regex)(\/(.+))?\/([^\/]+)$/) {
    my ($tmp,$base,$head) = ($1,$3,$4);
    my $basehead;
    if (defined $base) {
      $basehead = "$base/$head";
    } else {
      $basehead = "$head";
    }
    if (-f $item) {
      if ($item =~ /\.pdf$/i) {
	# now we may make this a searchable PDF
	my $makesearchablepdfargs = {
				     InputFile => $item,
				     Base => $base,
				     Head => $head,
				     BaseHead => $basehead,
				    };
	print Dumper($makesearchablepdfargs);
	my $res = $ocr->MakeSearchablePDF
	  (%$makesearchablepdfargs);
	print Dumper($res)."\n\n\n";
      } else {
	print "ERROR: $item\n";
      }
    }
  } else {
    print "BIG ERROR: $item\n";
  }
}

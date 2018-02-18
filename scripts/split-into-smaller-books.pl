#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

# take a given document and split it into smaller sections suitable
# for perusal by Emacs

my $targetdir = "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/split-book";
if (! -d $targetdir) {
  my $dir = "/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport2/documents/2RkFLZGeH_";
  my $keys = {};
  foreach my $file (split /\n/, `ls $dir`) {
    # print "<$file>\n";
    if ($file =~ /^(\d+)\.pnm$/) {
      $keys->{$1} = 1;
    }
  }

  my $keys2 = [sort {$a <=> $b} keys %$keys];

  my @total;
  while (@$keys2) {
    my $size = scalar @$keys2;
    my @queue;
    if ($size < 20) {
      @queue = @$keys2;
      $keys2 = [];
    } else {
      foreach my $i (1..20) {
	push @queue, shift @$keys2;
      }
    }

    # print Dumper(\@queue);
    push @total, \@queue;
  }

  if (! -d $targetdir) {
    mkdir $targetdir;
  }
  die "No targetdir <$targetdir>\n" unless -d $targetdir;
  my $booksplit = 1;
  foreach my $queue (@total) {
    mkdir "$targetdir/$booksplit";
    my $i = 0;
    foreach my $num (@$queue) {
      my $command = "cp $dir/$num.pnm $targetdir/$booksplit/$i.pnm";
      print $command."\n";
      system $command;
      ++$i;
    }
    ++$booksplit;
  }
}

# now go ahead and bind these into pdfs
foreach my $dir (sort {$a <=> $b} split /\n/, `ls $targetdir`) {
  # convert -define pdf:use-trimbox=true *.pnm document.pdf
  print "<$dir>\n";
  my @files = sort {Strip($a) <=> Strip($b)} split /\n/, `ls $targetdir/$dir`;
  # FIXME have dir be equal to 01, 02 etc, or 001, etc
  # my $command = "cd $targetdir/$dir && convert -define pdf:use-trimbox=true ".join(" ",@files)." handbook-of-logic-part-$dir.pdf";
  my $command = "cd $targetdir/$dir && convert -quality 100 ".join(" ",@files)." handbook-of-logic-part-$dir.pdf";
  print $command."\n";
  system $command;
  GetSignalFromUserToProceed();
}

sub Strip {
  my $a = shift;
  if ($a =~ /^(\d+)\.pnm$/) {
    return $1;
  } else {
    die "Doesn't match\n";
  }
}

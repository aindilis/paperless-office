#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

use File::DirList;

my $quoteddir = shell_quote('/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/official/documents/NX0_nRvnVd');
# foreach my $file (map split /\n/, `ls $quoteddir`) {
my $list = File::DirList::list($quoteddir, 'n', 1, 1, 0);

foreach my $file (sort {$a <=> $b} grep /\.pnm$/, map {$_->[13]} @$list) {
  print '<'.$file.">\n";
}

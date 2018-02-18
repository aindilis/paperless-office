#!/usr/bin/perl -w

use BOSS::Config;
use Manager::Dialog qw(ApproveCommands);
use PerlLib::SwissArmyKnife;

$specification = q(
	-f <file>...	List existing searches
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";

foreach my $file (@{$conf->{'-f'}}) {
  MakeThumbnailOfPDF(File => $file);
}

sub MakeThumbnailOfPDF {
  my %args = @_;
  my $file = $args{File};
  ApproveCommands
    (
     Commands =>
     [
      "pdftoppm ".shell_quote($file)." -f 1 -l 1 output",
      "convert -thumbnail 100 output-1.ppm thumbnail.gif",
      "rm output-1.ppm",
     ],
     Method => "parallel",
    );
}

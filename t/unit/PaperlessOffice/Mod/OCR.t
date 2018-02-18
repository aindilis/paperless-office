#!/usr/bin/perl -w

use Test::More;
use MyFRDCSA qw(ConcatDir Dir);

BEGIN { use_ok( 'PaperlessOffice::Mod::OCR' ); }

$UNIVERSAL::systemdir = ConcatDir(Dir('minor codebases'),'paperless-office');

my $ocr;

subtest 'load' => sub {
  plan tests => 1;
  $ocr = PaperlessOffice::Mod::OCR->new();
  isa_ok($ocr, 'PaperlessOffice::Mod::OCR');
};

subtest 'scan' => sub {
  plan tests => 3;
  my $imagefile = ConcatDir($UNIVERSAL::systemdir,'t','data','2.pnm');
  ok(-e $imagefile,'test image file exists');
  my $results = $ocr->OCRImage(ImageFile => $imagefile);
  ok($results->{Success}, 'scan successful');
  ok($results->{Text} =~ /Andrew Dougherty/,'scan matches');
};

done_testing();




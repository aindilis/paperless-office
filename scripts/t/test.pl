#!/usr/bin/perl -w

use Data::Dumper;
use Image::OCR::Tesseract 'get_ocr';

my $image = $ARGV[0];
if (-f $image) { # and its an image file
  my $text = get_ocr($image);
  print Dumper($text);
}

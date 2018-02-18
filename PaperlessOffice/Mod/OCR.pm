package PaperlessOffice::Mod::OCR;

use Capability::OCR;
use PerlLib::Dictionary;

use Data::Dumper;
use Image::Magick;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyOCR MyDictionary MyImageMagick /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyOCR
    (Capability::OCR->new
     (EngineName => $args{EngineName}));
  $self->MyDictionary
    (PerlLib::Dictionary->new);
}

sub OCRImage {
  my ($self,%args) = @_;
  my $image = $args{ImageFile};
  print "OCRING $image\n";
  my $outputimage = $UNIVERSAL::systemdir."/data/tmp/tmp.pnm";
  $self->LoadImageMagick;
  if (-f $image) {
    @{$self->MyImageMagick} = ();
    my $x = $self->MyImageMagick->Read($image);
    # $self->MyImageMagick->Quantize(colorspace=>'gray');
    # $self->MyImageMagick->Set(monochrome=>'True');
    my $count = 0;
    my $sanity = 0;
    my $text;
    my $badresults = [];
    do {
      if ($count > 0) {
	# rotate the image
	print "Results unreasonable, rotating and re-OCRing\n";
	push @$badresults, $text;

	$x = $self->MyImageMagick->Rotate
	  (Degrees => 90);
	warn "$x" if "$x";

	$x = $self->MyImageMagick->Write($outputimage);
	warn "$x" if "$x";
      }
      $text = "";
      ++$count;
      $x = $self->MyImageMagick->Write($outputimage);
      warn "$x" if "$x";
      my $res = $self->MyOCR->OCR
	(
	 ImageFile => $outputimage,
	);
      $text = $res->{Text};
      if ($res->{Success}) {
	$sanity = $self->Sane
	  (Text => $text);
      } else {
	$sanity = 0;
      }
    # now do a sanity check
    } while (! $args{SkipRotations} and ! $sanity and $count < 4);
    return {
	    Success => 1,
	    Text => $text,
	    BadResults => $badresults,
	   };
  }
  return {
	  Success => 0,
	 };
}

sub LoadImageMagick {
  my ($self,%args) = @_;
  if (! $self->MyImageMagick) {
    $self->MyImageMagick
      (Image::Magick->new);
  }
}

sub Sane {
  my ($self,%args) = @_;
  # check the percentage of in dictionary 3 or more letter words is high enough
  my $hits = 0;
  my $total = 0;
  foreach my $word (split /\W/, $args{Text}) {
    if (length($word) > 2) {
      $total++;
      $hits += $self->MyDictionary->Lookup
	(Word => $word);
    }
  }
  if ($total and ($hits / $total > 0.3)) {
    return 1;
  }
}

1;

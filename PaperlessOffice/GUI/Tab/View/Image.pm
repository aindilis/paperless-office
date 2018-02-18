package PaperlessOffice::GUI::Tab::View::Image;

use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / File Width Height /

  ];

sub init {
  my ($self,%args) = @_;
  $self->File($args{File});
  # get the width and height from the file
  my $command = "identify ".shell_quote($self->File);
  my $res = `$command`;
  # scripts/thumbnail.gif GIF 100x141 100x141+0+0 8-bit PseudoClass 256c 10.7KB 0.000u 0:00.000
  if ($res =~ /GIF (\d+)x(\d+)\s+/) {
    $self->Width($args{Width} || $1);
    $self->Height($args{Height} || $2);
  }
}

1;

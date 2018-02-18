package PaperlessOffice::GUI::Tab::View::Document;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Source ID Description Selected /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Source($args{Source});
  $self->ID($args{ID});
  $self->Description($args{Description});
}

sub ToggleSelected {
  my ($self,%args) = @_;
  if ($self->Selected) {
    $self->Selected(0);
  } else {
    $self->Selected(1);
  }
}

1;

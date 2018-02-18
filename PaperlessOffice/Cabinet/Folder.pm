package PaperlessOffice::Cabinet::Folder;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Name Documents /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Name($args{Name});
  $self->Documents({});
  # should probably have a file which represents information about the
  # folder somewhere

}

sub AddDocument {
  my ($self,%args) = @_;
  $self->Documents->{$args{Document}->DocumentID} = $args{Document};
}

sub RemoveDocument {
  my ($self,%args) = @_;
  delete $self->Documents->{$args{Document}->DocumentID};
}

sub Execute {
  my ($self,%args) = @_;

}

1;

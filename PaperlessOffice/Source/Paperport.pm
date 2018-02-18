package PaperlessOffice::Source::Paperport;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / / ];

sub init {
  my ($self,%args) = @_;

}

sub ImportDocument {
  my ($self,%args) = @_;
  # okay one thing we need to do is monitor a directory for new files
}

1;

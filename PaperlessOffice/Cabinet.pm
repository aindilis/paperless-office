package PaperlessOffice::Cabinet;

use Manager::Dialog qw(QueryUser2);
use PaperlessOffice::Cabinet::Folder;
use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Name Directory DocumentDirectory Documents Folders /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Name($args{Name});
  $self->DocumentDirectory($args{DocumentDirectory});
  $self->Directory(dirname($self->DocumentDirectory));
  $self->Documents({});
  $self->Folders({});
  my $docdir = $self->DocumentDirectory;
  system "mkdir -p \"$docdir\"";
}

sub AddDocument {
  my ($self,%args) = @_;
  my $doc = $args{Document};
  $self->Documents->{$doc->Dir} = $doc;
  if (exists $doc->Folders->{"Incoming from Scanner"}) {
    if ($args{DeleteIfNecessary}) {
      $doc->Delete();
    }
  } else {
    foreach my $foldername (keys %{$doc->Folders}) {
      if (! exists $self->Folders->{$foldername}) {
	$self->AddFolder
	  (
	   FolderName => $foldername,
	  );
      }
      $self->Folders->{$foldername}->AddDocument
	(
	 Document => $doc,
	);
    }
  }
}

sub RemoveDocument {
  my ($self,%args) = @_;
  my $doc = $args{Document};
  delete $self->Documents->{$doc->Dir};
  foreach my $foldername (keys %{$doc->Folders}) {
    $self->Folders->{$foldername}->RemoveDocument
      (
       Document => $doc,
      );
  }
}

sub Execute {
  my ($self,%args) = @_;

}

sub AddFolder {
  my ($self,%args) = @_;
  my $foldername;
  if (defined $args{FolderName}) {
    $foldername = $args{FolderName};
  } else {
    # prompt the user for the folder name
    my $res = QueryUser2
      (
       Title => "Create New Folder",
       Message => "Name of new folder?",
      );
    if (! $res->{Cancel}) {
      $foldername = $res->{Value};
    } else {
      return {
	      Success => 0,
	     };
    }
  }
  my $preexisting = 1;
  if (! exists $self->Folders->{$foldername}) {
    $self->Folders->{$foldername} = PaperlessOffice::Cabinet::Folder->new
      (
       Name => $foldername,
      );
    $preexisting = 0;
  }
  return {
	  Success => 1,
	  Result => $foldername,
	  PreexistingCabinet => $preexisting,
	 };
}

1;

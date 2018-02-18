package PaperlessOffice::Mod::Classifier::Basic;

use Manager::Dialog qw(SubsetSelect);
use MyFRDCSA;
use PerlLib::SwissArmyKnife;
use Rival::AI::Categorizer;
use Rival::AI::Categorizer::Category;
use Rival::AI::Categorizer::Document;
use Rival::AI::Categorizer::KnowledgeSet;
use Rival::AI::Categorizer::Learner::NaiveBayes;
use Rival::AI::Categorizer::Learner::SVM;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyDocumentManager MyLearner _DocumentsDataLocation /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyDocumentManager($args{MyDocumentManager});
  $self->_DocumentsDataLocation
    (ConcatDir($self->MyDocumentManager->Cabinet->Directory,"classification","rival-categorizer","documents"));
  MkDirIfNotExists(Directory => $self->_DocumentsDataLocation);
  my $dir = ConcatDir($self->MyDocumentManager->Cabinet->Directory,"classification","domain","classes");
  $statepath = ConcatDir($self->MyDocumentManager->Cabinet->Directory,"classification","domain","model");
  MkDirIfNotExists(Directory => $statepath);

  # Create the Learner, and restore state if need be
  $args{Learner} ||= "NaiveBayes";

  my $needstraining;
  if ($args{Learner}) {
    if ($args{Learner} eq "SVM") {
      if (-d $statepath and ! $args{Retrain}) {
	print "Restoring state\n";
	$self->MyLearner(Rival::AI::Categorizer::Learner::SVM->restore_state($statepath));
      } else {
	$self->MyLearner(Rival::AI::Categorizer::Learner::SVM->new());
	$needstraining = 1;
      }
    } elsif ($args{Learner} eq "NaiveBayes") {
      if (-d $statepath and ! $args{Retrain}) {
	print "Restoring state\n";
	$self->MyLearner(Rival::AI::Categorizer::Learner::NaiveBayes->restore_state($statepath));
      } else {
	$self->MyLearner(Rival::AI::Categorizer::Learner::NaiveBayes->new());
	$needstraining = 1;
      }
    } else {
      die "Learner ".$args{Learner}." not found\n";
    }
  }

  if ($needstraining) {
    # LOAD THE SOURCE DATA
    # first create a list of all of the folders

    # my $exceptions =
    #   {
    #    "Incoming" => 1,
    #    "Incoming2" => 1,
    #    "Incoming from Scanner" => 1,
    #   };

    my @cats;
    foreach my $foldername (keys %{$self->MyDocumentManager->Cabinet->Folders}) {
      next if $self->MyDocumentManager->Cabinet->Folders->{$foldername}->Hidden;
      $foldername =~ s/[^a-zA-Z0-9]/_/g;
      push @cats, $foldername;
    }

    my %mycategories;
    my @categories;
    foreach my $categoryname (@cats) {
      my $cat = Rival::AI::Categorizer::Category->by_name
	(
	 name => $categoryname,
	 _CategoriesDataLocation => ConcatDir($self->MyDocumentManager->Cabinet->Directory,"classification","rival-categorizer","categories"),
	);
      $mycategories{$categoryname} = $cat;
      push @categories, $cat;
    }

    my @test;
    my @train;

    my $traincutoff;
    if (exists $args{TrainTest}) {
      print "Doing a train test\n";
      $percentage = $args{TrainTest};
      die "Invalid percentage: $percentage\n" unless ($percentage >= 0 and $percentage <= 100);
    }

    my $seen = {};
    foreach my $document (values %{$self->MyDocumentManager->Documents}) {
      # figure out which valid categories this document belongs to
      my @items;
      foreach my $foldername (keys %{$document->Folders}) {
	if (! $document->Folders->{$foldername}->Hidden) {
	  $foldername =~ s/[^a-zA-Z0-9]/_/g;
	  my $c = $mycategories{$foldername};
	  if (UNIVERSAL::isa($c,'Rival::AI::Categorizer::Category')) {
	    push @items, $c;
	  }
	  if (! $seen->{$foldername}) {
	    my $folderdir = ConcatDir($dir,$foldername);
	    MkDirIfNotExists(Directory => $folderdir);
	  }
	}
	if (defined $percentage and int(rand(100)) > $percentage) {
	  my $d = Rival::AI::Categorizer::Document->new
	    (
	     name => $document->DocumentID,
	     content => $document->FullText,
	     _DocumentsDataLocation => $self->_DocumentsDataLocation,
	    );
	  push @test, $d;
	} else {
	  my $d = Rival::AI::Categorizer::Document->new
	    (
	     name => $document->DocumentID,
	     content => $document->FullText,
	     categories => \@items,
	     _DocumentsDataLocation => $self->_DocumentsDataLocation,
	    );
	  foreach my $c (@items) {
	    $c->add_document($d);
	  }
	  if (UNIVERSAL::isa($d,'Rival::AI::Categorizer::Document')) {
	    push @train, $d;
	  }
	}
      }
    }

    # create a knowledge set
    my $k = new Rival::AI::Categorizer::KnowledgeSet
      (
       _KnowledgeSetDataLocation => ConcatDir($self->MyDocumentManager->Cabinet->Directory,"classification","rival-categorizer","knowledge-set"),
       categories => \@categories,
       documents => \@train,
      );

    print "Training, this could take some time...\n";
    $self->MyLearner->train(knowledge_set => $k);
    $self->MyLearner->save_state($statepath) if $statepath;
  }
}

sub Classify {
  my ($self,%args) = @_;
  my $document = $args{Document};
  my $d = Rival::AI::Categorizer::Document->new
    (
     name => "target",
     content => $document->FullText,
     _DocumentsDataLocation => $self->_DocumentsDataLocation,
    );
  my $res = $self->MyLearner->categorize($d);
  # go ahead and prompt the user
  my $selected = {};
  my $potentials = 0;
  foreach my $item (keys %$res) {
    if ($res->{$item} > 0.3) {
      $selected->{$item} = 1;
    }
    if ($res->{$item} > 0.1) {
      $potentials++;
    }
  }
  if ($potentials > 1) {
    my $res2 = SubsetSelect
      (
       Title => "Select Folders",
       Message => "Please select to which folders this document belongs",
       Set => [sort keys %$res],
       Selection => $selected,
      );
    print Dumper($res2);
  }
  #   $document->MoveToFolders
  #     (
  #      # Folders => $
  #     );
}

sub ReclassifyFolder {
  my ($self,%args) = @_;
  # foreach document in the incoming folder, run the classifier on it,
  # add the classification data to metadata but with an explicit note
  # about the auto-classified source
  if (exists $self->MyDocumentManager->Cabinet->Folders->{$args{FolderName}}) {
    my $folder = $self->MyDocumentManager->Cabinet->Folders->{$args{FolderName}};
    foreach my $document (values %{$folder->Documents}) {
      $self->Classify(Document => $document);
    }
  }
}

1;


# foreach my $categoryname (@cats) {
#   my $c = $mycategories{$categoryname};
#   print "<$categoryname>\n";
#   foreach my $file (split /\n/,`find $dir/$categoryname`) {
#	if (-f $file) {
#	  my $filecontents = `cat $file`;
#	  if (defined $percentage and int(rand(100)) > $percentage) {
#	    my $d = Rival::AI::Categorizer::Document->new
#	      (
#	       name => $file,
#	       content => $filecontents,
#	       _DocumentsDataLocation => $self->_DocumentsDataLocation,
#	      );
#	    push @test, $d;
#	  } else {
#	    if (UNIVERSAL::isa($c,'Rival::AI::Categorizer::Category')) {
#	      my $d = Rival::AI::Categorizer::Document->new
#		(
#		 name => $file,
#		 content => $filecontents,
#		 categories => [$c],
#		 _DocumentsDataLocation => $self->_DocumentsDataLocation,
#		);
#	      $c->add_document($d);
#	      if (UNIVERSAL::isa($d,'Rival::AI::Categorizer::Document')) {
#		push @train, $d;
#	      }
#	    }
#	  }
#	}
#   }
# }

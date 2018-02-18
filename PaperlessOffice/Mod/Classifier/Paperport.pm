package PaperlessOffice::Mod::Classifier::Paperport;

use MyFRDCSA;
use Rival::AI::Categorizer;
use Rival::AI::Categorizer::Category;
use Rival::AI::Categorizer::Document;
use Rival::AI::Categorizer::KnowledgeSet;
use Rival::AI::Categorizer::Learner::NaiveBayes;
use Rival::AI::Categorizer::Learner::SVM;

use Data::Dumper;
use IO::File;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config MyLearner _DocumentsDataLocation /

  ];

sub init {
  my ($self,%args) = @_;
  $self->_DocumentsDataLocation
    ($UNIVERSAL::systemdir."/data/classification/paperport/rival-categorizer/documents");

  my $conf = $UNIVERSAL::paperlessoffice->Config->CLIConfig;

  my $dir = "$UNIVERSAL::systemdir/data/classification/paperport/classes";
  $statepath = "$UNIVERSAL::systemdir/data/classification/paperport/model";

  # Create the Learner, and restore state if need be
  $conf->{'--learner'} = "NaiveBayes";

  my $needstraining;
  if (exists $conf->{'--learner'}) {
    if ($conf->{'--learner'} eq "SVM") {
      if (-d $statepath and ! $conf->{'--retrain'}) {
	print "Restoring state\n";
	$self->MyLearner(Rival::AI::Categorizer::Learner::SVM->restore_state($statepath));
      } else {
	$self->MyLearner(Rival::AI::Categorizer::Learner::SVM->new());
	$needstraining = 1;
      }
    } elsif ($conf->{'--learner'} eq "NaiveBayes") {
      if (-d $statepath and ! $conf->{'--retrain'}) {
	print "Restoring state\n";
	$self->MyLearner(Rival::AI::Categorizer::Learner::NaiveBayes->restore_state($statepath));
      } else {
	$self->MyLearner(Rival::AI::Categorizer::Learner::NaiveBayes->new());
	$needstraining = 1;
      }
    } else {
      die "Learner ".$conf->{'--learner'}." not found\n";
    }
  }

  if ($needstraining) {
    # LOAD THE SOURCE DATA
    my @categories;
    my %mycategories;
    my @cats = split /\n/, `ls $dir`;
    # @cats = splice @cats,-30;
    foreach my $categoryname (@cats) {
      my $cat = Rival::AI::Categorizer::Category->by_name
	(
	 name => $categoryname,
	 _CategoriesDataLocation => $UNIVERSAL::systemdir."/data/classification/paperport/rival-categorizer/categories",
	);
      $mycategories{$categoryname} = $cat;
      push @categories, $cat;
    }

    my @test;
    my @train;

    my $traincutoff;
    if (exists $conf->{'--traintest'}) {
      print "Doing a train test\n";
      $percentage = $conf->{'--traintest'};
      die "Invalid percentage: $percentage\n" unless ($percentage >= 0 and $percentage <= 100);
    }

    foreach my $categoryname (@cats) {
      my $c = $mycategories{$categoryname};
      print "<$categoryname>\n";
      foreach my $file (split /\n/,`find $dir/$categoryname`) {
	if (-f $file) {
	  my $filecontents = `cat $file`;
	  if (defined $percentage and int(rand(100)) > $percentage) {
	    my $d = Rival::AI::Categorizer::Document->new
	      (
	       name => $file,
	       content => $filecontents,
	       _DocumentsDataLocation => $self->_DocumentsDataLocation,
	      );
	    push @test, $d;
	  } else {
	    if (UNIVERSAL::isa($c,'Rival::AI::Categorizer::Category')) {
	      my $d = Rival::AI::Categorizer::Document->new
		(
		 name => $file,
		 content => $filecontents,
		 categories => [$c],
		 _DocumentsDataLocation => $self->_DocumentsDataLocation,
		);
	      $c->add_document($d);
	      if (UNIVERSAL::isa($d,'Rival::AI::Categorizer::Document')) {
		push @train, $d;
	      }
	    }
	  }
	}
      }
    }

    # create a knowledge set
    my $k = new Rival::AI::Categorizer::KnowledgeSet
      (
       _KnowledgeSetDataLocation => $UNIVERSAL::systemdir."/data/classification/paperport/rival-categorizer/knowledge-set",
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
  my $doc = $args{Document};
  my $d = Rival::AI::Categorizer::Document->new
    (
     name => "target",
     content => $doc->FullText,
     _DocumentsDataLocation => $self->_DocumentsDataLocation,
    );
  print Dumper($self->MyLearner->categorize($d));
}

1;

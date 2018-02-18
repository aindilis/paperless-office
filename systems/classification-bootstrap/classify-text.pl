#!/usr/bin/perl -w

# this is an adaptation of the auto-debtags script to index the
# contents of sourceforge and freshmeat as well

use BOSS::Config;
use MyFRDCSA;

use Rival::AI::Categorizer;
use Rival::AI::Categorizer::Category;
use Rival::AI::Categorizer::Document;
use Rival::AI::Categorizer::KnowledgeSet;
use Rival::AI::Categorizer::Learner::NaiveBayes;
use Rival::AI::Categorizer::Learner::SVM;
use Data::Dumper;
use IO::File;

my $specification = "
	--rebuild	Ignore reloading the state and just rebuild
";

my $config = BOSS::Config->new
  (Spec => $specification,
   ConfFile => "");
my $conf = $config->CLIConfig;
$UNIVERSAL::systemdir = ConcatDir(Dir("minor codebases"),"paperless-office");
my $dir = "$UNIVERSAL::systemdir/data/classification/bootstrap/classes";

$statepath = "$UNIVERSAL::systemdir/data/classification/model";

# Create the Learner, and restore state if need be
$conf->{'--learner'} = "NaiveBayes";

my $learner;
my $needstraining;
if (exists $conf->{'--learner'}) {
  if ($conf->{'--learner'} eq "SVM") {
    if (-d $statepath and ! $conf->{'--rebuild'}) {
      print "Restoring state\n";
      $learner = Rival::AI::Categorizer::Learner::SVM->restore_state($statepath);
    } else {
      $learner = Rival::AI::Categorizer::Learner::SVM->new();
      $needstraining = 1;
    }
  } elsif ($conf->{'--learner'} eq "NaiveBayes") {
    if (-d $statepath and ! $conf->{'--rebuild'}) {
      print "Restoring state\n";
      $learner = Rival::AI::Categorizer::Learner::NaiveBayes->restore_state($statepath);
    } else {
      $learner = Rival::AI::Categorizer::Learner::NaiveBayes->new();
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
    my $cat = Rival::AI::Categorizer::Category->by_name(name => $categoryname);
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
	    (name => $file,
	     content => $filecontents);
	  push @test, $d;
	} else {
	  if (UNIVERSAL::isa($c,'Rival::AI::Categorizer::Category')) {
	    my $d = Rival::AI::Categorizer::Document->new
	      (name => $file,
	       content => $filecontents,
	       categories => [$c]);
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
     categories => \@categories,
     documents => \@train,
    );

  print "Training, this could take some time...\n";
  $learner->train(knowledge_set => $k);
  $learner->save_state($statepath) if $statepath;
}

my $targetcontents = `cat /var/lib/myfrdcsa/codebases/minor/paperless-office/first-scan/out.txt`;

my $d = Rival::AI::Categorizer::Document->new
  (name => "target",
   content => $targetcontents);

print Dumper($learner->categorize($d));
# my $hypothesis = $learner->categorize($d);
# foreach my $key (sort {$hypothesis->{scores}->{$b} <=> $hypothesis->{scores}->{$a}} keys %{$hypothesis->{scores}}) {
#   print "$key\t\t".$hypothesis->{scores}->{$key}."\n";
# }

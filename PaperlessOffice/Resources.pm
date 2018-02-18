package PaperlessOffice::Resources;

use Capability::TextAnalysis;
use PaperlessOffice::Mod::Calendar;
use PaperlessOffice::Mod::Classifier::Basic;
use PaperlessOffice::Mod::OCR;
use PaperlessOffice::Mod::TextAnalysis;

use PerlLib::SwissArmyKnife;

# want to add the semanta extractor item

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyOCR MyClassifier MyTextSummarization MyTextAnalysis
   MyCalendar /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyOCR
    (PaperlessOffice::Mod::OCR->new
     (
      EngineName => "Cuneiform",
     ));
}

sub Execute {
  my ($self,%args) = @_;
}

sub Summarize {
  my ($self,%args) = @_;
  if (! $self->MyTextSummarization) {
    $self->MyTextSummarization
      (Capability::TextSummarization->new);
  }
  return $self->MyTextSummarization->SummarizeText
	  (Text => $args{Text});
}

sub AnalyzeDocumentContents {
  my ($self,%args) = @_;
  $self->MyDocumentManager->AnalyzeDocuments();
}

### CLASSIFICATION

sub ClassifyAllUnclassifiedDocuments {
  my ($self,%args) = @_;
  $self->LoadDocumentClassifier;
  $self->MyClassifier->ReclassifyFolder
    (
     FolderName => "Incoming",
    );
}

sub RetrainTheDocumentClassifier {
  my ($self,%args) = @_;
  $self->LoadDocumentClassifier
    (
     Retrain => 1,
    );
}

sub LoadDocumentClassifier {
  my ($self,%args) = @_;
  if (! $self->MyClassifier or $args{Retrain}) {
    $self->MyClassifier
      (PaperlessOffice::Mod::Classifier::Basic->new
       (
	MyDocumentManager => $UNIVERSAL::paperlessoffice->MyDocumentManager,
	Learner => $args{Learner},
	Retrain => $args{Retrain},
	TrainTest => $args{TrainTest},
       ));
  }
}

### TEXT ANALYSIS

sub LoadTextAnalysis {
  my ($self,%args) = @_;
  if (! $self->MyTextAnalysis) {
    $self->MyTextAnalysis
      (
       PaperlessOffice::Mod::TextAnalysis->new(),
      );
  }
}

### CALENDAR

sub LoadCalendar {
  my ($self,%args) = @_;
  if (! $self->MyCalendar) {
    $self->MyCalendar
      (
       PaperlessOffice::Mod::Calendar->new(),
      );
  }
}

1;



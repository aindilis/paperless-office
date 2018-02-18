package PaperlessOffice::Mod::TextAnalysis;

# use Capability::FactExtraction;
use Capability::TextAnalysis;
use PerlLib::SwissArmyKnife;
use Sayer;

use Cache::FileCache;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MySayer MyTextAnalysis /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MySayer
    (Sayer->new
     (
      DBName => "sayer_paperlessoffice",
     ));
  $self->MyTextAnalysis
    (Capability::TextAnalysis->new
     (
      Sayer => $self->MySayer,
      DontSkip => {
		   "Tokenization" => 1,
		   "TermExtraction" => 1,
		   # "DateExtraction" => 1,
		   "GetDatesTIMEX3" => 1,
		   "NamedEntityRecognition" => 1,
		   "NounPhraseExtraction" => 1,
		   # "SemanticAnnotation" => 1,
		  },
     ));
}

sub AnalyzeDocument {
  my ($self,%args) = @_;
  return $self->MyTextAnalysis->AnalyzeText
    (
     Text => $args{Document}->FullText,
    );
}

# sub DoFactExtraction {
#   my ($self,%args) = @_;
#   my $results = FactExtraction
#     (
#      Sayer => $self->MySayer,
#      Sentences => $args{Sentences},
#     );
#   return {
# 	  Target => Capability::FactExtraction::Process
# 	  (
# 	   Topic => $args{Topic},
# 	   Results => $results,
# 	  ),
# 	 };
# }

1;

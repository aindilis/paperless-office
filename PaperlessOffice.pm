package PaperlessOffice;

use BOSS::Config;
use Manager::Dialog qw(Choose);
use MyFRDCSA;
use PaperlessOffice::Cabinet;
use PaperlessOffice::DocumentManager;
use PaperlessOffice::GUI;
use PaperlessOffice::Resources;
use PerlLib::SwissArmyKnife;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config Conf MyDocumentManager CabinetName Cabinets MyGUI
   MyResources Debug CabinetsDir /

  ];

sub init {
  my ($self,%args) = @_;
  $specification = "
	-l			List cabinets
	-c <cabinet>		The cabinet to use

	-f			Fake scan
	-s			Small (only load a few documents, for development purposes)

	-u [<host> <port>]	Run as a UniLang agent
	-w			Require user input before exiting
	-W [<delay>]		Exit as soon as possible (with optional delay)
";
  $UNIVERSAL::systemdir = ConcatDir(Dir("minor codebases"),"paperless-office");
  $self->Config(BOSS::Config->new
		(Spec => $specification,
		 ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  $self->Conf($conf);
  if (exists $conf->{'-u'}) {
    $UNIVERSAL::agent->Register
      (Host => defined $conf->{-u}->{'<host>'} ?
       $conf->{-u}->{'<host>'} : "localhost",
       Port => defined $conf->{-u}->{'<port>'} ?
       $conf->{-u}->{'<port>'} : "9000");
  }
  MkDirIfNotExists
    (
     Directory => "/tmp/paperless-office/trash",
    );
  $self->Cabinets({});
  $self->CabinetsDir($UNIVERSAL::systemdir."/data/cabinets");
  $self->MyResources
    (PaperlessOffice::Resources->new);
}

sub CreateDataDir {
  my ($self,%args) = @_;
  my $datadir = "$UNIVERSAL::systemdir/data";
  if (! -d $datadir) {
    system "mkdir -p \"$datadir\"";
  }
}

sub Execute {
  my ($self,%args) = @_;
  my $conf = $self->Config->CLIConfig;

  if (exists $conf->{'-l'}) {
    print Dumper($self->ListCabinets);
    exit;
  }

  $self->LoadGUI();

  $UNIVERSAL::managerdialogtkwindow = $self->MyGUI->MyMainWindow;
  $self->CreateDataDir;
  $self->LoadCabinets;
  $self->MyDocumentManager
    (PaperlessOffice::DocumentManager->new
     (Cabinet => $self->Cabinets->{$self->CabinetName}));
  $self->MyDocumentManager->LoadDocuments;

  #   # fix this eventually
  #   if (exists $conf->{'-u'}) {
  #     # enter in to a listening loop
  #     while (1) {
  #       $UNIVERSAL::agent->Listen(TimeOut => 10);
  #     }
  #   }
  #   if (exists $conf->{'-w'}) {
  #     Message(Message => "Press any key to quit...");
  #     my $t = <STDIN>;
  #   }

  $self->MyGUI->Execute();
}

sub LoadGUI {
  my ($self,%args) = @_;
  if (! $self->MyGUI) {
    $self->MyGUI
      (PaperlessOffice::GUI->new());
  }
}

sub ProcessMessage {
  my ($self,%args) = @_;
  my $m = $args{Message};
  my $it = $m->Contents;
  if ($it) {
    if ($it =~ /^echo\s*(.*)/) {
      $UNIVERSAL::agent->SendContents
	(Contents => $1,
	 Receiver => $m->{Sender});
    } elsif ($it =~ /^(quit|exit)$/i) {
      $UNIVERSAL::agent->Deregister;
      exit(0);
    }
  }
}

sub ListCabinets {
  my ($self,%args) = @_;
  my $cabinetsdir = $self->CabinetsDir;
  return [split /\n/, `ls $cabinetsdir`];
}

sub LoadCabinets {
  my ($self,%args) = @_;
  my $cabinetsdir = $self->CabinetsDir;
  foreach my $dir (@{$self->ListCabinets}) {
    $self->Cabinets->{$dir} = PaperlessOffice::Cabinet->new
      (
       Name => $dir,
       DocumentDirectory => $cabinetsdir."/".$dir."/documents",
      );
  }
  my $conf = $self->Config->CLIConfig;
  my $cabinet = $conf->{'-c'} || Choose(keys %{$self->Cabinets});
  $self->CabinetName($cabinet);
}

1;

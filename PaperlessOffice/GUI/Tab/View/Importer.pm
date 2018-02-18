package PaperlessOffice::GUI::Tab::View::Importer;

use PaperlessOffice::Mod::Importer;
use Manager::Dialog qw(Approve ApproveCommands QueryUser);
use PerlLib::SwissArmyKnife;

use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use Term::ReadKey;
use Tk;
use Tk::FileDialog;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyView Top1 MyMainWindow MyImporter /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyView($args{View});
  $self->MyMainWindow
    ($UNIVERSAL::paperlessoffice->MyGUI->MyMainWindow);
  $self->Top1
    ($self->MyMainWindow->Toplevel
     (
      -title => "Select File or Directory",
     ));
}

sub Execute {
  my ($self,%args) = @_;
  # a filename dialog

  my $fileframe = $self->Top1->Frame();

  my $Horiz = 1;
  my $fname;
  my $LoadDialogFile = $fileframe->FileDialog
    (
     -Title => 'Select File',
     -Create => 0,
    );
  $LoadDialogFile->configure
    (
     -ShowAll => 'NO',
    );

  my $LoadDialogDir = $fileframe->FileDialog
    (
     -Title => 'Select Directory',
     -SelDir => 1,
     -Create => 0,
    );
  $LoadDialogDir->configure
    (
     -ShowAll => 'NO',
    );

  $fileframe->Entry
    (
     -width => 80,
     -textvariable => \$fname,
    )
      ->pack
	(
	 -expand => 1,
	 -fill => 'x',
	);

  $fileframe->Button
    (-text => 'Select File',
     -command => sub {
       $fname = $LoadDialogFile->Show
	 (
	  -Horiz => $Horiz,
	 );
     })->pack
       (
	-side => "left",
	-expand => 1,
	-fill => 'x',
       );

  $fileframe->Button
    (-text => 'Select Dir',
     -command => sub {
       $fname = $LoadDialogDir->Show
	 (
	  -Horiz => $Horiz,
	 );
     })->pack
       (
	-side => "left",
	-expand => 1,
	-fill => 'x',
       );
  $fileframe->pack(-side => "top");

  $buttons1 = $self->Top1->Frame();
  $buttons1->Checkbutton
    (
     -text => "Turn parent directories into paperless-office folders",
     -command => sub { },
    )->pack(-fill => "x");
  $buttons1->pack(-side => "bottom");
  $buttons2 = $self->Top1->Frame();
  $buttons2->Button
    (
     -text => "Import",
     -command => sub { $self->ActionImport
			 (
			  FileOrDir => $fname,
			 ),},
    )->pack(-side => "left");
  $buttons2->Button
    (
     -text => "Cancel",
     -command => sub {$self->ActionCancel},
    )->pack(-side => "left");
  $buttons2->pack(-side => "bottom");

  $self->Top1->bind
    (
     "all",
     "<Escape>",
     sub {
       $self->Cancel();
     },
    );
}

sub ActionImport {
  my ($self,%args) = @_;
  $self->LoadImporter;
  if (-e $args{FileOrDir}) {
    $self->MyImporter->ImportFileOrDir
      (
       FileOrDir => $args{FileOrDir},
       Directory => $UNIVERSAL::paperlessoffice->Cabinets->{$UNIVERSAL::paperlessoffice->CabinetName}->DocumentDirectory,
       UseParentDirsAsFolders => 1,
      );
  }
}

sub LoadImporter {
  my ($self,%args) = @_;
  if (! $self->MyImporter) {
    $self->MyImporter(PaperlessOffice::Mod::Importer->new);
  }
}

sub ActionCancel {
  my ($self,%args) = @_;
  # remove the item from the directory
  $self->Top1->destroy;
}

1;

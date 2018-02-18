package PaperlessOffice::GUI::TabManager;

use Data::Dumper;

use Tk::NoteBook;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyMainWindow MyNoteBook MainMenu MyMenu Tabs TabInfo /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Tabs({});
  $self->TabInfo
    ({
      "View" => {
		 Module => "View",
		 Default => 1,
		},
      # "Scan" => {
      # 		 Module => "Scan",
      # 		 Default => 1,
      # 		},
     });
}

sub Execute {
  my ($self,%args) = @_;
  $self->StartGUI(%args);
}

sub StartGUI {
  my ($self,%args) = @_;
  $self->MyMainWindow($args{MyMainWindow});
  # $self->MainMenu($args{MainMenu});
  my $frame = $self->MyMainWindow->Frame();
  $frame->pack
    (
     -expand => 1,
     -fill => 'both',
    );
  $self->MyNoteBook
    ($frame->NoteBook
     (
     ));
  # $self->MyMenu($self->MainMenu->Menubutton(-text => "Tabs"));
  foreach my $tabname (
		       "View",
		       # "Scan",
		      ) {
    my $open = 0;
    if ($self->TabInfo->{$tabname}->{Default}) {
      $self->StartTab
	(
	 Tabname => $tabname,
	 # Flags => $args{Flags},
	);
      $open = 1;
    }
    $self->AddTabToTabMenu
      (
       Tabname => $tabname,
       Open => $open,
      );
  }
  $self->MyNoteBook->pack(-expand => 1, -fill => "both");
}

sub StartTab {
  my ($self,%args) = @_;
  my $myframe = $self->MyNoteBook->add($args{Tabname}, -label => $args{Tabname});
  my $modulename = "PaperlessOffice::GUI::Tab::".$self->TabInfo->{$args{Tabname}}->{Module};
  # print Dumper({Modulename => $modulename});
  my $require = $modulename;
  $require =~ s/::/\//g;
  $require .= ".pm";
  my $fullrequire = "/var/lib/myfrdcsa/codebases/minor/paperless-office/$require";
  if (! -f $fullrequire) {
    print "ERROR, no <<<$fullrequire>>>\n";
    return;
  }
  require $fullrequire;
  my $newtab = eval "$modulename->new(Frame => \$myframe)";
  my $errorstring = $@;
  if (defined $newtab) {
    $self->Tabs->{$args{Tabname}} = $newtab;
    $newtab->Execute
      (
       Flags => $args{Flags},
      );
  } else {
    print Dumper($args{Tabname});
    print $errorstring."\n";
  }
}

sub AddTabToTabMenu {
  my ($self,%args) = @_;
  my $open = $args{Open};
  # $self->MyMenu->checkbutton(-label => $args{Tabname}, -variable => \$open);
}

1;

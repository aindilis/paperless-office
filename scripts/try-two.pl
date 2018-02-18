#!/usr/bin/perl
use warnings;
use strict;
use Tk;
use Tk::NoteBook;
use Tk::Pane;

my $mw = MainWindow->new();
$mw->geometry('600x400+300+100');

my $pane = $mw->Scrolled('Pane', Name => 'scroll test',
			 -width => 600,
			 -height => 400,
			 -scrollbars => 'osoe',
			 -sticky => 'nw',
			);
$pane->pack(
	    -fill => 'both',
	   );

my $nb = $pane->NoteBook(-width=>400,
			 -background => 'green', 
			);

my @colors = qw(ivory yellow white black cyan pink snow
		linen bisque green azure  gray
		navy blue turquoise chartreuse khaki 
		gold peru red);

my %tabs;

for (1..20) {
  $tabs{$_}{'name'} = 'tab'.$_;
  #print 'tab->',$tabs{$_}{'name'},"\n";
  my $tab = $nb->add("page$_", -label=>"Student $_");

  $tabs{$_}{'text'} = $tab->Scrolled('Text', -scrollbars=>'se',
				     ,-bg => $colors[0])
    ->pack(
	   -side => 'left',
	   -anchor => 'n',
	   -fill => 'both',
	  );
  $tabs{$_}{'text'}->insert('end', "Tab $_");

  $tabs{$_}{'canvas'} = $tab->Canvas(-background=>"yellow")
    ->pack(
	   -side => 'left',
	   -anchor => 'n',
	   -fill => 'both'
	  );

  $tabs{$_}{'canvas'}->createText(30,40, -text=>"Canvas $_");

  #$nb->Resize;
  push (@colors,shift(@colors));
}

$nb->pack(
	  -side => 'top',
	  -fill => 'both',
	 );

$tabs{1}{'text'}->insert('end',"\nAdd this from outside the loop");

MainLoop;

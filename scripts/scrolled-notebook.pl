#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::NoteBook;

our $mw = MainWindow->new;

my $canvas = $mw->Scrolled('Canvas',-bg=>'red')->pack;
our $nb = $canvas->NoteBook;

### add 20 tabs to notebook
for ( 1 .. 20 ) {
  my $title = "Untitled ($_)";
  $nb->add( $_, -label => $title );
}

### embed the notebook widget into the canvas
my $nb_in_canvas = $canvas->createWindow
  ( 0, 0, -window => $nb, -anchor => 'nw' );

$canvas->update;
### the whole notebook is larger than what can be initially displayed
### so we'll have to sroll it later on in the program

$canvas->configure
  (
   -scrollregion => [0,0,$nb->reqwidth,$nb->reqheight]
  );

MainLoop();

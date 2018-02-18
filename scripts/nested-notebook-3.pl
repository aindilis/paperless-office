#!/usr/bin/perl -w

require 5.004;

use Tk;
use English;
use strict;

require Tk::NoteBook;

my $main     = new MainWindow;

$main-> focusmodel('passive');
#    $main-> geometry('429x229+326+314');
$main-> resizable(1, 1);

my $top  = $main-> Frame(-borderwidth => 3, -relief => 'groove')->pack;

my $Nb   = $top-> NoteBook(-dynamicgeometry => 0)->pack;
for my $n (1..3) {
  my $Nb1  = $Nb-> add("Nb".$n, -label => 'Tab'.$n);
  my $SNb  = $Nb1-> NoteBook(-dynamicgeometry => 0)->pack;
  for my $j (1..4) {
    my $SNB1 = $SNb-> add("SNb".$j, -label => 'SNb'.$j);
    $SNB1-> Label(-text => "$n-$j Content")->pack;
  }
}
MainLoop;
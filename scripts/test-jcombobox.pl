#!/usr/bin/perl -w

use Tk;

use Tk::JComboBox;

my @choices = (qw/black green/, {qw/-name blue -value #0000ff/});


my $mw = MainWindow->new;

my $jcb = $mw->JComboBox
  (
   -choices =>
   [
    {-name => "black", -selected => 1},
    {-name => "green"},
   ],
  )->pack;

MainLoop();

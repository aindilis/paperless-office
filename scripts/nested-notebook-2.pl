#!/usr/bin/perl -w

require 5.004;

use Tk;
use English;
use strict;

require Tk::NoteBook;

my $main     = new MainWindow;

$main-> focusmodel('passive');
$main-> geometry('429x229+326+314');
$main-> resizable(1, 1);

###########

my $top = $main-> Frame(-borderwidth => 3, -relief => 'groove')->pack(-expand =>
1, -fill =>  'both');

###########

my $Notebook = $top-> NoteBook(-dynamicgeometry => 0)->pack(-fill => 'both',
-expand =>  1);
$Notebook-> raise("NBPage");
my $NBPage = $Notebook-> add("NBPage", -label => 'NBPage', -underline =>
5)-> pack(-fill => 'both', -expand => 1);

###########

my $SubNotebook = $NBPage-> NoteBook(-dynamicgeometry => 0)->pack(-fill =>
'both', -expand =>  1);
$SubNotebook-> raise("SNBPage");
my $SNBPage = $SubNotebook-> add("SNBPage", -label => 'SNBPage', -underline =>
5)-> pack(-fill => 'both', -expand => 1);

MainLoop;

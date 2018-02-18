#!/usr/bin/perl -w

# eval 'exec /apps/tools/utils/sol2/bin/perl -w -S $0 ${1+"$@"}'
#     if 0; # not running under some shell

# eval 'exec /usr/local/bin/perl -w -S $0 ${1+"$@"}'
#     if 0; # not running under some shell

require 5.004;

use Tk;
use English;
use strict;

require Tk::NoteBook;

     my $main     = new MainWindow;

     $main-> focusmodel('passive');
     $main-> geometry('429x229+326+314');
     $main-> resizable(1, 1);

     my $top  = $main-> Frame(-borderwidth => 3, -relief => 'groove')->pack;

     my $Nb   = $top-> NoteBook(-dynamicgeometry => 0)->pack;
     my $Nb1  = $Nb-> add("Nb1", -label => 'Nb1')->pack;
     my $Nb1F = $Nb1-> Frame(-borderwidth => 5, -relief => 'groove')->pack;

     my $SNb  = $Nb1F-> NoteBook(-dynamicgeometry => 0)->pack;
     $SNb-> add("SNb1", -label => 'SNb1')->pack;

     MainLoop;

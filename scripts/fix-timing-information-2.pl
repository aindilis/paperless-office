#!/usr/bin/perl -w

use DateTime;
use KBS2::Client;
use KBS2::Util;
use Manager::Dialog qw(ApproveCommands);
use PerlLib::SwissArmyKnife;

die "dangerous script\n";

my $CabinetName = "paperport";
my $Context = "Org::FRDCSA::PaperlessOffice::Cabinet::$CabinetName";

$MyClient =
  KBS2::Client->new
  (
   Context => $Context,
  );

my $Metadata;

# match the folder and file combinations with date time

# LoadMetadata();
# print Dumper(keys %$Metadata);

my $data = {};
my @assertions;
foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport/documents`) {
  if ($file =~ /\.pnm$/) {
    my $filecp = $file;
    $filecp =~ s|/var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/paperport/documents/||;
    print "<$filecp>\n";
    my $folder = dirname($filecp);
    my $pnm = basename($filecp);
    my $stat = stat( $file );
    my $dt = DateTime->from_epoch(epoch => $stat->ctime);

    # obtain the file

    $data->{$folder}->{$pnm} = $stat->ctime;
    print Dumper
      ({
	File => $pnm,
	Folder => $folder,
	Ctime => $dt->ymd." ".$dt->hms,
       });
    push @assertions, ["has-datetimestamp",["document-fn",$CabinetName,$folder],$stat->ctime];
  }
}

foreach my $assertion (@assertions) {
  %sendargs =
    (
     Assert => [$assertion],
     Context => $Context,
     QueryAgent => 1,
     InputType => "Interlingua",
     Flags => {
	       AssertWithoutCheckingConsistency => 1,
	      },
    );
  print Dumper(\%sendargs);
  my $res = $MyClient->Send(%sendargs);
  print Dumper({AssertResult => $res});
}

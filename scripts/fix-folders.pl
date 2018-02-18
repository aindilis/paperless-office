#!/usr/bin/perl -w

use KBS2::Client;
use KBS2::Util;
use Manager::Dialog qw(ApproveCommands);
use PerlLib::SwissArmyKnife;

my $CabinetName = "paperport";
my $Context = "Org::FRDCSA::PaperlessOffice::Cabinet::$CabinetName";

$MyClient =
  KBS2::Client->new
  (
   Context => $Context,
  );

my $Metadata;
LoadMetadata();

print Dumper(keys %$Metadata);
foreach my $dir (split /\n/, `ls /var/lib/myfrdcsa/codebases/minor/paperless-office/data/cabinets/$CabinetName/documents`) {
  print "$dir\n";
  my $res = GetMetadata
    (
     DocumentID => $dir,
     Predicate => "has-folder",
    );
  print Dumper($res);
}

sub LoadMetadata {
  my (%args) = @_;
  my $message = $MyClient->Send
    (
     QueryAgent => 1,
     Command => "all-asserted-knowledge",
     Context => $Context,
    );
  # print Dumper($message);
  if (defined $message) {
    my $assertions = $message->{Data}->{Result};
    foreach my $assertion (@$assertions) {
      my $pred = $assertion->[0];
      if ($assertion->[0] eq "has-type") {
	$Metadata->{"has-type"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-folder") {
	$Metadata->{"has-folder"}->{DumperQuote2($assertion->[1])}->{$assertion->[2]} = 1;
      }
      if ($assertion->[0] eq "has-fulltext") {
	$Metadata->{"has-fulltext"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-thumbnail") {
	$Metadata->{"has-thumbnail"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
      if ($assertion->[0] eq "has-pdf") {
	$Metadata->{"has-pdf"}->{DumperQuote2($assertion->[1])} = $assertion->[2];
      }
    }
  }
}


sub GetMetadata {
  my (%args) = @_;
  my $documentfn = DumperQuote2(["document-fn",$CabinetName,$args{DocumentID}]);
  if (exists $Metadata->{$args{Predicate}}->{$documentfn}) {
    return {
	    Success => 1,
	    Result => $Metadata->{$args{Predicate}}->{$documentfn},
	   };
  }
  return {
	  Success => 0,
	 };
}

sub SetMetadata {
  my (%args) = @_;
  my $docrel = ["document-fn",$CabinetName,$args{DocumentID}];
  my $documentfn = DumperQuote2($docrel);
  my $assert = 0;
  if (exists $Metadata->{$args{Predicate}}->{$documentfn}) {
    if (DumperQuote2($args{Value}) ne DumperQuote2($Metadata->{$args{Predicate}}->{$documentfn})) {
      # update the value in the KB and the array

      # first unassert the old value
      my %sendargs =
	(
	 Unassert => [[$args{Predicate},$docrel,$Metadata->{$args{Predicate}}->{$documentfn}]],
	 Context => $Context,
	 QueryAgent => 1,
	 InputType => "Interlingua",
	 Flags => {
		   AssertWithoutCheckingConsistency => 1,
		  },
	);
      print Dumper(\%sendargs);
      my $res = $MyClient->Send(%sendargs);
      print Dumper({UnassertResult => $res});

      # make sure that succeeded
      $assert = 1;
    } else {
      # it's fine, leave it alone
    }
  } else {
    # assert the value into the KB
    $assert = 1;
  }
  if ($assert) {
    # send the new value
    if (defined $args{Value}) {
      %sendargs =
	(
	 Assert => [[$args{Predicate},$docrel,$args{Value}]],
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
      $Metadata->{$args{Predicate}}->{$documentfn} = $args{Value};
    } else {
      delete $Metadata->{$args{Predicate}}->{$documentfn};
    }
  }
}

#!/usr/bin/perl -w

# rather than manually classify my bookmarks, I'll just cluster them,
# and extract cluster names

use BOSS::Config;
use Manager::Dialog qw(Message SubsetSelect);
use PerlLib::ToText;
use PerlLib::Util;

use Cache::FileCache;
use Data::Dumper;
use IO::File;
use WWW::Mechanize::Cached;
use Yahoo::Search;

$specification = q(
	-f <file>		Bookmarks file (places.sqlite)
	-c <actualcount>	Manually set actual count
	-s			Skip downloading phase
	-S			Skip clustering phase
  );

print "Initializing...\n";
my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
$UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/paperless-office";

my $dir = "$UNIVERSAL::systemdir/data/classification/bootstrap/classes";

my $cacheobj = new Cache::FileCache
  ({
    namespace => 'paperless-office-classification-bootstrap',
    default_expires_in => "2 years",
    cache_root => "$UNIVERSAL::systemdir/data/classification/bootstrap/FileCache",
   });

my $cacher = WWW::Mechanize::Cached->new
  (
   cache => $cacheobj,
   timeout => 15,
  );

my $totext = PerlLib::ToText->new;

my $c = `cat filing-system`;
foreach my $line (split /\n/, $c) {
  if ($line =~ /\S/) {
    BuildClass(Class => $line);
  }
}

sub BuildClass {
  my %args = @_;
  my $class = $args{Class};
  print "CLASS: $class\n";
  $class =~ s/\W/_/g;
  if (! -d "$dir/$class") {
    mkdir "$dir/$class";
  }
  my @Results = Yahoo::Search->Results(Doc => $args{Class},
				       AppId => "Paperless-Office-Classification-Bootstrap",
				       # The following args are optional.
				       # (Values shown are package defaults).
				       Mode         => 'all', # all words
				       Start        => 0,
				       Count        => 20,
				       Type         => 'html',
				       AllowAdult   => 0, # no porn, please
				       AllowSimilar => 0, # no dups, please
				       Language     => undef,
				      );

  foreach my $Result (@Results) {
    printf "Result: #%d\n",  $Result->I + 1;
    printf "Url:%s\n",       $Result->Url;
    printf "%s\n",           $Result->ClickUrl;
    printf "Summary: %s\n",  $Result->Summary;
    printf "Title: %s\n",    $Result->Title;

    $cacher->get( $Result->Url );
    my $res = $totext->ToText(String => $cacher->content());
    if (exists $res->{Success} and $res->{Success}) {
      my $fh = IO::File->new;
      my $url2 = $Result->Url;
      $url2 =~ s/\W/_/g;
      $fh->open(">$dir/$class/$url2") or print "can't open\n";
      print $fh $res->{Text};
      $fh->close;
    }
  }
}

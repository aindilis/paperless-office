#!/usr/bin/perl

use DBM::Deep;
my $db = DBM::Deep->new( "foo.db" );

$db->{key} = 'value';
print $db->{key};

$db->put('key' => 'value');
print $db->get('key');

# true multi-level support
$db->{my_complex} = [
		     'hello', { perl => 'rules' },
		     42, 99,
		    ];

$db->begin_work;

# Do stuff here

$db->rollback;
$db->commit;

tie my %db, 'DBM::Deep', 'foo.db';
$db{key} = 'value';
print $db{key};

tied(%db)->put('key' => 'value');
print tied(%db)->get('key');

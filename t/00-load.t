#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gearman::XS::Declare' );
}

diag( "Testing Gearman::XS::Declare $Gearman::XS::Declare::VERSION, Perl $], $^X" );

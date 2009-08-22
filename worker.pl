#!/usr/bin/env perl

=pod
# use Gearman::XS qw(:constants);
# use Gearman::XS::Client;
# my $client = Gearman::XS::Client->new;
# my $ret = $client->add_server(  '127.0.0.1'  , '7003');
# die $client->error if ( $ret != GEARMAN_SUCCESS );

# $client->do("dummy" , "");
# $client->do("foo" , "");

# use Gearman::Worker;
# my $worker = Gearman::Worker->new;
# $worker->job_servers('127.0.0.1');
# $worker->register_function( $funcname => \&do_x );
# $worker->work while 1;
use Gearman::XS qw(:constants);
use Gearman::XS::Worker;
my $core = Gearman::XS::Worker->new( );
my $ret = $core->add_server( '127.0.0.1', '7003' );
die $core->error if ( $ret != GEARMAN_SUCCESS );
# $core->add_function( $func_name , 0 , \&{ "main::" . $func_name } , { });

sub run (&) { return shift }

sub work {
    while (1) {
        warn "$$: work";
        my $ret = $core->work();
        die $core->error if ( $ret != GEARMAN_SUCCESS );
    }
}
sub add_worker {
    my ( $func_name , $args , $function );
    if( scalar @_ == 3 ) {
        ( $func_name , $args , $function ) = @_;
    }
    elsif( scalar @_ == 2 ) {
        ( $func_name , $function ) = @_;
    }

    $registerd{ $func_name } = 1;

    my %options = ();
    if( ref(\$args) eq 'SCALAR' ) {
        my @args = split /\s+/, $args;
        for ( @args ) {
            $options{duplicate} = 1 if m/:duplicate/;
            $options{isolate}   = 1 if m/:isolate/;
        }
    }
    elsif( ref($args) eq 'HASH' ) {
        %options = ( %$args );
    }
    
    # export function to main::
    ${ main:: }{ $func_name } = $function;

    if ( $options{isolate} ) {
        my $pid = fork;
        die "fork() failed: $!" unless defined $pid;
        if ( $pid == 0 ) {
            warn "$$: add function $func_name";
            $core->add_function( 
                $func_name => 0 => \&{ ${ main:: }{ $func_name } } => { }
            );
            goto WORK;
        }
    }
    elsif( $options{duplicate} ) {
        my $pid = fork;
        die "fork() failed: $!" unless defined $pid;
        warn "$$: add function $func_name";
        $core->add_function( 
            $func_name => 0 => \&{ ${ main:: }{ $func_name } } => { }
        );
        goto WORK if( $pid == 0 );
    }
    else {
        warn "$$: add function $func_name";
        $core->add_function( 
            $func_name => 0 => \&{ ${ main:: }{ $func_name } } => { }
        );
    }
}

=cut

use lib 'lib';
use Gearman::XS::Declare;

init;
add_servers( '127.0.0.1:7003' );

add_worker common => run {
    my $workload = shift;

};

add_worker foo => ":isolate" => run {
    my $workload = shift;



};

add_worker foo3 => ":fork" => run {
    my $workload = shift;
};


add_worker dummy => { } => run {
    warn "dummy";
    $client->do("foo" , "");
};

WORK:
work();

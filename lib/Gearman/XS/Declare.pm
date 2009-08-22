package Gearman::XS::Declare;
use Gearman::XS qw(:constants);
use Gearman::XS::Worker;
use warnings;
use strict;
my %registerd = ();
use vars qw($core);
our @EXPORT = qw(init add_servers run work add_worker);
use base qw(Exporter::Lite);

=head1 NAME

Gearman::XS::Declare

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

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

=head1 EXPORT

=head1 FUNCTIONS

=cut


sub init {
    $core = Gearman::XS::Worker->new( @_ );
}


sub add_servers {
    my @servers = @_;
    for ( @servers ) {
        my $ret = $core->add_server( split /:/, $_ );
        die $core->error if ( $ret != GEARMAN_SUCCESS );
    }
}

sub run (&) { return shift }

sub work {

    use Data::Dumper;
    warn "$$: ". Dumper( \%registerd ) ;
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
    if( $args and ref(\$args) eq 'SCALAR' ) {
        my @args = split /\s+/, $args;
        for ( @args ) {
            $options{fork} = 1 if m/:fork/;
            $options{isolate}   = 1 if m/:isolate/;
        }
    }
    elsif( $args and ref($args) eq 'HASH' ) {
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
    elsif( $options{fork} ) {
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



=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gearman-xs-declare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gearman-XS-Declare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gearman::XS::Declare


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gearman-XS-Declare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gearman-XS-Declare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gearman-XS-Declare>

=item * Search CPAN

L<http://search.cpan.org/dist/Gearman-XS-Declare/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gearman::XS::Declare

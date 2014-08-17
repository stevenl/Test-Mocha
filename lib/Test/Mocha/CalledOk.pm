package Test::Mocha::CalledOk;

use strict;
use warnings;

use Test::Builder;
use Test::Mocha::Util qw( getattr );

my $TB = Test::Builder->new;

sub test {
    my ( $class, $method_call, $exp, $test_name ) = @_;

    my $mock    = $method_call->invocant;
    my $calls   = getattr( $mock, 'calls' );
    my $got     = grep { $method_call->satisfied_by($_) } @{$calls};
    my $test_ok = $class->is( $got, $exp );

    my $exp_times = $class->stringify($exp);
    $test_name = "$method_call was called $exp_times" if !defined $test_name;

    # Test failure report should not trace back to Mocha modules
    ## no critic (ProhibitMagicNumbers)
    local $Test::Builder::Level = 3;
    $TB->ok( $test_ok, $test_name );
    ## use critic

    # output diagnostics to aid with debugging
    unless ( $test_ok || $TB->in_todo ) {

        my $call_history;
        if ( @{$calls} ) {
            $call_history .= "\n    " . $_->stringify_long foreach @{$calls};
        }
        else {
            $call_history = "\n    (No methods were called)";
        }

        $TB->diag(<<"END");
Error: unexpected number of calls to '$method_call'
         got: $got time(s)
    expected: $exp_times
Complete method call history (most recent call last):$call_history
END
    }
    return;
}

1;

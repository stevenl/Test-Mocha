package Test::Mocha::Stub;
# ABSTRACT: Create methods stubs for mock objects

use strict;
use warnings;
use feature 'state';

use Carp qw( croak );
use Test::Mocha::StubbedCall;
use Test::Mocha::Types qw( MockWrapper Slurpy );
use Test::Mocha::Util qw( extract_method_name get_attribute_value );
use Type::Params qw( compile );
use Types::Standard qw( ArrayRef ClassName HashRef slurpy );

our $AUTOLOAD;

sub new {
    state $check = compile( ClassName, slurpy MockWrapper );
    my ($class, $self) = $check->(@_);

    return bless $self, $class;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method_name = extract_method_name($AUTOLOAD);

    my $i = 0;
    my $seen_slurpy;
    foreach (@args) {
        if (Slurpy->check($_)) {
            $seen_slurpy = 1;
            last;
        }
        $i++;
    }
    croak 'No arguments allowed after a slurpy type constraint'
        if $i < $#args;

    if ($seen_slurpy) {
        my $slurpy = $args[$i]->{slurpy};
        croak 'Slurpy argument must be a type of ArrayRef or HashRef'
            unless $slurpy->is_a_type_of(ArrayRef)
                || $slurpy->is_a_type_of(HashRef);
    }

    my $stub = Test::Mocha::StubbedCall->new(
        name => $method_name,
        args => \@args,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $stubs = get_attribute_value($mock, 'stubs');

    # add new stub to front of queue so that it takes precedence
    # over existing stubs that would satisfy the same invocations
    unshift @{ $stubs->{$method_name} }, $stub;

    return $stub;
}

1;
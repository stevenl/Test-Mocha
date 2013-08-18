package Test::Mocha::Role::MethodCall;
# ABSTRACT: A role that represents a method call

use Moose::Role;
use namespace::autoclean;

use Devel::PartialDump;
use Test::Mocha::Types qw( Matcher );
use Test::Mocha::Util qw( match );
use Types::Standard qw( ArrayRef Str );

# cause string overloaded objects (Matchers) to be stringified
my $Dumper = Devel::PartialDump->new(objects => 0, stringify => 1);

has 'name' => (
    isa => Str,
    is  => 'ro',
    required => 1
);

has 'args' => (
    isa     => ArrayRef,
    traits  => ['Array'],
    handles => { args => 'elements' },
    default => sub { [] },
);

# Stringifies this method call to something that roughly resembles what you'd
# type in Perl.

sub as_string {
    my ($self) = @_;
    return $self->name . '(' . $Dumper->dump($self->args) . ')';
}

# Returns true if the given C<$invocation> would satisfy this method call.

sub satisfied_by {
    my ($self, $invocation) = @_;

    return unless $invocation->name eq $self->name;

    my @expected = $self->args;
    my @input    = $invocation->args;
    # invocation arguments can't be argument matchers
    ### assert: ! grep { Matcher->check($_) } @input

    while (@input && @expected) {
        my $matcher = shift @expected;
        my $value   = shift @input;

        if (Matcher->check($matcher)) {
            return unless $matcher->check($value);
        }
        else {
            return unless match($value, $matcher);
        }
    }
    return @input == 0 && @expected == 0;
}

1;

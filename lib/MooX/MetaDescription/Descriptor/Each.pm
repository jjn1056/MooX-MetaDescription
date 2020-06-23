package MooX::MetaDescription::Descriptor::Each;

use Moo::Role;

with 'MooX::MetaDescription::Descriptor';
requires 'describe_each';

has if => (is=>'ro', predicate=>'has_if');
has unless => (is=>'ro', predicate=>'has_unless');
has on => (is=>'ro', predicate=>'has_on');
has opts => (is=>'ro', required=>1, default=>sub { +{} });
has attributes => (is=>'ro', required=>1);
has model_class => (is=>'ro', required=>1);

# TODO maybe have a 'where' attribute which allows a callback so you can
# stick callback / coderefs all over without needed to invoke the 'with'
# validator.
#
# TODO do we need some sort of loop control, like 'stop_on_first_error' or
# something?  Is possible that notion belongs in Valiant::Validatable

sub options { 
  my $self = shift;
  my %opts = (
    %{$self->opts},
    @_);
  return %opts;
}

sub generate_attributes {
  my ($self, $object, $options) = @_;
  if(ref($self->attributes) eq 'ARRAY') {
    return @{ $self->attributes };
  } elsif(ref($self->attributes) eq 'CODE') {
    return $self->attributes->($object, $options);
  }
}

sub get_descriptions {
  my ($self, $object, $options) = @_;

  # Loop over each attribute and run the validators
  ATTRIBUTE_LOOP: foreach my $attribute ($self->generate_attributes(@_)) {
    if($self->has_if) {
      my @if = (ref($self->if)||'') eq 'ARRAY' ? @{$self->if} : ($self->if);
      foreach my $if (@if) {
        if((ref($if)||'') eq 'CODE') {
          next ATTRIBUTE_LOOP unless $if->($object, $attribute);
        } else {
          if(my $method_cb = $object->can($if)) {
            next ATTRIBUTE_LOOP unless $method_cb->($object, $attribute);
          } else {
            die ref($object) ." has no method '$if'";
          }
        }
      }
    }
    if($self->has_unless) {
      my @unless = (ref($self->unless)||'') eq 'ARRAY' ? @{$self->unless} : ($self->unless);
      foreach my $unless (@unless) {
        if((ref($unless)||'') eq 'CODE') {
          next ATTRIBUTE_LOOP if $unless->($object, $attribute);
        } else {
          if(my $method_cb = $object->can($unless)) {
            next ATTRIBUTE_LOOP if $method_cb->($object, $attribute);
          } else {
            die ref($object) ." has no method '$unless'";
          }
        }
      }
    }

    if($self->has_on) {
      my @on = ref($self->on) ? @{$self->on} : ($self->on);
      my $context = $options->{context}||'';
      my @context = ref($context) ? @$context : ($context);
      my $matches = 0;

      OUTER: foreach my $c (@context) {
        foreach my $o (@on) {
          if($c eq $o) {
            $matches = 1;
            last OUTER;
          }
        }
      }

      next unless $matches;
    }

    $self->describe_each($object, $attribute, $self->options(%{$options||+{}}));
  }
}

sub _cb_value {
  my ($self, $object, $value) = @_;
  if((ref($value)||'') eq 'CODE') {    
    return $value->($object, $self);
  } else {
    return $value;
  } 
}

1;

=head1 TITLE

MooX::MetaDescription::Descriptor::Each - Get descriptions for attributes

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

This validator role provides the following attributes

=head2 if / unless

Accepts a coderef or the name of a method which executes and is expected to
return true or false.  If false we skip the validation (or true for C<unless>).
Recieves the object, the attribute name and the value to be checked as arguments.

You can set more than one value to these with an arrayref:

    if => ['is_admin', sub { ... }, 'active_account'],


When true instead of adding a message to the errors list, will die with the
error instead.  If the true value is the name of a class that provides a C<throw>
message, will use that instead.

=head2 on

A scalar or list of contexts that can be used to control the situation ('context')
under which the validation is executed. If you specify an C<on> context that 
validation will only run if you pass that context via C<validate>.  However if you
don't set a context for the validate (in other words you don't set an C<on> value)
then that validation ALWAYS runs (whether or not you set a context via C<validates>.
Basically not setting a context means validation runs in all contexts and none.

=head1 METHODS

This role provides the following methods.  You may wish to review the source
code of the prebuild validators for examples of usage.

=head2 options

=head2 _cb_value

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Moo>, L<MooseX::MetaDescription>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


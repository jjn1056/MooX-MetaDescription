package MooX::MetaDescription::Descriptor::Callback;

use Moo;
with 'MooX::MetaDescription::Descriptor::Each';

has callback => (is=>'ro', required=>1);

sub describe_each {
  my ($self, $object, $attribute, %opts) = @_;
  my @descriptors = $self->callback->($object, %opts);
  return @descriptors;
}

1;

package MooX::MetaDescription::Descriptor::Instance;

use Moo;
with 'MooX::MetaDescription::Descriptor::Each';

has instance => (is=>'ro', required=>1);

sub describe_each {
  my ($self, $object, $attribute, %opts);
  return $self->instance;
}

1;

package MooX::MetaDescription::Describes;

use Moo::Role;
use Module::Runtime;
use Scalar::Util;

requires 'ancestors';

sub DEBUG_MX_MD { $ENV{MOOX_META_DESCRIPTION_DEBUG} ? 1:0 }

my @_descriptions;
sub _descriptions {
  my ($class, $arg) = @_;
  $class = ref($class) if ref($class);
  my $varname = "${class}::_descriptions";

  no strict "refs";
  push @$varname, $arg if defined($arg);

  # At some point we should have a way to freeze this list, like once
  # the classes are finalized or similar so that we can catch the 
  # results instead of traversing the full ancestors list each time.

  return @$varname,
    map { $_->descriptions } 
    grep { $_->can('descriptions') }
      $class->ancestors;
}

sub get_descriptions {
  my ($self, %opts) = @_;
}

sub read_attribute_for_description {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return my $value = $self->$attribute if $self->can($attribute);
  die "Class '@{[ ref $self ]}' does not have an attribute '$attribute'";
}

sub _reserved_option_keys { return qw/if unless on/ }

sub _is_reserved_option_key {
  my ($class, $key_to_check) = @_;
  return grep {
    $_ eq $key_to_check
  } $class->_reserved_option_keys;
}

sub _find_descriptor_package_in {
  my ($self, $key, @inc) = @_;
  my ($descriptor_package, @rest) = grep {
    eval { Module::Runtime::use_module $_ } || do {
      # This regexp matches too much... We need to add the package
      # path here just the path delim will vary from platform to platform
      if($@=~m/^Can't locate/) {
        warn "Can't find $_ in \@INC\n" if DEBUG_MX_MD;
        0;
      } else {
        die $@;
      }
    }
  } map {
    join '::', ($_, $key)
  } @inc;
  die "'$key' is not a Descriptor" unless $descriptor_package;
  warn "Found $descriptor_package in \@INC\n" if DEBUG_MX_MD;
  return $descriptor_package;
}

sub _create_descriptor {
  my ($self, $descriptor_package, $args) = @_;
  my $descriptor = Module::Runtime::use_module($descriptor_package)->new($args);
  return $descriptor;
}

sub _normalize_package_part {
  my ($class, $package_part) = @_;
  my ($fully_qualified_flag, $package_part) = ($package_part =~/^(+?)(.+)$/);
  return $package_part if $fully_qualified_flag;

  my @inc = $class->_generate_application_descriptor_inc;
  return my $package = $class->_find_descriptor_package_in($package_part, @inc);
}

sub default_descriptor_namepart { 'Descriptor' }

sub default_descriptor_inc {
  return (
    join('::','MooX::MetaDescriptionX', $_[0]->default_descriptor_namepart),
    join('::','MooX::MetaDescription', $_[0]->default_descriptor_namepart),
  );
}

sub _generate_application_descriptor_inc {
  my ($class) = @_;
  my @parts = split '::', $class;
  while(@parts) {
    push @project_inc, join '::', (@parts, $class->default_descriptor_namepart);
    pop @parts;
  }
  push @project_inc, $class->default_descriptor_inc;
  return @project_inc;
}

sub _normalize_attributes {
  my ($class, $attribute_proto) = @_;
  my @attributes = (ref($attribute_proto)||'') eq 'ARRAY' ?
    @$attribute_proto : ($attribute_proto);
  return @attributes;
}

sub describe {
  my ($class, $attribute_proto, @description_proto) = @_;
  my @attributes = $class->_normalize_attributes($attribute_proto);
  my (%global, @descriptors);

  while(@description_proto) {
    my $key = shift(@description_proto);

    # pull out any global options
    if($class->_is_reserved_option_key($key)) {
      # Options are allowed to be a scalar or an arrayref
      my @args = map {
        (ref($_)||'') eq 'ARRAY' ? @$_ : ($_)
      } shift(@description_proto);
      push @{$global{$key}}, @args;
      next; # short circuit any more processing
    }

    # Default arguments
    my $args = +{
      attributes => $attributes,
      model_class => $class,
    };

    # Handle the instance case (ie, "describe MyDescriptor->new")
    if(Scalar::Util::blessed($key)) {
      die "Descriptor '@{[ ref $key ]}' must provide 'get_descriptions' method"
        unless $_->can('get_descriptions');
      $args->{callback} = sub { $key };
      $key = 'MooX::MetaDescription::Descriptor::Callback';
      
      # this bit allows for "describe MyDescriptor->new(%args), +{ on => 'context'}"
      if((ref($description_proto[0])||'') eq 'HASH') {
        my $instance_args = shift(@description_proto);
        $args = +{ %$args, %$instance_args };
      }
    }
    # Ok now we handle the package or package part case (ie "Notes => { ... }")
    else {
      $key = $class->_normalize_package_part($key);
      my $descriptor_args = shift(@description_proto);
      unless((ref($descriptor_args)||'') eq 'HASH') {
        $descriptor_args = $key->normalize_shortcut($descriptor_args);
      }
      $args = +{ %$args, %$descriptor_args };
    }

    my $descriptor = $class->_create_descriptor($key, $args);
    push @descriptors, $descriptor;
  }

  $global{callback} = sub { $_->get_descriptions(@_) for @descriptors };
  
  my $callback = $class->_create_descriptor('MooX::MetaDescription::Descriptor::Callback', \%global);
  return $class->_descriptions($callback);
}

sub description {
  my (@class, @description_proto) = @_;
}

sub described_by {
  my (@class, @description_proto) = @_;
}


1;

=head1 TITLE

MooX::MetaDescription::Describes - Roles that gives a class MetaDescriptions

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 GLOBAL OPTIONS

All descriptions can access the following global options which can be used to
control the processing flow of te descriptions.

=head2 on

A scalar or arrayref of context names for which the description applies. If a
descriptor or description has this option then the matching context must appear
in the options lists when getting descriptions.  If several are defined then only
at least one must match.  If there is no C<on> option then the description will
any or no context.

=head2 if

=head2 unless

This is a reference to a subroutine which receives two arguments, the first being
the object being described and the second is the attribute name (if any).  This
function should return a boolean indicating if the description should be returned
or not.

=head1 METHODS

This role adds the following methods to your result classes.

=head2 get_descriptions

Returns a collection of the descriptions for the current instance or class.

=head2 describe

Add meta descriptions for attributes.  Accepts a scalar value or arrayref of values
which indicate the attributes to be described, followed by a list of descriptors
and optionally a hash of global options.

    describe attribute => (
      Descriptor => \%args;
    );

    describe attribute => (
      MySpecialDescriptor->new(%args)
    );

    describe ['attribute01', 'attribute02'] => (
      Descriptor => \%args;
    );

=head2 description

Add meta descriptions that apply to the class as a whole.  Accepts a list of package
names or part package names (which will resolve to full package names via the documented
namespace expansion rules) optionally each followed by a hashref of initialization options.
Can also accept a blessed descriptor directly as well as global control flow options.

    description 'Descriptor';

    description 'Descriptor' => \%args;

    description MySpecialDescriptor->new(%args);

=head2 described_by

A list of packages or part package names which are external classes that provide description
information.

    described_by 'Notes';

    described_by 'Common', 'Notes';

    described_by Notes => \%args;

    described_by MySpecialDescriptor->new(%args);

    described_by 
      Notes => \%notes_args,
      Common => \%common_args,
      %global_args;

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<MooseX::MetaDescription>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut



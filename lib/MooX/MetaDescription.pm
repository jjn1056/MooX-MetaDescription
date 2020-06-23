package MooX::MetaDescription;

use Moo;

use Sub::Exporter 'build_exporter';
use Class::Method::Modifiers qw(install_modifier);

require Role::Tiny;

sub default_roles { 'MooX::MetaDescription::Ancestors', 'MooX::MetaDescription::Describes' }
sub default_exports { qw(describe description described_by) }

sub import {
  my $class = shift;
  my $target = caller;

  foreach my $default_role ($class->default_roles) {
    Role::Tiny->apply_roles_to_package($target, $default_role)
      unless Role::Tiny::does_role($target, $default_role);
  }

  my %cb = map {
    $_ => $target->can($_);
  } $class->default_exports;
  
  my $exporter = build_exporter({
    into_level => 1,
    exports => [
      map {
        my $key = $_; 
        $key => sub {
          sub { return $cb{$key}->($target, @_) };
        }
      } keys %cb,
    ],
  });

  $class->$exporter($class->default_exports);

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $method = \&{"${target}::describe"};
 
    if(my $validates = delete $opts{describe}) {
      $method->($attr, @$validates);
    }
      
    return $orig->($attr, %opts);
  } if $target->can('has');
} 

1;
1;

=head1 TITLE

MooX::MetaDescription - Moo Meta Descriptions

describere
describo

=head1 SYNOPSIS

    package Example::User;

    use Moo;
    use MooX::MetaDescription;

    has name => (is=>'ro');
    has email => (is=>'ro');
    has address => (is=>'ro');

    describe name => (
      Meta => { notes => 'A user in the system' },
      JSON => { map => 'user-name', omit_if_empty => 1 },
      Validates => {
        type => 'String',
        args => { max => 20, min => 3, validate_if_empty => 0 },
      },
    );

    describe email => (
      Meta => { notes => 'User email' },
      JSON => { map => 'user-email', omit_if_empty => 1 },
      Validates => {
        type => 'String',
        args =>  { max => 96, min => 6, validate_if_empty => 0 }
      },
    );

    describe address => (
      Meta => { notes => 'User Address' },
      JSON => { map => 'user-address', omit_if_empty => 1 },
      Validates => { type => 'Object', args => { validate_if_empty => 0 } },
    );

    description
      Author => { CPANID => 'JJNAPIORK', email => 'jjnapiork@cpan.org' },
      Git => { src => 'https://github.com/jjn1056/Example' };

    1;

    my $address = Example:Address->new(%args);

    my $user = Example::User->new(
      name => 'John Napiorkowski',
      email => 'jjnapiork@cpan.org',
      address => $address);

    my $description_objects_collection  = $address->descriptions_for($attribute);
    my $types_collection = $description_objects_collection->search_for_types('Validates');
    my @string_validations = $type_collection->where({type=>'String'});

=head1 DESCRIPTION

    ::InterfaceMessage
    ::Message Does ::InterfaceMessage
    ::Error Does::InterfaceMessage
    ::Errors Does Collection[::InterfaceMessage]
    
    things to use this for
    - serialization / deserializaition
    - configiration / dependencie injection
    - notes and tagging
    - internationalization / translations
    - validation
    - URL route matching

=head1 METHODS

This component adds the following methods to your result classes.

=head2 

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Moo>, L<MooseX::MetaDescription>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut



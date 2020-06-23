use Test::More;

{
  package Local::Meta::Boilerplate;

  use Moo;

  has 'notes' => (is=>'ro');

  package Local::Descriptor::Notes;

  use Moo;

  with 'MooX::MetaDescription::Descriptor::Each';
  extends 'Local::Meta::Boilerplate';

  sub describe_each {
    my ($self, $object, $attribute, %opts) = @_;
    return $self;
  }

  package Local::User;

  use Moo;
  use MooX::MetaDescription;

  has name => (is=>'ro');
  has email => (is=>'ro');

  describe name => (
    Notes => { notes => 'A user in the system' },
  );

  describe email => (
    Notes => { notes => 'User email' },
  );

  description Meta => { notes => 'Information about a user' };

  described_by '+Local::Meta::Boilerplate' => { notes => 'For Local Application' };
}

ok my $user = Local::User->new(
  name => 'John Napiorkowski',
  email => 'jjnapiork@cpan.org');

use Devel::Dwarn;
Dwarn $user;
Dwarn [$user->get_descriptions];

# $user->get_descriptions(context=>'registration', %opts);
#
# $user->descriptions(%args)->for_descriptor('Notes')->for_attribute('email');
# $user->descriptions->for_class;
# $user->descriptions->descriptors
# $user->descriptions->attributes;
# $user->descriptions->class;
# $user->descriptions->all | count 

done_testing;

__END__

my $errors = $user->descriptions
  ->for_descriptors('Validations')
  ->each(sub {
    my ($descriptors, $validators, $errors) = @_;
    $descriptors->attributes->each(sub {
      my ($attribute, $descriptor, $idx) = @_;
      $validator->get($descriptor->type)
        ->validate($user, $attribute)
        ->errors
        ->each(sub { $users->errors->add($attribute, $_->message) });
    });
    return $errors;
  }, Validators->new(for=>$user), Errors->new);

$errors->descriptions
  ->for_descriptor('I18n')
  ->for_attribute('translation_tags')
  ->each(sub {
    my ($descriptor, $attribute) = @_;
    $i18n->translate($descriptor->tag) # ... something like this
  }



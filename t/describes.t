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
    my ($self, $attribute, %opts) = @_;
    warn $self;
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

# $user->get_descriptions(context=>'registration', %opts);

done_testing;

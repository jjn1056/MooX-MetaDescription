use Test::More;

{
  package Local::User;
  use MooX::MetaDescription;

  has name => (is=>'ro');
  has email => (is=>'ro');
  has address => (is=>'ro');

  describe name => (
    Meta => { notes => 'A user in the system' },
  );

  describe email => (
    Meta => { notes => 'User email' },
  );

  describe email => (
    Meta => { notes => 'User Address' },
  );

  package Local::Address;
  use MooX::MetaDescription;

  has street => (is=>'ro');
  has post_code => (is=>'ro');
  has city => (is=>'ro');
  has state => (is=>'ro');

  describe street => (
    Meta => { notes => 'A street somewhere' },
  );

  describe post_code => (
    Meta => { notes => 'A postal or zipcode' },
  );
  describe city => (
    Meta => { notes => 'A geographical city or town' },
  );

  describe state => (
    Meta => { notes => 'A State in the United States' },
  );
}

ok my $address = Local::Address->new(
  street => '123 Everytown Road',
  post_code => '12312',
  city => 'Everytown',
  state => 'TX');

ok my $user = Local::User->new(
  name => 'John Napiorkowski',
  email => 'jjnapiork@cpan.org',
  address => $address);

use Devel::Dwarn;
Dwarn $user;

done_testing;

package Viroverse::View::JSON2;

use strict;
use base qw(Catalyst::View::JSON);


  use JSON::MaybeXS qw(JSON);

  sub encode_json {
      my($self, $c, $data) = @_;
      my $encoder = JSON->new->ascii->pretty->allow_nonref;
      $encoder->allow_blessed (1);
      $encoder->allow_unknown(1);
      $encoder->convert_blessed(1);
      my $return  = {Response => $data->{jsonify}};
      $encoder->encode($return);
  }




1;

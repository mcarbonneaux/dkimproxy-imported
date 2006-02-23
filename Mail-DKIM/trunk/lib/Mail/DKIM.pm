#!/usr/bin/perl

use strict;
use warnings;

package Mail::DKIM;
our $VERSION = '0.13';

1;
__END__

=head1 NAME

Mail::DKIM - Signs/verifies Internet mail using DKIM message signatures

=head1 SYNOPSIS

  # verify a message
  use Mail::DKIM::Verifier;

  # create a verifier object
  my $dkim = Mail::DKIM::Verifier->new_object();

  # read an email from stdin, pass it into the verifier
  while (<STDIN>)
  {
      # remove local line terminators
      chomp;
      s/\015$//;

      # use SMTP line terminators
      $dkim->PRINT("$_\015\012");
  }
  $dkim->CLOSE;

  # what is the result of the verify?
  my $result = $dkim->result;

=head1 DESCRIPTION

This Perl module is part of the dkimproxy program, located at
http://jason.long.name/dkimproxy/. I've tried to abstract out the DKIM
parts into this module, for use in other programs.

The Mail::DKIM module uses an object-oriented interface. You use one of
two different classes, depending on whether you are signing or verifying
a message. To sign, use the Mail::DKIM::Signer class. To verify, use the
Mail::DKIM::Verifier class. Simple, eh?

=head1 SEE ALSO

Mail::DKIM::Signer

Mail::DKIM::Verifier

http://jason.long.name/dkimproxy/

=head1 KNOWN BUGS

The DKIM standard is still in development, so by the time you read this,
this module may already be broken with regards to the latest DKIM
specification.

One feature that has not been implemented yet is the "sender signing policy".
I.e. this library will tell you whether the signature is valid, but will
not lookup the signing policy for the author of the message.

This library uses two different crypto libraries: Crypt::OpenSSL::RSA and
Crypt::RSA. This redundancy is undesirable, but so far I have not figured
out how to load base64-encoded key data using Crypt::RSA, and I have not
figured out to sign/verify an already-computed message digest using
Crypt::OpenSSL::RSA.

=head1 AUTHOR

Jason Long, E<lt>jlong@messiah.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Messiah College

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

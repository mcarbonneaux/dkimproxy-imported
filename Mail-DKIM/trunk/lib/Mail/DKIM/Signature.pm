#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

use Mail::DKIM::PublicKey;

package Mail::DKIM::Signature;
use base "Mail::DKIM::KeyValueList";
use Carp;

=head1 NAME

Mail::DKIM::Signature - encapsulates a DKIM signature header

=head1 CONSTRUCTORS

=head2 new() - create a new signature from parameters

  my $signature = new Mail::DKIM::Signature(
                      [ Algorithm => "rsa-sha1", ]
                      [ Signature => $base64, ]
                      [ Method => "nowsp", ]
                      [ Domain => "example.org", ]
                      [ Headers => "from:subject:date:message-id", ]
                      [ Query => "dns", ]
                      [ Selector => "alpha", ]
                  );

=cut

sub new {
	my $type = shift;
	my %prms = @_;
	my $self = {};
	bless $self, $type;

	$self->algorithm($prms{'Algorithm'} || "rsa-sha1");
	$self->signature($prms{'Signature'});
	$self->method($prms{'Method'} || "simple");
	$self->domain($prms{'Domain'});
	$self->headerlist($prms{'Headers'});
	$self->protocol($prms{'Query'} || "dns");
	$self->selector($prms{'Selector'});

	return $self;
}

=head2 parse() - create a new signature from a DKIM-Signature header

  my $sig = parse Mail::DKIM::Signature(
                  "DKIM-Signature: a=rsa-sha1; b=yluiJ7+0=; c=nowsp"
            );

Constructs a signature by parsing the provided DKIM-Signature header
content. You do not have to include the header name (i.e. "DKIM-Signature:")
but it is recommended, so the header name can be preserved and returned
the same way in as_string().

Note: The input to this constructor is in the same format as the output
of the as_string method.

=cut

sub parse
{
	my $class = shift;
	croak "wrong number of arguments" unless (@_ == 1);
	my ($string) = @_;

	# remove line terminator, if present
	$string =~ s/\015\012\z//;

	# remove field name, if present
	my $prefix;
	if ($string =~ /^(dkim-signature:)(.*)/si)
	{
		# save the field name (capitalization), so that it can be
		# restored later
		$prefix = $1;
		$string = $2;
	}

	my $self = $class->SUPER::parse($string);
	$self->{prefix} = $prefix;

	if (defined $self->get_tag("v"))
	{
		die "detected forbidden v= tag\n";
	}

	return $self;
}


=head1 METHODS

=cut

# deprecated
sub wantheader {
	my $self = shift;
	my $attr = shift;

	$self->headerlist or
		return 1;
	
	foreach my $key ($self->headerlist) {
		lc $attr eq lc $key and
			return 1;
	}

	return;
}

=head2 algorithm() - get or set the algorithm (a=) field

The algorithm used to generate the signature. Should be either "rsa-sha1",
an RSA-signed SHA-1 digest, or "rsa-sha256", an RSA-signed SHA-256 digest.

See also hash_algorithm().

=cut

sub algorithm
{
	my $self = shift;

	if (@_)
	{
		$self->set_tag("a", shift);
	}

	return lc $self->get_tag("a");
}	

=head2 as_string() - the signature header as a string

  print $signature->as_string . "\n";

outputs

  DKIM-Signature: a=rsa-sha1; b=yluiJ7+0=; c=nowsp

As shown in the example, the as_string method can be used to generate
the DKIM-Signature that gets prepended to a signed message.

=cut

sub as_string
{
	my $self = shift;

	my $prefix = $self->{prefix} || "DKIM-Signature:";

	return $prefix . $self->SUPER::as_string;
}

# undocumented method
sub as_string_debug
{
	my $self = shift;

	my $prefix = $self->{prefix} || "DKIM-Signature:";

	return $prefix . join(";", map { ">" . $_->{raw} . "<" } @{$self->{tags}});
}

=head2 as_string_without_data() - signature without the signature data

  print $signature->as_string_without_data . "\n";

outputs

  DKIM-Signature: a=rsa-sha1; b=; c=nowsp

This is similar to the as_string() method, but it always excludes the "data"
part. This is used by the DKIM canonicalization methods, which require
incorporating this part of the signature into the signed message.

=cut

sub as_string_without_data
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);

	my $alt = $self->clone;
	$alt->signature("");

	return $alt->as_string;
}

=head2 body_count() - get or set the body count (l=) field

  my $i = $signature->body_count;

Informs the verifier of the number of bytes in the body of the email
included in the cryptographic hash, starting from 0 immediately
following the CRLF preceding the body. Also known as the l= tag.

When creating a signature, this tag may be either omitted, or set after
the selected canonicalization system has received the entire message
body (but before it canonicalizes the DKIM-Signature).

=cut

sub body_count
{
	my $self = shift;

	# set new body count if provided
	(@_) and
		$self->set_tag("l", shift);

	return $self->get_tag("l");
}

=head2 body_hash() - get or set the body hash (bh=) field

  my $bh = $signature->body_hash;

The hash of the body part of the message. Whitespace is ignored in this
value. This tag is required.

When accessing this value, whitespace is stripped from the tag for you.

=cut

sub body_hash
{
	my $self = shift;

	# set new body hash if provided
	(@_) and
		$self->set_tag("bh", shift);

	my $result = $self->get_tag("bh");
	if (defined $result)
	{
		$result =~ s/\s+//gs;
	}
	return $result;
}

=head2 canonicalization() - get or set the canonicalization (c=) field

  $signature->canonicalization("relaxed", "simple");

  ($header, $body) = $signature->canonicalization;

Message canonicalization (default is "simple/simple"). This informs the
verifier of the type of canonicalization used to prepare the message for
signing.

In scalar context, this returns header/body canonicalization as a single
string separated by /. In list context, it returns a two element array,
containing first the header canonicalization, then the body.

=cut

sub canonicalization
{
	my $self = shift;

	if (@_)
	{
		$self->set_tag("c", join("/", @_));
	}

	my $c = lc $self->get_tag("c");
	if (not $c)
	{
		$c = "simple/simple";
	}
	my ($c1, $c2) = split(/\//, $c, 2);
	if (not defined $c2)
	{
		# default body canonicalization depends on header canonicalization
		$c2 = $c1 eq "nowsp" ? "nowsp" : "simple";
	}

	if (wantarray)
	{
		return ($c1, $c2);
	}
	else
	{
		return "$c1/$c2";
	}
}	

=head2 domain() - get or set the domain (d=) field

  my $d = $signature->domain;          # gets the domain value
  $signature->domain("example.org");   # sets the domain value

The domain of the signing entity, as specified in the signature.
This is the domain that will be queried for the public key.

=cut

sub domain
{
	my $self = shift;

	if (@_)
	{
		$self->set_tag("d", shift);
	}

	return lc $self->get_tag("d");
}	

=head2 expiration() - get or set the signature expiration (x=) field

Signature expiration (default is undef, meaning no expiration).
The signature expiration, if defined, is an unsigned integer identifying
the standard Unix seconds-since-1970 time when the signature will
expire.

=cut

sub expiration
{
	my $self = shift;

	(@_) and
		$self->set_tag("x", shift);
	
	return $self->get_tag("x");
}

use MIME::Base64;

sub check_canonicalization
{
	my $self = shift;

	my ($c1, $c2) = $self->canonicalization;

	my @known = ("nowsp", "simple", "relaxed");
	return undef unless (grep { $_ eq $c1 } @known);
	return undef unless (grep { $_ eq $c2 } @known);
	return 1;
}

sub check_protocol
{
	my $self = shift;

	my ($type, $options) = split(/\//, $self->protocol, 2);
	return ($type eq "dns");
}

sub get_public_key
{
	my $self = shift;

	unless ($self->{public})
	{
		my $pubk = Mail::DKIM::PublicKey->fetch(
			Protocol => $self->protocol,
			Selector => $self->selector,
			Domain => $self->domain);
		unless ($pubk)
		{
			#$self->status("no key"),
			#$self->errorstr("no public key available"),
			die "no public key available\n";
		}

		if ($pubk->revoked)
		{
			#$self->status("revoked"),
			#$self->errorstr("public key has been revoked"),
			die "public key has been revoked\n";
		}

		$self->{public} = $pubk;
	}
	return $self->{public};
}

=head2 hash_algorithm() - access the hash algorithm specified in this signature

  my $hash = $signature->hash_algorithm;

Determines what hashing algorithm is used as part of the signature's
specified algorithm.

For algorithm "rsa-sha1", the hash algorithm is "sha1". Likewise, for
algorithm "rsa-sha256", the hash algorithm is "sha256". If the algorithm
is not recognized, undef is returned.

=cut

sub hash_algorithm
{
	my $self = shift;
	my $algorithm = $self->algorithm;

	return $algorithm eq "rsa-sha1" ? "sha1" :
		$algorithm eq "rsa-sha256" ? "sha256" : undef;
}

=head2 headerlist() - get or set the signed header fields (h=) field

Signed header fields. A colon-separated list of header field names
that identify the header fields presented to the signing algorithm.

=cut

sub headerlist
{
	my $self = shift;

	(@_) and
		$self->set_tag("h", shift);

	my $h = $self->get_tag("h") || "";

	# remove whitespace next to colons
	$h =~ s/\s+:/:/g;
	$h =~ s/:\s+/:/g;
	$h = lc $h;

	if (wantarray and $h)
	{
		my @list = split /:/, $h;
		@list = map { s/^\s+|\s+$//g; $_ } @list;
		return @list;
	}

	return $h;
}	

=head2 identity() - get or set the signing identity (i=) field

  my $i = $signature->identity;

Identity of the user or agent on behalf of which this message is signed.
The identity has an optional local part, followed by "@", then a domain
name. The domain name should be the same as or a subdomain of the
domain returned by the C<domain> method.

Ideally, the identity should match the identity listed in the From:
header, or the Sender: header, but this is not required to have a
valid signature. Whether the identity used is "authorized" to sign
for the given message is not determined here.

=cut

sub identity
{
	my $self = shift;

	# set new identity if provided
	(@_) and
		$self->set_tag("i", shift);

	my $i = $self->get_tag("i");
	if (defined $i)
	{
		return $i;
	}
	else
	{
		return '@' . $self->domain;
	}
}

=head2 method() - get or set the canonicalization (c=) field

Message canonicalization (default is "simple"). This informs the verifier
of the type of canonicalization used to prepare the message for signing.

=cut

sub method
{
	my $self = shift;

	if (@_)
	{
		$self->set_tag("c", shift);
	}

	return lc $self->get_tag("c");
}	

=head2 protocol() - get or set the query methods (q=) field

A colon-separated list of query methods used to retrieve the public
key (default is "dns"). Each query method is of the form "type[/options]",
where the syntax and semantics of the options depends on the type.

=cut

sub protocol {
	my $self = shift;

	(@_) and
		$self->set_tag("q", shift);

	my $q = $self->get_tag("q");
	if (not defined $q)
	{
		return "dns/";
	}
	elsif ($q =~ m#/#)
	{
		return $q;
	}
	else
	{
		return "$q/";
	}
}	

=head2 selector() - get or set the selector (s=) field

The selector subdivides the namespace for the "d=" (domain) tag.

=cut

sub selector {
	my $self = shift;

	(@_) and
		$self->set_tag("s", shift);

	return $self->get_tag("s");
}	

=head2 signature() - get or set the signature data (b=) field

The signature data. Whitespace is automatically stripped from the
returned value.

=cut

sub signature
{
	my $self = shift;

	if (@_)
	{
		$self->set_tag("b", shift);
	}

	my $b = $self->get_tag("b");
	if (defined $b)
	{
		$b =~ s/\s+//g;
	}
	return $b;
}	

=head2 timestamp() - get or set the signature timestamp (t=) field

Signature timestamp (default is undef, meaning unknown creation time).
This is the time that the signature was created. The value is an unsigned
integer identifying the number of standard Unix seconds-since-1970.

=cut

sub timestamp
{
	my $self = shift;

	(@_) and
		$self->set_tag("t", shift);
	
	return $self->get_tag("t");
}

1;
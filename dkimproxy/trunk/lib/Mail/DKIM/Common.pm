#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

use Mail::DKIM::Algorithm::rsa_sha1;
use Mail::DKIM::Signature;

package Mail::DKIM::Common;
use base "Mail::DKIM::MessageParser";
use Carp;
our $VERSION = "0.12";

sub new
{
	my $class = shift;
	return $class->new_object(@_);
}

sub get_algorithm_class
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 1);
	my ($algorithm) = @_;

	my $class = $algorithm eq "rsa-sha1" ? "Mail::DKIM::Algorithm::rsa_sha1" :
		die "unknown algorithm $algorithm\n";
	return $class;
}

sub add_header
{
	my $self = shift;
	my ($line) = @_;

	if ($line =~ /^([^:]+)\s*:(.*)/s)
	{
		my $field_name = lc $1;
		my $contents = $2;
		$self->handle_header($field_name, $contents, $line);
	}
	push @{$self->{headers}}, $line;
}

sub add_body
{
	my $self = shift;
	if ($self->{algorithm})
	{
		$self->{algorithm}->add_body(@_);
	}
}

sub handle_header
{
	my $self = shift;
	my ($field_name, $contents, $line) = @_;

	push @{$self->{header_field_names}}, $field_name;

	# TODO - detect multiple occurrences of From: or Sender:
	# header and reject them

	$self->{headers_by_name}->{$field_name} = $contents;
}

sub load
{
	my $self = shift;
	my ($fh) = @_;

	while (<$fh>)
	{
		$self->PRINT($_);
	}
	$self->CLOSE;
}

sub message_attributes
{
	my $self = shift;
	my @attributes;

	if (my $message_id = $self->message_id)
	{
		push @attributes, "message-id=<$message_id>";
	}

	if (my $sig = $self->signature)
	{
		push @attributes, "signer=<" . $sig->identity . ">";
	}

	if ($self->{headers_by_name}->{sender})
	{
		my @list = parse Mail::Address($self->{headers_by_name}->{sender});
		if ($list[0])
		{
			push @attributes, "sender=<" . $list[0]->address . ">";
		}
	}
	elsif ($self->{headers_by_name}->{from})
	{
		my @list = parse Mail::Address($self->{headers_by_name}->{from});
		if ($list[0])
		{
			push @attributes, "from=<" . $list[0]->address . ">";
		}
	}

	return @attributes;
}

sub message_id
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);

	if (my $message_id = $self->{headers_by_name}->{"message-id"})
	{
		if ($message_id =~ /^\s*<(.*)>\s*$/)
		{
			return $1;
		}
	}
	return undef;
}

sub message_originator
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);

	if ($self->{headers_by_name}->{from})
	{
		my @list = parse Mail::Address($self->{headers_by_name}->{from});
		return $list[0];
	}
	return undef;
}

sub message_sender
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);

	if ($self->{headers_by_name}->{sender})
	{
		my @list = parse Mail::Address($self->{headers_by_name}->{sender});
		return $list[0];
	}
	if ($self->{headers_by_name}->{from})
	{
		my @list = parse Mail::Address($self->{headers_by_name}->{from});
		return $list[0];
	}
	return undef;
}

sub result
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);
	return $self->{result};
}

sub result_detail
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);

	if ($self->{details})
	{
		return $self->{result} . " (" . $self->{details} . ")";
	}
	return $self->{result};
}

sub signature
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 0);
	return $self->{signature};
}


1;
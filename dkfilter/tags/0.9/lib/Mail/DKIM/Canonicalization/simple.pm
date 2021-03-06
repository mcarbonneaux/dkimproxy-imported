#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::Canonicalization::simple;
use base "Mail::DKIM::Canonicalization::DkimCommon";
use Carp;

sub init
{
	my $self = shift;
	$self->SUPER::init;

	$self->{canonicalize_body_buf} = "";
}

sub canonicalize_header
{
	my $self = shift;
	croak "wrong number of parameters" unless (@_ == 1);
	my ($line) = @_;

	#
	# draft-allman-dkim-base-01.txt, section 3.4.1:
	#   the "simple" header field canonicalization algorithm does not
	#   change the header field in any way
	#

	return $line;
}

sub canonicalize_body
{
	my $self = shift;
	my ($line) = @_;

	#
	# draft-allman-dkim-base-01.txt, section 3.4.3:
	#   the "simple" body canonicalization algorithm ignores all
	#   empty lines at the end of the message body
	#

	#
	# (i.e. do not emit empty lines until a following nonempty line
	# is found)
	#
	if ($line eq "\015\012")
	{
		$self->{canonicalize_body_buf} .= $line;
		$line = "";
	}
	else
	{
		$line = $self->{canonicalize_body_buf} . $line;
		$self->{canonicalize_body_buf} = "";
	}

	return $line;
}

1;

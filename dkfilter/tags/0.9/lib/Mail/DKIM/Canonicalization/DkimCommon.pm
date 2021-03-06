#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::Canonicalization::DkimCommon;
use base "Mail::DKIM::Canonicalization::Base";
use Carp;

sub init
{
	my $self = shift;
	$self->SUPER::init;

	# these canonicalization methods require signature to use
	$self->{Signature}
		or croak "no signature specified";
}

sub add_header
{
	my $self = shift;
	my ($line) = @_;

	croak "header parse error \"$line\"" unless ($line =~ /:/);

	$line =~ s/\015\012\z//s;
	push @{$self->{myheaders}},
		$self->canonicalize_header($line) . "\015\012";
}

sub finish_header
{
	my $self = shift;

	# Headers are canonicalized in the order specified by the h= tag.
	# However, in the case of multiple instances of the same header name,
	# the headers will be canonicalized in reverse order (i.e. "from
	# the bottom of the header field block to the top").
	#
	# This is described in 5.4 of draft-allman-dkim-base-01.

	# Since the bottom-most headers are to get precedence, we reverse
	# the headers here... (now the first header matching a particular
	# name is the header to insert)
	my @mess_headers = reverse @{$self->{myheaders}};

	# presence of a h= tag is mandatory...
	unless (defined $self->{Signature}->{HDRS})
	{
		die "Error: h= tag is required for this canonicalization\n";
	}

	# iterate through the header field names specified in the signature
	my @sig_headers = $self->{Signature}->headerlist;
	foreach my $hdr_name (@sig_headers)
	{
		$hdr_name = lc $hdr_name;

		# find the specified header in the message
		inner_loop:
		for (my $i = 0; $i < @mess_headers; $i++)
		{
			my $hdr = $mess_headers[$i];

			if ($hdr =~ /^([^\s:]+)\s*:/)
			{
				my $key = lc $1;
				if ($key eq $hdr_name)
				{
					# found it

					# remove it from our list, so if it occurs more than
					# once, we'll get the next header in line
					splice @mess_headers, $i, 1;

					$self->output($hdr);
					last inner_loop;
				}
			}
		}
	}

	$self->output("\015\012");
}

sub add_body
{
	my $self = shift;
	my ($line) = @_;
	$self->output($self->canonicalize_body($line));
}

sub finish_body
{
	my $self = shift;

	if ($self->{Signature})
	{
		# append the DKIM-Signature (without data)
		my $line = "DKIM-Signature: "
			. $self->{Signature}->as_string_without_data;
		#$self->output("\015\012");

		# signature is subject to same canonicalization as headers
		$self->output($self->canonicalize_header($line));
	}
}

1;

__END__

=head1 NAME

Mail::DKIM::Canonicalization::DkimCommon - common canonicalization methods

=head1 DESCRIPTION

This class implements functionality that is common to all the
currently-defined DKIM canonicalization methods, but not necessarily
common with future canonicalization methods.

For functionality that is common to all canonicalization methods
(including future methods), see Mail::DKIM::Canonicalization::Base.

=head1 SEE ALSO

Mail::DKIM::Canonicalization::Base

=cut

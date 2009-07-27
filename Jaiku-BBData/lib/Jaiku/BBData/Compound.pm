# Copyright (c) 2007-2009 Google Inc.
# Copyright (c) 2006-2007 Jaiku Ltd.
# Copyright (c) 2002-2006 Mika Raento and Renaud Petit
#
# This software is licensed at your choice under either 1 or 2 below.
#
# 1. Perl (Artistic) License
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# 2. Gnu General Public license 2.0
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#
# This file is part of the JaikuEngine mobile frontend.
package Jaiku::BBData::Compound;

use base qw(Jaiku::BBData);
use Jaiku::BBData::Factory;

sub _from_xml {
  my $self=shift;
  my $xml_to_field=$self->xml_to_field;

  my @c=@{$self->{children}};
  $self->{children}=[];

  foreach my $c (@c) {
    next unless (defined($c));
    if (!(ref $c)) {
      # ignore intra-element whitespace
      next if ($c =~ /\s*/);
    }
    die "non-element child $c in compound " . $self->element()
      unless(ref $c);

    if (ref $c) {
      my ($ns, $name)=$c->element;
      if ( $ns eq "" || $ns eq "http://www.cs.helsinki.fi/group/context") {
        $name = $xml_to_field->{$name};
        if ($name) {
          my $method="set_$name";
          $self->$method($c);
          $c=undef;
        }
      }
    }

    $self->push_child($c) if ($c);
  }
}

sub as_parsed {
  my $self=shift;
  my $parsed={};
  my $field_to_xml=$self->field_to_xml;
  foreach my $k (keys %$field_to_xml) {
    next unless ($self->{$k});
    my $xmlname=$field_to_xml->{$k};
    $parsed->{$xmlname}=$self->{$k}->as_parsed;
  }
  return $parsed;
}

sub from_parsed {
  my ($self, $hashref) = @_;
  my $xml_to_field=$self->xml_to_field;
  foreach my $k (keys %$hashref) {
    eval {
      my $name = $xml_to_field->{$k};
      if (!$name) {
        die "No field mapping for $k";
      }
      $self->$name()->from_parsed($hashref->{$k});
    };
    if ($@) {
      if (Jaiku::BBData::release_mode()) {
        print STDERR "failed to parse some BBData: $@";
      } else {
        die $@;
      }
    }
  }
}

1;

# $Id: Orphea.pm,v 1.15 2006/08/22 13:00:51 rousse Exp $
package WWW::Orphea;

=head1 NAME

WWW::Orphea - Orphea Agent

=head1 VERSION

Version 0.3.3

=head1 DESCRIPTION

This module may be used search images on an Orphea web server, a Digital Asset
Management (DAM) software suite published by Algoba Systems
(http://www.algoba.com/public/orphea.pgi). Its interface is adapted from
L<WWW::Google::Images>, itself inspired from L<WWW::Google::Groups>.

=head1 SYNOPSIS

    use WWW::Orphea;

    $agent = WWW::Orphea->new(
        server => 'my.orphea.server',
        proxy  => 'my.proxy.server:port',
    );

    $result = $agent->search('flowers', limit => 10);

    while ($image = $result->next()) {
        $count++;
        print $image->content_url();
        print $image->legend();
        print $image->save_content( base => 'image' . $count);
    }

=cut

use WWW::Mechanize;
use WWW::Orphea::SearchResult;
use strict;
our $VERSION = '0.3.3';

=head1 Constructor

=head2 new(I<%args>)

Creates and returns a new C<WWW::Google::Images> object.

Optional parameters:

=over

=item server => I<$server>

use I<$server> as server.

=item proxy => I<$proxy>:I<$port>

use I<$proxy> as proxy on port I<$port>.

=back

=cut

sub new {
    my ($class, %arg) = @_;

    foreach my $key (qw(server pass user)) {
        die "No $key defined, aborting" unless $arg{$key};
    }

    foreach my $key (qw(server proxy)) {
        next unless $arg{$key};
        $arg{$key} = 'http://' . $arg{$key} unless $arg{$key} =~ m|^\w+?://|;
        $arg{$key} = $arg{$key} . '/' unless $arg{$key} =~ m|/$|;
    }

    my $a = WWW::Mechanize->new(onwarn => undef, onerror => undef);
    $a->proxy(['http'], $arg{proxy}) if $arg{proxy};

    my $self = bless {
        _user   => $arg{user},
        _pass   => $arg{pass},
        _server => $arg{server},
        _proxy  => $arg{proxy},
        _agent  => $a,
    }, $class;

    $self->{_agent}->get($self->{_server});

    $self->{_agent}->submit_form(
        form_number => 1,
        fields      => {
            UserName => $self->{_user},
            PassWord => $self->{_pass},
        }
    );

    $self->{_agent}->content() =~ /src="loading_header.html\?UNID=(\w+)&LGID=(\w+)&([^"]+)"/;
    my $unid   = $1;
    my $lang   = $2;
    my $remain = $3;
    $self->{_agent}->get($self->{_server} . "header.html?UNID=$unid&LGID=$lang&$remain");

    my $content = $self->{_agent}->content();
    $content =~ s/document.write\('//g;
    $content =~	s/'\);//g;
    $content =~	s/\\'/'/g;
    $content =~	s/'\+lvLangue\+'/$lang/g;
    $content =~ s/'\+lvUNID\+'/$unid/g;
    $content =~ s/<!-- ORPHEA CODE INSERTED  -->/<\/script>/;
    $self->{_form} = HTML::Form->parse($content, $self->{_agent}->uri());

    return $self;
}

=head2 $agent->search(I<$query>, I<%args>);

Perform a search for I<$query>, and return a C<WWW::Google::Images::SearchResult> object.

Optional parameters:

=over

=item limit => I<$limit>

limit the maximum number of result returned to $limit.

=back

=cut

sub search {
    my ($self, $query, %arg) = @_;

    warn "No query given, aborting" and return unless $query;

    $arg{limit} = 10 unless defined $arg{limit};

    $self->{_form}->value('userrequest', $query);
    $self->{_agent}->request($self->{_form}->click());
    $self->{_agent}->submit();

    my @images;
    my $page = 1;

    LOOP: {
        do {
            push(@images, $self->_extract_images($arg{limit} ? $arg{limit} - @images : 0));
            last if $arg{limit} && @images >= $arg{limit};
        } while ($self->_next_page(++$page));
    }

    return WWW::Orphea::SearchResult->new($self->{_agent}, @images);
}

sub _next_page {
    my ($self, $page) = @_;

    my $link = $self->{_agent}->find_link(url_regex => qr/javascript:fOpenURL/, text_regex => qr/$page/);
    return unless $link;
    my $url = $link->url();
    $url =~ s/javascript:fOpenURL\('//;
    $url =~ s/'\)//;
    return $self->{_agent}->get($self->{_server} . $url);
}

sub _extract_images {
    my ($self, $limit) = @_;

    my @images;
    my $page = $self->{_agent}->content();
    my @legends  = $page =~ m/<TD class="photoslistsubline1">([^<]+)<\/TD>/go;
    my @contents = $page =~ m/<img src="thu_orphea\/([\d_]+)\.(?:thw|THW)"/go;

    for (my $i = 0; $i <= $#contents; $i++) {
        last if $limit && @images >= $limit;
        $contents[$i] = $self->{_server} . 'bro_orphea/' . $contents[$i] . '.BRO';
        $legends[$i]  =~ s/\w+$//;
        push(@images, { content => $contents[$i], legend => $legends[$i] });
    }

    return @images;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 INRIA.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Guillaume Rousse <grousse@cpan.org>

=cut

1;

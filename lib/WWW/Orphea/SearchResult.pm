# $Id: SearchResult.pm,v 1.2 2004/04/05 13:57:31 guillaume Exp $
package WWW::Orphea::SearchResult;

=head1 NAME

WWW::Google::Orphea::SearchResult - Search result object for WWW::Orphea

=cut

use WWW::Orphea::Image;
use strict;

=head1 Constructor

=head2 new(I<$agent>, I<@urls>)

Creates and returns a new C<WWW::Google::Orphea::SearchResult> object.

=cut

sub new {
    my ($class, $agent, @images) = @_;

    my $self = bless {
	_agent  => $agent,
	_images => \@images
    }, $class;

    return $self;
}

=head1 Accessor

=head2 $result->next()

Returns the next image from result as a C<WWW::Orphea::Image> object.

=cut

sub next {
    my ($self) = @_;
    my $image = shift @{$self->{_images}};
    return unless $image;
    return WWW::Orphea::Image->new(
	$self->{_agent},
	$image->{content},
	$image->{legend}
    );
}

=head1 Other methods

=head2 $result->save_all_contents(I<%args>)

Save all the image files from result, by calling $image->save_content(I<%args>)
for each one. If optional parameter file or base is given, an index number is
automatically appended.

=cut

sub save_all_contents {
    my ($self, %args) = @_;

    my $count;
    while (my $image = $self->next()) {
	$count++;
	$image->save_content(
	    dir  => $args{dir} ? $args{dir} : undef,
	    file => $args{file} ? $args{file} . $count : undef,
	    base => $args{base} ? $args{base} . $count : undef,
	);
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, INRIA.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Guillaume Rousse <grousse@cpan.org>

=cut

1;

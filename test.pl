#!/usr/bin/perl
# $Id: test.pl,v 1.3 2004/04/05 13:59:50 guillaume Exp $
use Test::More tests => 15;
use Test::URI;
use File::Temp qw/tempdir/;
use strict;

my $query = 'Musa';

BEGIN {
    use_ok 'WWW::Orphea';
}

# skip all other tests if the network is not available
SKIP: {
    skip "Web does not seem to work", 14 unless web_ok();

    my $agent = WWW::Orphea->new(
	server => 'http://www.ird.fr/indigo',
	user   => '__GUEST',
	pass   => '__GUEST'
    );
    isa_ok($agent, 'WWW::Orphea', 'constructor returns a WWW::Orphea object');

    my $result = $agent->search($query, limit => 1);
    isa_ok($result, 'WWW::Orphea::SearchResult', 'search returns a WWW::Orphea::SearchResult object');

    my $image = $result->next();
    isa_ok($image, 'WWW::Orphea::Image', 'iteration returns a WWW::Orphea::Image object');

    my $content_url = $image->content_url();
    ok($content_url, "content URL exist");
    uri_scheme_ok($content_url, 'http');
    like($content_url, qr/\.bro$/i, 'content URL is an image file URL');

    my $context_url = $image->legend();
    ok($context_url, "legend exist");

    my $dir = tempdir( CLEANUP => 1 );

    my $content_file;
    $content_file = $image->save_content(dir => $dir, file => 'content');
    ok(-f $content_file, 'content file is saved correctly with imposed file name');
    $content_file = $image->save_content(dir => $dir, base => 'content');
    ok(-f $content_file, 'content file is saved correctly with imposed base name');
    $content_file = $image->save_content(dir => $dir);
    ok(-f $content_file, 'content file is saved correctly with original name');

    $image = $result->next();
    ok(! defined $image, 'search limit < 20 works');
    print $image;

    my $count;

    $count = 0;
    $result = $agent->search($query);
    while ($image = $result->next()) { $count++ }; 
    is($count, 10, 'default search limit');

    $count = 0;
    $result = $agent->search($query, limit => 37);
    while ($image = $result->next()) { $count++ }; 
    is($count, 37, 'search limit > 20 works');

    $count = 0;
    $result = $agent->search($query, limit => 0);
    while ($image = $result->next()) { $count++ }; 
    is($count, get_max_result_count(), 'no search limit');
}

sub get_max_result_count {
    my $test_agent = WWW::Mechanize->new();

    $test_agent->get('http://www.ird.fr/indigo');
    $test_agent->submit_form(
	 form_number => 1,
	 fields      => {
	     UserName => '__GUEST',
	     PassWord => '__GUEST'
	 }
    );

    my $content;
    $content = $test_agent->content();
    $content =~ /src="loading_header.html\?UNID=(\w+)&LGID=(\w+)&([^"]+)"/;
    my $unid   = $1;
    my $lang   = $2;
    my $remain = $3;
    $test_agent->get("http://www.ird.fr/indigo/header.html?UNID=$unid&LGID=$lang&$remain");

    $content = $test_agent->content();
    $content =~ s/document.write\('//g;
    $content =~	s/'\);//g;
    $content =~	s/\\'/'/g;
    $content =~	s/'\+lvLangue\+'/$lang/g;
    $content =~ s/'\+lvUNID\+'/$unid/g;
    $content =~ s/<!-- ORPHEA CODE INSERTED  -->/<\/script>/;
    my $form = HTML::Form->parse($content, $test_agent->uri());

    $form->value('userrequest', $query);
    $test_agent->request($form->click());

    $test_agent->content() =~ m/ramène (\d+) photos/;
    return $1;
}

# shamelessly stolen from HTTP-Proxy test suite
sub web_ok {
    my $ua = LWP::UserAgent->new( env_proxy => 1, timeout => 30 );
    my $res = $ua->request(
        HTTP::Request->new( GET => shift||'http://www.google.com/intl/en/' ) );
    return $res->is_success;
}

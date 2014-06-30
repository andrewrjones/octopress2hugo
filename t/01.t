#!perl

use strict;
use warnings;
use 5.010;

use Test::More;

use octopress2hugo;

my $o = octopress2hugo->new();

is($o->process_line('---'), '---', 'leave frontmatter');
is($o->process_line('---'), '---', 'leave frontmatter');
is($o->process_line('---'), undef, 'remove HR');

is($o->process_line('layout: post'), undef, 'remove "layout: post"');

is($o->process_line('comments: true'), undef, 'remove "comments: true"');
is($o->process_line('comments: false'), undef, 'remove "comments: false"');

is($o->process_line('date: 2014-03-22 16:15'), 'date: 2014-03-22T16:15:00+00:00', 'date formatting');

is($o->process_line('title: bar &amp; foo'), 'title: bar & foo', '&amp; in title');

is($o->process_line('categories: Foo'), "categories:\n- Foo", 'replace single line categories');

is($o->process_line('external-url: http://hugo.spf13.com/'), "linked: http://hugo.spf13.com/", 'replace single line categories');

is($o->process_line('{% img center img-polaroid /images/posts/squirrel-sql-jira.png %}'), '{{% figure src="/images/posts/squirrel-sql-jira.png" %}}', 'image to figure');

is($o->process_line('<img src="https://farm3.staticflickr.com/2859/13249455284_48174052f7.jpg" width="375" height="500" alt="The Sea-wolf" style="display: block;margin:0 auto; padding: 5px">'),
	'{{% figure src="https://farm3.staticflickr.com/2859/13249455284_48174052f7.jpg" alt="The Sea-wolf" %}}',
	'HTML img to figure');
is($o->process_line('<a href="https://www.flickr.com/photos/quiteadept/13249455284"><img src="https://farm3.staticflickr.com/2859/13249455284_48174052f7.jpg" width="375" height="500" alt="The Sea-wolf" style="display: block;margin:0 auto; padding: 5px"></a>'),
	'{{% figure src="https://farm3.staticflickr.com/2859/13249455284_48174052f7.jpg" link="https://www.flickr.com/photos/quiteadept/13249455284" alt="The Sea-wolf" %}}',
	'HTML img and link to figure');

is($o->process_line('{% blockquote @toughplacetogo https://twitter.com/toughplacetogo/status/441876375717556224 %}'),
	'{{% blockquote author="@toughplacetogo" source="https://twitter.com/toughplacetogo/status/441876375717556224" %}}',
	'blockquote full cite');
is($o->process_line('{% blockquote David Heinemeier Hansson http://37signals.com/svn/posts/3159-testing-like-the-tsa Testing like the TSA %}'),
	'{{% blockquote author="David Heinemeier Hansson" source="http://37signals.com/svn/posts/3159-testing-like-the-tsa" title="Testing like the TSA" %}}',
	'blockquote full cite with title');
is($o->process_line('{% endblockquote %}'), '{{% /blockquote %}}', 'endblockquote');

is($o->process_line('Updated 08/11/2010:'), 'Updated 2010-11-08:', 'dates that Hugo dont like');

done_testing();
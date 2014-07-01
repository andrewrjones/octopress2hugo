package octopress2hugo;
use 5.010;
use strict;
use warnings;

my $inFrontMatter;

sub new {
	my $class = shift;
    my $args  = shift;
    my $self  = {};

    bless( $self, $class );

    return $self;
}

sub process_line {
	my ($self, $line) = @_;

	my $newline = $line;
	given($line){
		# remove HR
		# I only used these before footnotes, but the Hugo markdown parser puts it in for me, so I just get rid of them
		# if you use these in your writing, you probably want to remove this feature.
		# need to ensure we don't remove the front matter
		when(/^---/){
			if(not defined $self->{inFrontMatter}){
				$self->{inFrontMatter} = 1;
				return $line;
			} elsif($self->{inFrontMatter} == 1){
				$self->{inFrontMatter} = 0;
				return $line;
			} else {
				$newline = undef;
			}
			break;
		}
		# Remove octopress' layout definition. Everything is the same for me anyway.
		when(/^layout\:/){ $newline = undef; break; }
		# remove comments: *
		when(/^comments\:/){ $newline = undef; break; }
		# Format the date correctly for Hugo
		when(/^date\: (?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d) (?<hour>\d\d)\:(?<min>\d\d)/){
			$newline = sprintf('date: %s-%s-%sT%s:%s:00+00:00', $+{year}, $+{month}, $+{day}, $+{hour}, $+{min});
			break;
		}
		# Hugo doesn't like `&amp;` in the title
		when(/^title\:/){
			$newline =~ s/&amp;/&/g;
			break;
		}
		# Octopress allowed a single category to be on the same line as `categories: `, but Hugo
		# requires it to be a list.
		when(/^categories: (\w+)/){
			$newline = "categories:\n- $1";
			break;
		}
		# For linked posts, Octopress uses `external-url:`. I prefer `linked: ` when implementing them myself
		# in Hugo
		when(/^external-url: /){
			$newline =~ s/external-url/linked/;
			break;
		}
		# convert Octopress image tags to Hugo figure
		# regex from https://github.com/imathis/octopress/blob/master/plugins/image_tag.rb
		when(/{% img (?<class>\S.*\s+)?(?<src>(?:https?:\/\/|\/|\S+\/)\S+)(?:\s+(?<width>\d+))?(?:\s+(?<height>\d+))?(?<title>\s+.+)? %}/i){
			$newline = sprintf('{{%% figure src="%s"', $+{src});
			# TODO: check for title, alt, etc
			$newline .= ' %}}';
			break;
		}
		# convert HTML image tag with link to Hugo figure
		# FIXME: be more flexible in ordering, missing tags, etc
		when(/<a href=["'](?<link>\S+)["'].*>\s*<img src=["'](?<src>\S+)["'].*alt=["'](?<alt>.*?)["']/){
			$newline = sprintf('{{%% figure src="%s" link="%s" alt="%s" %%}}', $+{src}, $+{link}, $+{alt});
			break;
		}
		# convert HTML image tags to Hugo figure
		# FIXME: be more flexible in ordering, missing tags, etc
		when(/<img src=["'](?<src>\S+)["'].*alt=["'](?<alt>.*?)["']/){
			$newline = sprintf('{{%% figure src="%s" alt="%s" %%}}', $+{src}, $+{alt});
			break;
		}
		# convert Octopress blockquote tags to my Hugo shortcode
		# regex from https://github.com/imathis/octopress/blob/master/plugins/blockquote.rb
		when(/{% blockquote (\S.*)\s+(https?:\/\/)(\S+) %}/i){
			$newline = sprintf('{{%% blockquote author="%s" source="%s" %%}}', $1, $2 . $3);
			break;
		}
		when(/{% blockquote (\S.*)\s+(https?:\/\/)(\S+)\s+(.+) %}/i){
			$newline = sprintf('{{%% blockquote author="%s" source="%s" title="%s" %%}}', $1, $2 . $3, $4);
			break;
		}
		# endblockquote
		when('{% endblockquote %}'){
			$newline = '{{% /blockquote %}}';
			break;
		}
		# gist shortcode
		when(/{% gist(.*?)%}/){
			$newline = "{{% gist$1%}}";
			break;
		}
	}

	# inline fixes

	# Markdown converter that Hugo uses messes with dates like 01/01/2012
	{
		no warnings;
		$newline =~ s!([0-9]{2})/([0-9]{2})/([0-9]{4})!$3-$2-$1!g;
	}

	return $newline;
}

1;
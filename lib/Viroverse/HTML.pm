use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::HTML;

use Text::Markdown;
use HTML::Restrict;
use namespace::clean;

# All of this substantially duplicated from TCozy::HTML

sub markdown {
    my $self = shift;
    state $m = Text::Markdown->new(
        empty_element_suffix   => ">",
        trust_list_start_value => 1,
    );
    return $self->scrub_html( $m->markdown( shift ) );
}

sub scrub_html {
    my $self = shift;
    state $scrubber = HTML::Restrict->new(
        rules => {
            a       => [qw[ href target ]],
            b       => [],
            br      => [],
            code    => [],
            em      => [],
            h1      => [],
            h2      => [],
            h3      => [],
            h4      => [],
            h5      => [],
            h6      => [],
            i       => [],
            li      => [],
            ol      => [],
            p       => [],
            strong  => [],
            sub     => [],
            sup     => [],
            table   => [qw[ class ]],
            tbody   => [],
            thead   => [],
            tr      => [],
            th      => [],
            td      => [],
            tt      => [],
            u       => [],
            ul      => [],
        },

        # message:// is used by OS X to link to email Message-IDs
        uri_schemes => [ undef, qw[ http https ftp message ] ],

        # Add the Bootstrap img-responsive class to all images.
        replace_img => sub {
            my ($tagname, $attr, $text) = @_;
            no warnings 'uninitialized';
            return qq[<img class="img-responsive" alt="$attr->{alt}" src="$attr->{src}" title="$attr->{title}">];
        },
    );
    return $scrubber->process(shift);
}

1;

package Viroverse::View::NG;

use 5.010;
use strict;
use base 'Catalyst::View::TT::Alloy';
use Template::Alloy::VMethod qw<>;
use Lingua::EN::Inflexion { noun => 'inflect_noun', inflect => 'inflect' };
use Pod::Simple::XHTML;
use Viroverse::HTML;

my $filter_html = $Template::Alloy::VMethod::SCALAR_OPS->{html}
    or die "Can't find Template::Alloy html filter";

my $filter_angular = sub {
    # Escapes Angular.js interpolated expressions {{...}} by replacing them
    # with an escaped version surrounded by _real_ interpolated expressions
    # (which are empty) in order to ensure that interpolation processing is
    # triggered for this content.  As documented¹, the escaped forms won't be
    # replaced by their unescaped forms unless the content has a real
    # interpolation in it.  We use two real interpolations as triggers since we
    # process content after Markdown (we'd run into issues with backslash
    # escaping if we did it _before_ Markdown).  Markdown can split expressions
    # across HTML elements, which are processed separately by Angular.
    #
    # ¹ https://code.angularjs.org/1.4.14/docs/api/ng/service/$interpolate
    shift =~ s/\{\{(.*?)\}\}/{{}}\\{\\{$1\\}\\}{{}}/sgr
};

__PACKAGE__->config({
    WRAPPER     => 'layouts/default.tt',
    AUTO_FILTER => 'html',
    RECURSION   => 1,
    LOAD_PERL   => 1,
    FILTERS         => {
        commafy     => sub {
            my $num = shift // return undef;

            # Ensure we have a number we can handle.  Note that this check also
            # ensures that we don't have to further HTML-escape our return
            # value for safety.  In the common usage of
            #
            #   <% number | commafy %>
            #
            # HTML escaping isn't applied.  (It would have to be explicitly
            # specified with "... | commafy | html".)
            #
            return undef unless $num =~ /^\d+([.]\d+)?$/;

            my ($integer, $decimal) = split /[.]/, $num, 2;

            $integer = reverse $integer;
            $integer =~ s/(?<=\G\d{3})(?!$)/,/g;
            $integer = reverse $integer;

            return defined $decimal
                ? "$integer.$decimal"
                : $integer;
        },
        pod => sub {
            my $pod = shift // return undef;

            # Setup POD → HTML formatter
            my $formatter = Pod::Simple::XHTML->new;
            $formatter->html_header('');
            $formatter->html_footer('');
            # Headers do not actually look good inside the Help panel,
            # but =head2s should correspond to <h3>s
            $formatter->html_h_level(2);

            $formatter->output_string(\my $html);
            $formatter->parse_string_document($pod);
            return $filter_angular->($html);
        },
        markdown => sub { $filter_angular->(Viroverse::HTML->markdown(@_)) },
    },
    VARIABLES => {
        Inflect => {
            noun    => \&inflect_noun,
            phrase  => \&inflect,
        },
    },
});

# Redefine the standard HTML filter to also escape Angular interpolated
# expressions.  This is necessary, as noted in the Angular security guide²,
# because we use a mix of server-side templates with user-provided data and
# which are processed client-side by Angular.  Template::Alloy, because it
# blurs the distinction between vmethods and filters, looks for filter
# functions in scalar vmethods before true filter methods.
#
# ² https://docs.angularjs.org/guide/security#angularjs-templates-and-expressions
Template::Alloy->define_vmethod('scalar', html => sub {
    $filter_html->($filter_angular->(shift))
});

1;

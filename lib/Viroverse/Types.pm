use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Types;
use Type::Library -base, -declare => qw(
    ViroDBRecord
    WithOptionalFreezerLocation
    EmptyStr
    ImporterClass
);
use Type::Utils -all;
use Types::Standard -types;
use Types::Common::String qw< NonEmptySimpleStr >;
use Types::LoadableClass -types;
use ViroDB;

declare "ViroDBRecord",
    constraint_generator => sub {
        my ($class) = @_;
        return (InstanceOf["ViroDB::Result::$class"])->plus_fallback_coercions(
            Int, sub { ViroDB->instance->resultset($class)->find($_) }
        );
    };

declare EmptyStr, as Str, where { length $_ == 0 };

# If you adjust this type, please also consider if any changes are necessary to
# _build_fields in Viroverse::ImportType.  Thanks!
declare "WithOptionalFreezerLocation",
    constraint_generator => sub {
        return (Dict[
            @_,
            freezer => Optional[EmptyStr],
            rack    => Optional[EmptyStr],
            box     => Optional[EmptyStr],
            ] | Dict[
            @_,
            freezer => NonEmptySimpleStr,
            rack    => NonEmptySimpleStr,
            box     => NonEmptySimpleStr,
        ]);
    }
;

declare ImporterClass,
    as ClassDoes["Viroverse::Import"] & StrMatch[qr/^Viroverse::Import::/];

coerce ImporterClass,
    from StrMatch[qr/^(?!Viroverse::Import::)/],
    via { "Viroverse::Import::$_" };

1;

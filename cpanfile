requires 'perl', '== 5.18.1';

# Initially generated by Perl::PrereqScanner
requires 'Catalyst', '>= 5.90090';
requires 'Catalyst::Action::FromPSGI', '0.001006';
requires 'Catalyst::ActionRole::MatchRequestAccepts', '0.05';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Cache::FastMmap', '0.9';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap', '0.16';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::StatusMessage';
requires 'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack';
requires 'Catalyst::TraitFor::Request::ProxyBase';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT', '0.44';
requires 'Catalyst::View::TT::Alloy', '0.00007';
requires 'Template::Alloy', '1.020';
requires 'Catalyst::View::Vega';
requires 'Catalyst::ResponseHelpers';
requires 'Config::Any';
requires 'Config::General';

on 'develop' => sub {
    requires 'Catalyst::Devel';
    requires 'Plack::Middleware::Debug';
    requires 'Plack::Middleware::Debug::CatalystStash';
    requires 'Plack::Middleware::Debug::DBIC::QueryLog';
    requires 'Plack::Middleware::Debug::DBIProfile';
    requires 'Plack::Middleware::ForceEnv';
    requires 'DBIx::Class::Schema::Loader'; # provides dbicdump
    requires 'Devel::Confess';
    requires 'Devel::REPL';
    requires 'Devel::REPL::Profile::TSIBLEY';
    requires 'Data::Printer';
    requires 'Term::ReadLine::Gnu';
};

requires 'Plack';
requires 'Plack::App::File';
requires 'Plack::Middleware::ConditionalGET';
requires 'Plack::Middleware::Header';
requires 'Plack::Middleware::NoMultipleSlashes';
requires 'Plack::Middleware::ReverseProxy';
requires 'Plack::Middleware::SetEnvFromHeader';
requires 'Server::Starter';
requires 'Starlet';

requires 'autodie';
requires 'Archive::Zip';
requires 'Beanstalk::Client', '1.07';
requires 'Benchmark';

requires 'Carp';
requires 'Class::Accessor';

requires 'Class::DBI::AbstractSearch';
requires 'Class::DBI::Pg';
requires 'Class::DBI::Plugin::RetrieveAll';

requires 'Clone';

requires 'Cpanel::JSON::XS', '3.0225';	# Numeric serialization fixes for dual-type variables

requires 'DBD::Pg', '3.5.1';
requires 'DBI';
requires 'DBIx::Class';
requires 'DBIx::Class::Helper::ResultSet::Shortcut';
requires 'DBIx::Class::Schema';
requires 'App::Sqitch', '0.997';

# Undeclared Sqitch dependency required by its Build.PL for sane test
# prerequisite handling
requires 'Module::Build', '0.4004';

requires 'Data::Dump';
requires 'Data::Dumper';
requires 'DateTime::Format::Duration';
requires 'DateTime::Format::Pg';
requires 'DateTime::Format::RFC3339';
requires 'DateTime::Format::Strptime';
requires 'Digest::MD5';
requires 'English';
requires 'Exporter';
requires 'Exporter::Tiny';
requires 'Excel::Writer::XLSX';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::LibMagic';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'File::chdir';
requires 'FindBin';
requires 'GD';
requires 'GD::Simple';
requires 'Getopt::Long';
requires 'Getopt::Long::Descriptive', '0.100';
requires 'Hash::Fold';
requires 'HTML::Entities';
requires 'HTML::Restrict';
requires 'HTML::TreeBuilder';
requires 'IO::Scalar';
requires 'IO::String';
requires 'IPC::ConcurrencyLimit';
requires 'IPC::ConcurrencyLimit::WithStandby';
requires 'IPC::Open2';
requires 'Image::Info', '1.37';

# Imager will bundle JPEG, PNG, and TIFF if the external C libraries are
# available, which should be the case in a normal environment before Perl deps
# get installed.  We list them here as an extra check in case the external
# libraries aren't available, in which case the specific package will fail.  It
# also makes explicit the app's needs.
requires 'Imager';
requires 'Imager::File::JPEG';
requires 'Imager::File::PNG';
requires 'Imager::File::TIFF';

requires 'Import::Into';
requires 'JSON::MaybeXS';
requires 'Lingua::EN::Inflexion';
requires 'List::Compare';
requires 'List::AllUtils';
requires 'List::MoreUtils';
requires 'List::Util', '1.45';
requires 'List::UtilsBy', '0.04';
requires 'Log::Contextual';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Array';
requires 'Log::Log4perl';
requires 'Math::Base::Convert';
requires 'Mail::Send';
requires 'Module::Pluggable';
requires 'Module::Runtime';
requires 'Moo', '2';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::NonMoose';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::Role::Parameterized';
requires 'namespace::autoclean';
requires 'namespace::clean';
requires 'NEXT';
requires 'Net::FTP';
requires 'NetAddr::IP';
requires 'POSIX';
requires 'Path::Tiny';
requires 'Physics::Unit';
requires 'Pod::Abstract';
requires 'Pod::Simple::XHTML';
requires 'Pod::Usage';
requires 'Ref::Util';
requires 'Regexp::Common';
requires 'SQL::Abstract';
requires 'Safe::Isa', '1.000004';
requires 'Scalar::Util';
requires 'Sort::ByExample';
requires 'Sort::Naturally';
requires 'Spreadsheet::Read';
requires 'Spreadsheet::ParseExcel';
requires 'Spreadsheet::ParseXLSX';
requires 'Storable';
requires 'String::CamelSnakeKebab';
requires 'String::Flogger';
requires 'Sub::Exporter';
requires 'SVG::Sparkline';
requires 'Template'; # Template-Toolkit
requires 'Template::Plugin::JSON::Escape', '0.02';
requires 'Test::More';
requires 'Test::WWW::Mechanize::Catalyst';
requires 'Text::Markdown';
requires 'Text::ParseWords';
requires 'Text::CSV';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'Types::Common::Numeric';
requires 'Types::Common::String';
requires 'Types::DateTime';
requires 'Types::LoadableClass', '0.003';
requires 'Types::Path::Tiny';
requires 'Types::Standard';
requires 'Web::Machine';
requires 'WWW::Mechanize';
requires 'WWW::Mechanize::Plugin::FollowMetaRedirect';
requires 'Excel::Writer::XLSX';

# Pragma, mostly core
requires 'base';
requires 'constant';
requires 'lib';
requires 'parent';
requires 'strict';
requires 'vars';
requires 'warnings';

# Local libraries, not on CPAN
# requires 'Fasta';

# Vendored module dependencies
do "vendor/mullins/cpanfile"
    or die "Couldn't source vendor/mullins/cpanfile: ", $@ || $! || "returned false";

# External deps
#
# libgd
# libsyck
# beanstalkd
# EMBOSS 6.6.0.0
# quality (from ancient tarball)
# file (probably 5 or newer, 4.x magic.h doesn't work with File::LibMagic)

on 'test' => sub {
    requires 'Data::Tumbler';
    requires 'DateTime';
    requires 'HTTP::Request::Common';
    requires 'Safe::Isa';
    requires 'Test::Deep';
    requires 'Test::Deep::DateTime::RFC3339', '0.04';
    requires 'Test::LongString';
    requires 'Test::More';
    requires 'Test::Warnings', '0.005';
};

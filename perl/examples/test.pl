use strict; use warnings;

use Test::More;
use Test::Exception;

use FindBin;

use lib "$FindBin::Bin";

use Data::Rx;
use Data::Rx::Type::DateTime::W3;
use Data::Rx::Type::Enum;
use Data::Rx::Type::CSV;

my $rx = Data::Rx->new({
    sort_keys => 1,
    prefix => {
        example => 'tag:codesimply.com,EXAMPLE:rx/',
    },
    type_plugins => [qw(
        Data::Rx::Type::DateTime::W3
        Data::Rx::Type::Enum
        Data::Rx::Type::CSV
    )],
});

subtest 'DateTime::W3' => sub {
    dies_ok {
        my $dt = $rx->make_schema({
            type => '/example/datetime/w3',
            zirble => 'fleem',
        });
    } 'Construction dies on extra arguments';

    my $dt = $rx->make_schema({
        type => '/example/datetime/w3',
    });

    ok ! $dt->check( undef ), 'Undef is not a valid string';
    ok ! $dt->check( [] ),    'Reference is not a valid string';

    ok ! $dt->check( '9th Feb 2012' ), 'invalid datetime format';

    ok $dt->check( '1994-11-05T08:15:30-05:00' ), 'datetime format with offset';
    ok $dt->check( '1994-11-05T08:15:30+05:00' ), 'datetime format with positive';
    ok $dt->check( '1994-11-05T13:15:30Z' ),      'datetime format zulu';
};

subtest 'Enum' => sub {
    dies_ok {
        my $enum = $rx->make_schema({
            type => '/example/enum',
        });
    } 'Construction dies on insufficient arguments';

    dies_ok {
        my $enum = $rx->make_schema({
            type => '/example/enum',
            contents => {
                type => '//str',
            },
        });
    } 'Construction dies on insufficient arguments';

    dies_ok {
        my $enum = $rx->make_schema({
            type => '/example/enum',
            contents => {
                type => '//str',
                values => [ 'foo', 'bar', 'baz' ],
                bar => 'baz',
            },
        });
    } 'Construction dies on extra arguments';

    my $enum = $rx->make_schema({
        type => '/example/enum',
        contents => {
            type => '//str',
            values => [ 'foo', 'bar', 'baz' ],
        },
    });

    ok ! $enum->check( undef ), 'Undef is not a valid string';
    ok ! $enum->check( [] ),    'Reference is not a valid string';

    ok ! $enum->check( 'fleem' ), 'not in enum';

    ok $enum->check( 'foo' ), 'in enum';
    ok $enum->check( 'bar' ), 'in enum';
    ok $enum->check( 'baz' ), 'in enum';
};

subtest 'csv tests' => sub {

    dies_ok {
        my $csv = $rx->make_schema({
            type => '/example/csv',
        });
    } 'Construction dies on no contents';

    $rx->learn_type( 'tag:codesimply.com,EXAMPLE:rx/status' => {
        type => '/example/enum',
        contents => {
            type => '//str',
            values => ['open', 'closed'],
        },
    });

    dies_ok {
        my $csv = $rx->make_schema({
            type => '/example/csv',
            contents => '/example/status',
            zirble => 'fleem',
            roobit => [1,2],
        });
    } 'Construction dies on extra arguments';

    my $csv = $rx->make_schema({
        type => '/example/csv',
        contents => '/example/status',
        trim => 1,
    });

    ok ! $csv->check( undef ), 'Undef is not a valid string';
    ok ! $csv->check( [] ),    'Reference is not a valid string';

    ok ! $csv->check( 'zibble' ),      'invalid string';
    ok ! $csv->check( 'open,zibble' ),  'an invalid element';

    ok $csv->check( 'open' ),         'single value';
    ok $csv->check( 'open,closed' ), 'multiple values ok';
    ok $csv->check( 'open, closed ' ), 'spaces trimmed ok';
};

done_testing;

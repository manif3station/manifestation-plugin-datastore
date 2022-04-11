package DataStore::Services;

use strict;
use warnings;

sub services {
    {
        schema => {
            class      => 'DataStore::Schema',
            parameters => {
                plugin_name => {},
            },
        },
        list => {
            class      => 'DataStore::List',
            parameters => {
                plugin_name => {},
            },
        },
        item => {
            class      => 'DataStore::Item',
            parameters => {
                plugin_name => {},
                item_name   => {},
            },
        },
    }
}

1;

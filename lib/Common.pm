package DataStore::Common;

use Moo::Role;
use MF::Utils qw(makedir load_json);
use MF::Services;

has plugin_name => ( is => 'ro', required => 1 );

has plugin => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        Service->MF->Plugins->plugin(name => $self->plugin_name);
    },
);

has data_dir => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return makedir $self->plugin->plugin_dir . '/stateful/data';
    }
);

1;

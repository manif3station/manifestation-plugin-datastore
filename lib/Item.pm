package DataStore::Item;

use Moo;
use MF::Utils qw(openfile writefile_json load_json);

with 'DataStore::Common';

has schema => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        Service->DataStore->schema( plugin_name => $self->plugin_name );
    }
);

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return $self->data_dir . "/" . $self->item_name;
    }
);

sub _new_item {
    my ( $self, %data ) = @_;
    my $file   = $self->file;
    my $schema = $self->schema;
    my $class  = $schema->class;
    my $fields = $schema->fields;
    $class->new( %data, __file => $file, __fields => $fields );
}

sub load {
    my ($self) = @_;
    my $file = $self->file;
    return if !-f $file;
    my $data = load_json file => $self->file;
    return $data
      ? $self->_new_item(%$data)
      : undef;
}

sub add {
    my ( $self, %new ) = @_;
    $self->_new_item(%new, created => time)->update;
}

1;

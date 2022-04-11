package DataStore::List;

use Moo;
use MF::Utils qw(listdir);

with 'DataStore::Common';

sub items {
    my ($self) = @_;

    my @items;

    listdir $self->data_dir => sub {
        my %row  = @_;
        return if $row{item} eq 'data.schema.json';
        push @items, $row{item}
            if $row{item} =~ m/\.json$/;
      },
      { file_only => 1 };

      return @items;
}

1;

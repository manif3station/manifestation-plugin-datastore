package DataStore::Schema;

use MF::Utils qw(load_json openfile defor file);

use Moo;

use Template;
use Try::Tiny;

my %SCHEMA = ();

my $LOADER = do {
    local $/;
    <DATA>;
};

with 'DataStore::Common';

has schema_file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return file
          CONFIG => $self->plugin_name,
          'data.schema.json',
          want                => 'path',
          stop_when_not_found => 1;
    },
);

has schema => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return load_json file => $self->schema_file;
    }
);

has package_name => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return "DataStore::Schema::" . $self->plugin->name;
    }
);

has utility_functions => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $funcs = defor $self->schema->{utils}, [];
        die "utils must be an array (! $funcs)"
          if !UNIVERSAL::isa( $funcs, 'ARRAY' );
        push @$funcs, 'writefile_json';
        return $funcs;
    }
);

has fields => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $fields = $self->schema->{fields} or die "Schema missing fields";
        $fields->{created} = {isa => 'Int'};
        $fields->{updated} = {isa => 'Int'};
        return $fields;
    }
);

sub class {
    my ($self) = @_;

    my $plugin_name = $self->plugin_name;

    my $schema_class = $SCHEMA{$plugin_name};

    return $schema_class
      if $schema_class;

    my $template = Template->new;

    my %vars = (
        package => $self->package_name,
        fields  => $self->fields,
        utils   => $self->utility_functions,
        defor   => \&defor,
    );

    my $class;

    try {
        $template->process( \$LOADER, \%vars, \$class );
    }
    catch {
        die defor $_, $template->error;
    };

    eval $class;

    die "$class\n----> Error: $@\n" if $@;

    $SCHEMA{$plugin_name} = $self->package_name;
}

1;

__DATA__
package [% package %] {

use Moose;
use MF::Utils qw([% utils.join(' ') %]);

[%~ USE Dumper(indent=0) ~%]

[% FOREACH field IN fields.keys.sort -%]
has [%field%] => (
    is       => 'rw',
    isa      => '[% fields.$field.isa || "Str" %]',
    required => [% defor(fields.$field.required, 0) %],
    [% IF fields.$field.default.func %]
    lazy     => 1,
    builder  => 1,
    [% ELSIF fields.$field.default %]
    lazy     => 1,
    default  => sub { [% Dumper.Dump(fields.$field.default) %] },
    [% END %]
);
[% IF fields.$field.default.func -%]
sub _build_[% field %] {
    my ($self) = @_;
    [% fields.$field.default.func %];
}
[% END -%]
[% END -%]

has __file => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has __fields => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub update {
    my ($self) = @_;
    my $fields = $self->__fields;
    my %store  = ();
    $self->updated(time);
    @store{keys %$fields} = @$self{keys %$fields};
    writefile_json $self->__file, data => \%store;
    return 1;
}

sub delete {
    my ($self) = @_;
    unlink $self->__file;
    return 1;
}

}

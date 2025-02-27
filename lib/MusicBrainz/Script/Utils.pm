package MusicBrainz::Script::Utils;
use strict;
use warnings;

use English;

use feature 'state';

use base 'Exporter';

our @EXPORT_OK = qw( get_primary_keys log retry );

=sub get_primary_keys

Get a list of primary key column names for $schema.$table.

=cut

sub get_primary_keys($$$) {
    my ($sql, $schema, $table) = @_;

    state $cache = {};
    if (defined $cache->{$table}) {
        return @{ $cache->{$table} };
    }

    # retry: transient "server closed the connection unexpectedly",
    # "no statement executing", and "Field 'attnum' does not exist" errors
    # have happened here.
    my @keys = retry(
        sub { $sql->dbh->primary_key(undef, $schema, $table) },
        reason => 'getting primary keys',
    );
    @keys = map {
        # Some columns are wrapped in quotes, others aren't...
        s/^"(.*?)"$/$1/r
    } @keys;
    $cache->{$table} = \@keys;
    return @keys;
}

=sub log

Log a message to stdout, prefixed with the local time and ending with a
newline.

=cut

sub log($) {
    print localtime . ' : ' . $_[0] . "\n";
}

=sub retry

Retry a callback upon errors, with exponential backoff.

=cut

sub retry {
    my ($callback, %opts) = @_;

    my $attempts_remaining = 5;
    my $delay = 15;
    my $reason = $opts{reason} // 'executing callback';
    while (1) {
        my $error;
        if (wantarray) {
            my @result = eval { $callback->() };
            $error = $EVAL_ERROR;
            return @result unless $error;
        } else {
            my $result = eval { $callback->() };
            $error = $EVAL_ERROR;
            return $result unless $error;
        }
        if ($attempts_remaining--) {
            MusicBrainz::Script::Utils::log(
                qq(Died ($reason), ) .
                qq(retrying in $delay seconds: $error));
        } else {
            die $error;
        }
        sleep $delay;
        $delay *= 2;
    }
}

1;

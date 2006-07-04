package Email::Store::Mail;
use base 'Email::Store::DBI';
use Time::HiRes;
use strict; 
use warnings;

require Email::Store;

Email::Store::Mail->table("mail");
Email::Store::Mail->columns(All => qw/message_id message/);
Email::Store::Mail->columns(Primary => qw/message_id/);
Email::Store::Mail->columns(TEMP => qw/simple/);
use Module::Pluggable::Ordered search_path => ["Email::Store"], only => [ keys %Email::Store::only ];

use Email::Simple;

sub _simple { Email::Simple->new(shift); } # RFC2822 -> Email::Simple

sub simple {
    my $self = shift;
    return $self->_simple_accessor || do {
        $self->{simple} = _simple($self->message);
    }
}

sub store {
    my ($class, $rfc822) = @_;
    my $simple = Email::Simple->new($rfc822);
    my $msgid = $class->fix_msg_id($simple);
    my $self;

    if ($self = $class->retrieve($msgid)) {
        $class->call_plugins("on_seen_duplicate", $self, $simple);
        return $self;
    }

    $self = $class->create ({ message_id => $msgid, 
                              message    => $rfc822, 
                              simple     => $simple });
    $self->call_plugins("on_store", $self);
    $self;
}

sub fix_msg_id {
    my ($self, $simple) = @_;
    my $id = $simple->header("Message-ID");
    if ($id) { $id =~ s/.*<(.+)>.*/$1/ && return $id; }
    my $fake = $$."-".time()."\@unknown";
    $simple->header_set("Message-ID", "<$fake>");
    return $fake;
}

1;

=head1 NAME

Email::Store::Mail - An email in the database

=head1 SYNOPSIS

    Email::Store::Mail->store($message)

    my $mail = Email::Store::Mail->retrieve($msgid);

    my Email::Simple $simple = $mail->simple;
    print $mail->message;

    # Plus many additional accessors added by plugins

=head1 DESCRIPTION

While a fundamental concept in C<Email::Store>, a C<mail> is by itself
reasonably simple. It only has two properties, a C<message_id> and a
C<message>. A utility method C<simple> will produce a (cached)
C<Email::Simple> object representing the mail.

=head2 Indexing

When a mail is indexed with C<store>, all the plugins are called.
Plugins register a method called C<on_store> to get their chance to play
with an incoming mail, and C<on_store_order> to determine where in the
process they wish to be called in relation to other modules.

The C<on_store> method gets passed the mail object and can examine and
modify it while also doing what it needs to populate its own table(s).

=head2 Indexing Duplicates

When a message is stored but already exists in the database,
C<on_seen_duplicate> is called in the plugins rather than C<on_store>.
This allows, for instance, the List plugin to detect passage through
addiional lists.

=cut

__DATA__

CREATE TABLE IF NOT EXISTS mail (
    message_id varchar(255) NOT NULL primary key,
    message text
);

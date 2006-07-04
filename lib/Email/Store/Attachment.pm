package Email::Store::Attachment;
use base "Email::Store::DBI";
use strict;
use Email::MIME::Attachment::Stripper; # Until we write our own
use Email::Abstract;
use Email::MIME;
__PACKAGE__->table("attachment");
__PACKAGE__->columns(All => qw[id mail filename content_type payload ]);
__PACKAGE__->has_a(mail => "Email::Store::Mail");
Email::Store::Mail->has_many(attachments => "Email::Store::Attachment");

sub on_store {
    my ($class, $mail) = @_;
    my $mm;
    { local $SIG{__WARN__} = sub { "Shut *UP*, Mail::Box!" };
      my $mail_message = Email::Abstract->cast($mail->message, "Email::MIME");
      $mm = Email::MIME::Attachment::Stripper->new( $mail_message );
    }
    $mail->add_to_attachments($_) for $mm->attachments;
    # In case we twiddled it
    $mm->message->header_set("Message-ID", $mail->message_id); 
    $mail->message($mm->message->as_string);
    undef $mail->{simple}; # Invalidate cache
    $mail->update;
}

sub on_store_order { 1 }

1;

=head1 NAME

Email::Store::Attachment - Split attachments from mails

=head1 SYNOPSIS

    my @attachments = $mail->attachments;
    for (@attachments) {
        print $_->filename, $_->content_type, $_->payload;
    }

=head1 DESCRIPTION

This plug-in adds the concept of an attachment. At index time, it
removes all attachments from the mail, and stores them in a separate
attachments table. This records the C<filename>, C<content_type> and
C<payload> of the attachments, and each mail's attachments can be
reached through the C<attachments> accessor. The text of the mail,
sans attachments, is replaced into the mail table.

=head1 WARNING

If your database requires you to turn on some attribute for encoding
binary nulls, you need to do this in your call to C<use Email::Store>.

=cut

__DATA__

CREATE TABLE IF NOT EXISTS attachment (
    id           integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
    mail         varchar(255),
    payload      text,
    filename     varchar(255),
    content_type varchar(255)
);

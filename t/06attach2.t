use Test::More tests => 5;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store { only => [qw( Mail Attachment )] }, 
    ("dbi:SQLite2:dbname=t/test.db", "", "", { sqlite_handle_binary_nulls => 1 } );
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/message.out");
my $mail = Email::Store::Mail->store($data);
my @att = $mail->attachments;
is (@att, 1, "Has one attachment");
my $msg = $mail->message;
like ($msg, qr/submission/, "Message with crap stripped");
unlike ($msg, qr/JVBERi0x/, "Message with crap stripped");
is($att[0]->content_type, "application/pdf");

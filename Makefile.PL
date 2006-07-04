use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Email::Store',
    VERSION_FROM      => 'lib/Email/Store.pm', # finds $VERSION
    PREREQ_PM         => {
        Module::Pluggable::Ordered => 1.0,
        Module::Pluggable => 1.4,
        Email::Simple => 1.0,
        Email::MIME => 0,
        DBD::SQLite => 0,
        Class::DBI => 0.9,
        Class::DBI::DATA::Schema => 0,
        Mail::ListDetector => 0.30,
        Email::MIME::Attachment::Stripper => 1.1,
        Time::Piece => 0,
        File::Slurp => 0,
        Email::Address => 0,
        SQL::Translator => 0,
    }, # e.g., Module::Name => 1.1
);

use warnings;
use strict;

=head1 NAME

BarnOwl::Module::DevUtils

=head1 DESCRIPTION

Provides some small utilities to aid perl development in BarnOwl

=cut

package BarnOwl::Module::DevUtils;

our $VERSION = 0.1;

use Data::Dumper;
use Getopt::Long;

BarnOwl::new_command(
    eperl => sub { goto \&cmd_eperl },
    {
        summary     => 'Open the edit window for perl code',
        description => "Opens the edit window and allows the user to \n" .
                       "enter perl code, and executes the entered code.\n" .
                       "Accepts the following options:\n\n" .
                       "-p    Display the result in a popup window\n" .
                       "-a    Display the result as an admin message\n" .
                       "-y    Format the result using YAML\n" .
                       "-d    Format the result using Data::Dumper",
        usage       => 'eperl [-p] [-y] [-d] [-a]'
    }
);

sub cmd_eperl {
    my $flags = {popless => 0, dumper => 0, yaml => 0, admin => 0};
    my $p = Getopt::Long::Parser->new;
    local @ARGV = @_;
    
    $p->configure("bundling");
    $p->getoptions(p => \$flags->{popless},
                   a => \$flags->{admin},
                   y => \$flags->{yaml},
                   d => \$flags->{dumper},
                  ) or die("Usage: eperl [-p] [-y] [-d] [-a]\n");
    BarnOwl::start_edit_win("Enter perl to eval: ", sub {eval_perl($flags, shift)});
}

sub eval_perl {
    my $flags = shift;
    my $perl = shift;
    my $result;
    {
        local $SIG{__WARN__} = sub {
            my $warning = shift;
            warn $warning unless $warning =~ /^Subroutine .+ redefined at/;
        };
        $result = eval ("package main; " . $perl);
    }
    if($@) {
        BarnOwl::error($@);
        BarnOwl::popless_text("[Error in perl evaluation]\n$@");
    } else {
        if(!defined($result)) {
            $result = "undef";
        }
        if($flags->{dumper}) {
            $result = Dumper($result);
        } elsif($flags->{yaml}) {
            eval {require YAML};
            if(!$@) {
                $result = YAML::Dump($result);
            }
        }
        if($flags->{popless}) {
            BarnOwl::popless_text($result);
        } elsif($flags->{admin}) {
            BarnOwl::admin_message('Perl eval', $result);
        } else {
            BarnOwl::message($result);
        }
    }
}

1;

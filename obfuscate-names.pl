#!/usr/bin/perl

use strict;
use warnings;

use lib 'ext/Font-TTF/lib';
use Font::TTF::Font;

use Getopt::Long;

main();

sub help {
    print <<EOF;
Obfuscates fonts by deleting their name fields. The fonts should probably still
work in web browsers via \@font-face, but are a bit harder to install and use
in other applications.

Usage:
  $0 [options] [inputfile.ttf] [outputfile.ttf]

Options:
  --verbose, -v         print various details about the font
EOF
    exit 1;
}

sub set_name {
    my ($font, $id, $val, $verbose) = @_;
    my $str = $font->{name}{strings}[$id];
    for my $plat (0..$#$str) {
        next unless $str->[$plat];
        for my $enc (0..$#{$str->[$plat]}) {
            next unless $str->[$plat][$enc];
            for my $lang (keys %{$str->[$plat][$enc]}) {
                next unless exists $str->[$plat][$enc]{$lang};
                if ($verbose) {
                    print "Setting string $_ (plat $plat, enc $enc) to \"$val\"\n";
                }
                $str->[$plat][$enc]{$lang} = $val;
            }
        }
    }
}

sub main {
    my $verbose = 0;

    my $result = GetOptions(
        'verbose' => \$verbose,
    ) or help();

    @ARGV == 2 or help();

    my ($input_file, $output_file) = @ARGV;

    my $font = Font::TTF::Font->open($input_file) or die "Error opening $input_file: $!";

    $font->{name}->read;

    for (16, 17, 18) {
        if ($verbose and $font->{name}{strings}[$_]) {
            print "Deleting string $_\n";
        }
        $font->{name}{strings}[$_] = undef;
    }

    for (1, 3, 4, 5) {
        set_name($font, $_, '', $verbose);
    }

    for (6) {
        set_name($font, $_, '-', $verbose);
    }

    $font->out($output_file);

    $font->release;
}

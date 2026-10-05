#! /usr/bin/perl
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Cwd qw/getcwd/;
use Getopt::Long;

exit (main ());

sub main {
  my ($pattern, $path, $complete, $run_tests);
  GetOptions ("pattern=s" => \$pattern,
              "path=s" => \$path,
              "completions:s" => \$complete,
              "test" => \$run_tests);

  if (defined $run_tests)
  {
    run_tests ();
    return 0;
  }

  if (defined $complete)
  {
    (defined $path) or $path = getcwd ();

    (defined $pattern) and
      die "Can't use --pattern with --completions\n";
    show_completions ($complete, $path);
    return 0;
  }

  if (defined $pattern)
  {
    (defined $path) or $path = getcwd ();
    show_destination ($path, $pattern);
    return 0
  }

  if (scalar (@ARGV) == 2)
  {
    # This is backwards compatibility.  My bash scripts didn't used to use
    # the command line flags, so handle this case.
    $pattern = $ARGV[0];
    $path = $ARGV[1];
    show_destination ($path, $pattern);
    return 0
  }

  print ("Missing --pattern and --path command line flags.\n");
  return 1;
}

sub show_completions {
  my $pattern = shift;
  my $path = shift;

  # Count the number of '/' characters in the pattern.
  my $sep_count = ($pattern =~ tr~/~~);

  my @parts = split m~/~, $path;
  if ($parts[0] eq "")
  {
    shift @parts;
  }
  my @completions;

  #print "Splitting: $path\n";
  #print "     Into: ".join (" / ", @parts)."\n";
  #print "Sep count = $sep_count\n";
  for (my $i = 0; $i < (scalar (@parts) - $sep_count); $i++)
  {
    #print "  Start at: $i\n";
    my @p;
    for (my $j = 0; $j <= $sep_count; $j++)
    {
      #print "    Taking index: ".($i + $j)."\n";
      push @p, $parts[$i + $j];
      #print "    Got: ".join (" / ", @p)."\n";
    }
    push @completions, join ("/", @p);
  }

  @completions = sort @completions;
  print join (" ", @completions);
}

sub show_destination {
  my $path = shift;
  my $pattern = shift;

  print get_dest($path, $pattern);
}

sub get_dest
{
  # If we are in here: /xx/b/c/a/b/c
  # and use the pattern: a
  # we should print /xx/b/c/a/
  # If we use the pattern: xx/b
  # we should print /xx/b

  my $dir = shift;
  my $pattern = shift;
  $pattern =~ s,//+,/,g;

  $pattern = "^.*$pattern";

  if ( not ( $pattern =~ m,/$, ) )
  {
    $pattern = $pattern . "[^\/]*";
  }

  $dir =~ m/($pattern)/;

  my $res = ( (defined $1) ? $1 : "" );
  $res =~ s,/+$,,;
  return $res;
}

sub run_tests {
  our $test_id = 1;
  sub test {
    my $src = shift;
    my $pattern = shift;
    my $dest = shift;

    my $res = get_dest($src, $pattern);
    printf("%6d ... ", $test_id);
    if ( $res eq $dest )
    {
      printf("PASS\n");
    }
    else
    {
      printf("FAIL\n");
      printf("        -   source: $src\n");
      printf("        -  pattern: $pattern\n");
      printf("        - expected: $dest\n");
      printf("        -   result: $res\n");
    }
    $test_id++;
  }

  test("/abc/def/ghi", "ef",  "/abc/def");
  test("/abc/def/ghi", "de",  "/abc/def");
  test("/abc/def/ghi", "def", "/abc/def");
  test("/abc/def/ghi", "c/d", "/abc/def");
  test("/abc/def/ghi", "/a",  "/abc");

  test("/abc/def/ghi", "ghi", "/abc/def/ghi");
  test("/abc/abc/abc", "abc", "/abc/abc/abc");
  test("/abc/abc/def", "abc/", "/abc/abc");
  test("/abc/abc/def", "b", "/abc/abc");
}

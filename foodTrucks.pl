#!/usr/bin/perl -w #-d
# foodTrucks.pl - Find food trucs with desired foodstuffs
#
use strict;
use warnings;
use Carp;
use Getopt::Long;
use Text::CSV_XS;
use Data::Dumper;

BEGIN
{
  no warnings;              # in this BEGIN block
  $DB::single = 1;          # Allow debugging in BEGIN block
  use FindBin qw($Bin);     # Because my data file is in same directory
}

# Main:
# For now: Only one command line option: --food
#
my $food;
my %trucks;                             # Hash keyed on location ID
my ($in_fname, $in_fpath, $infile);     #  File name, path and file handle
my $runDir = $Bin;          # Get my current directory
$in_fname = "Mobile_Food_Facility_Permit.csv";
$in_fpath = $runDir . "/" . $in_fname;

# OK, before I set up my database see what the user wants
#
GetOptions("food:s" => \$food)
  or die "How could you get the syntax wrong on that comand?!";

open ($infile, "<", "$in_fpath")
  or die "Error <$!>\n opening\n $in_fpath";

my $headline = <$infile>;           # Get first line - Column headings
my @headings = split(/,/, $headline);   # Column headings as well as hash keys
shift(@headings);                   # Lose column heading for the hash key

# Now read in rest of file and set up the hash of hashes but including only
# those trucks that mention my chosen food.  Use Text::CSV_XS object to fetch
#
my $csvh = Text::CSV_XS->new();        #(No funny options)
#while (my $in_line = <$infile>)    #(no; use CSV objct to read line)
while (my $line_ref = $csvh->getline($infile))
{
  my %line_hash;
  my $loc_id = shift(@$line_ref); # Pull off item[0] as hash key
  @line_hash{@headings} = @$line_ref;
  next unless ($line_hash{FoodItems} =~ /$food/i);  # ONLY my food
 #printf ("%d: %s\n", $loc_id, $line_hash{FoodItems}); (debug)

  next if (   $line_hash{FoodItems} =~ /except/i
           || $line_hash{FoodItems} =~ /but /i  );

  # Note that above "except for" option is not reliable.  I'd have to make sure
  # the food I chose is the one that the truck does not sell.  For example, I
  # chose"hot dog" and truck sells "hot dogs, drinks, except for burritos". I
  # would eliminate that truck from consideration although it DOES sell hot
  # dogs.  That calls for gramatic analysis, beyond the scope of this project.
  #
  $trucks{$loc_id} = \%line_hash;   # If I didn't eliminate the truck, add it's
                                    # key into my trucks hash
  1 == 1;   # (For debugging breakpoints)
}

# Now output what I have found.  No relation to where *I* am located. I
# would have added that as a --location option but the location ID's are
# just abstractions, nothing to do with geographic data.  If that were part of
# the project I would have sorted by distance to my current location.
#
foreach my $loc_id (keys %trucks)
{
  printf("Truck at location %8d: (%s) sells %s\n", $loc_id,
         $trucks{$loc_id}->{LocationDescription},
         $trucks{$loc_id}->{FoodItems});
}
exit();

#!/usr/bin/perl
# Set Variables

$carpooldb = "/home/amyandfr/public_html/carpool.csv";
#$carpooldb = "./carpool.csv";
$carpoolheader = "../carpool-parta.htm";
$carpoolbody = "../carpool-partb.htm";
$date_command = "/bin/date";
@drivers = ();
@riders = ();


# Get the Date for Entry
#$date = `$date_command +"%A, %B %d, %Y at %T (%Z)"`; chop($date);
#$shortdate = `$date_command +"%D %T %Z"`; chop($shortdate);

# Load the db from the file
if (open(CPDB, $carpooldb)) {
  while (<CPDB>) {
    chomp;
    @line = split "~";
    if ($line[0] eq 'd') {
      push @drivers, [ @line ];
    } else {
      push @riders, [ @line ];
    }
  }
}
close(CPDB);

# Get the input
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

# Split the name-value pairs
@pairs = split(/&/, $buffer);

foreach $pair (@pairs) {
   ($name, $value) = split(/=/, $pair);

   # Un-Webify plus signs and %-encoding
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $value =~ s/<!--(.|\n)*-->//g;

   if ($allow_html != 1) {
      $value =~ s/<([^>]|\n)*>//g;
   }

   $FORM{$name} = $value;
}

# process any submits
if (exists $FORM{'submit'}) {
  if ($FORM{'submit'} eq 'Add My Ride') {
    @newride = ( ($FORM{'driver'} eq 'true')? 'd':'r', $FORM{'name'}, 
      $FORM{'zip'}, $FORM{'email'}, $FORM{'phone'}, $FORM{'from'},
      $FORM{'open'}, $FORM{'westin'}, $FORM{'late'}, $FORM{'comments'} );
    if ($FORM{'driver'} eq 'true') {
      push @drivers, [ @newride ];
    } else {
      push @riders, [ @newride ];
    }
  } elsif ($FORM{"submit"} eq "Update") {
    if ($FORM{'driver'} eq 'true') {
      $drivers[$FORM{'userIndex'}][6] = $FORM{'open'};
    } else {
      $riders[$FORM{'userIndex'}][6] = $FORM{'open'};
    }
  }
# time to rebuild the db
  if (open(CPDB, ">$carpooldb")) {
    foreach(@drivers) {
      print CPDB join("~",@{$_});
      print CPDB "\n";
    }
    foreach(@riders) {
      print CPDB join("~",@{$_});
      print CPDB "\n";
    }
  }
  close(CPDB);
}

print "Content-Type: text/html\n\n";
open(FH,$carpoolheader);
while (<FH>) {
  print;
}
close FH;

# output drivers and riders
for($i = 0; $i <= $#drivers; $i++) {
  print "drivers[$i] = new ride(\"",join("\",\"",@{$drivers[$i]}[1..9]),"\");\n";
}
for($i = 0; $i <= $#riders; $i++) {
  print "riders[$i] = new ride(\"",join("\",\"",@{$riders[$i]}[1..9]),"\");\n";
}

open(FH,$carpoolbody);
while (<FH>) {
  print;
}
close FH;



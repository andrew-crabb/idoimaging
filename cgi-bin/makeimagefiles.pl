#! /opt/local/bin/perl -w

# makeimagefiles.pl
# Parse image capture file and rename files appropriately.
# Also check for / create and store thumbnail versions of same.
# Naming convention:
#   field_ident_name_ordinal_xdim_ydim.suff
# Always search by ident, given that program name is always going to be unreliable.
# Ordinal, xdim, ydim may be omitted (delimiters may not).  
# Field may be abbreviated ie program -> prog.
# Ordinal is for multiple captures for a given progam and is 0-indexed.
# Thumbnails have no special name, just a smaller size.

use strict;
no strict 'refs';

use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

use Image::Magick;
use Getopt::Std;
use DBI;

my %opts;
getopts('dfhv', \%opts);
my $dummy   = $opts{'d'} || 0;
my $help    = $opts{'h'} || 0;
my $force   = $opts{'f'} || 0;
my $verbose = $opts{'v'} || 0;

if ($help) {
  usage();
  exit;
}

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------
my $PROGCAPDIR   = "/Users/ahc/public_html/idoimaging/img/cap/prog";    # Path for type 'prog'
my $TITLEDIR     = "/Users/ahc/public_html/idoimaging/img/prog_title";  # Path for type 'title'
my $ICONDIR      = "/Users/ahc/public_html/idoimaging/img/icon";
my $MAGICON      = "mag_big.png";
my $PROGPREFIX   = "prog_";
my $TITLEPREFIX  = "title_";
my $SMALLDIR     = "sm";
my $ORIGDIR      = "orig";
 my $SMALLDIM     = 200;
 my $MEDDIM       = 320;
my @FIELDNAMES   = (qw(rsrcfld rsrcid rsrcname ordinal width height suffix filename path scale));

# ------------------------------------------------------------
# Globals
# ------------------------------------------------------------
my $dbh = hostConnect();

our @g_infiles = ();
our @g_newfiles = ();
my @dirfiles = dirContents($PROGCAPDIR);
our @g_allfiles = grep(/^$PROGPREFIX|^$TITLEPREFIX/, @dirfiles);
if (scalar(@ARGV)) {
  foreach my $argv (@ARGV) {
    @g_infiles = (@g_infiles, dirContents($argv));
  }
  @g_infiles = grep(/^$PROGPREFIX/, @g_infiles);
} else {
  @g_infiles = grep(/^$PROGPREFIX/, @dirfiles);
}
print scalar(@g_infiles) . " files matching $PROGPREFIX in $PROGCAPDIR\n";

# Magnifier icon to place on small images.
our $magimage = Image::Magick->new;
if ($magimage->Read(filename => "${ICONDIR}/${MAGICON}")) {
  print "ERROR: Could not read ${ICONDIR}/${MAGICON}\n";
  exit;
}

# Remove from database all records without a matching file.
checkDBRec($dbh, '');

my ($nold, $nnew) = (0, 0);
foreach my $infile (@g_infiles) {
  print "==================== Processing: $infile ====================\n";
  my $image = Image::Magick->new;
  my %imgdet = (
    'rsrcfld'  => '',	# 'prog', 'title' etc.
    'rsrcid'   => '',	# Integer
    'rsrcname' => '',	# Free form program name
    'ordinal'  => '',	# 0-indexed
    'width'    => '',	# Pixels
    'height'   => '',	# Pixels
    'suffix'   => '',	# 'png' etc.
    'filename' => $infile,	# field_ident_name_ordinal_width_height.suff
    'path'     => '',   # subpath only: blank for main image directory.
    'scale'    => '',   # 'full', or pixel class (ie '200' for 200 pixel max).
      );

  if ($infile =~ /^(.+)_(\d{3})_(.+)_[^_\.]{0,30}\.(.+)/) {
    # Matches 4 fields
    # field_ident_name.suff or field_ident_name_optionalsomething.suff
    @imgdet{qw(rsrcfld rsrcid rsrcname suffix)} = ($1, $2, $3, $4);
    $imgdet{'rsrcfld'} = 'prog' if ($imgdet{'rsrcfld'} eq 'program');
    
    @g_allfiles = (@g_infiles, @g_newfiles);
    $imgdet{'ordinal'} = nextOrdinal(\%imgdet, \@g_allfiles);
    $nold++;

    if (my $ret = $image->Read(filename => "${PROGCAPDIR}/${infile}")) {
      print "ret $ret, ERROR: Could not read $infile\n";
      next;
    } else {
      @imgdet{qw(width height)} = $image->Get('width', 'height');
    }
   } elsif ($infile =~ /^(.+)_(\d{3})_(.+)_(.+)_(.+)_(.+)\.(.+)/) {
    # Matches 7 fields
    # field_ident_name_ordinal_width_height.suff
    @imgdet{@FIELDNAMES} = ($1, $2, $3, $4, $5, $6, $7);
    $imgdet{'filename'} = $infile;
    $nnew++;
   } else {
     print "ERROR: file $infile does not match pattern!\n";
   }
  printHash(\%imgdet, $infile) if ($verbose);

  # Skip this file if its name hasn't parsed.
  unless (has_len($imgdet{'rsrcid'})) {
    print "ERROR: Name parse failure: no rsrcid for $infile\n";
    next;
  }

  # Now have in imgdet a record of a file that physically exists.
  # Required fields are rsrcfield, rsrcid, suffix, width, height.

  # Process the main image.  Opts describe output image.
  my %optsfull = (
    'suffix' => 'jpg',	# Use jpg format for all images.
    'path'   => '',	# Output image in main dir.
    'maxdim' => '',	# Use existing dimensions.
      );

  # Create small image in 'sm' directory.
  my %smopts = (
    'suffix' => 'jpg',
    'path'   => $SMALLDIR,
    'maxdim' => $SMALLDIM,
      );

  my %opts320 = (
    'suffix' => 'jpg',
    'path'   => $SMALLDIR,
    'maxdim' => $MEDDIM,
      );

  # Combine all opts and image details in an array for processing.
  my @opts = (\%optsfull, \%smopts, \%opts320);
  processImages(\%imgdet, \@opts);

#   last if (($nold + $nnew) > 5)
}

print "$nold old format, $nnew new format.\n";

# Process all size copies of an image at once, to ensure database 
# and names of the different sized files are in synch.

sub processImages {
  my ($imgdet, $opts) = @_;
  my %imgdet = %$imgdet;
  my @opts = @$opts;
  my $mainimagemoved = 0;

  # Details of actual image file on disk.
  my ($imgwidth, $imgheight, $imgsuff, $imgpath, $imgfilename, $imgrsrcname) = @imgdet{qw(width height suffix path filename rsrcname)};
  $imgpath = '' unless (has_len($imgpath));

  foreach my $opt (@opts) {
    # Each opt is a hash with target image details.
    my %opts = %{$opt};
    my ($newpath, $newsuff, $newmaxdim) = @opts{qw(path suffix maxdim)};
    my $disppath = (has_len($newpath)) ? $newpath : "<empty>";
    my $dispmax  = (has_len($newmaxdim)) ? $newmaxdim : "<empty>";
    print "-------------------- processImages(): (newpath $disppath, newsuff $newsuff, newmaxdim $dispmax) --------------------\n";

    # If the size, suffix and filename are correct, no action needed.
    my $imgdim = ($imgwidth > $imgheight) ? $imgwidth : $imgheight;
    my $imgdimok = ((not has_len($newmaxdim)) or ($imgdim <= $newmaxdim)) ? 1 : 0;
    my $imgsuffok = ($imgsuff eq $newsuff) ? 1 : 0;
    my $imgpathok = ($imgpath eq $newpath) ? 1 : 0;

    # Get rsrcname from database if present.  It will be used in the file name
    # and its presence (meaning rsrcnmae unreliable) is a flag to process this file.
    my $dbrsrcname = rsrcNameFor($imgdet{'rsrcfld'}, $imgdet{'rsrcid'});
    if (has_len($dbrsrcname) and ($dbrsrcname ne $imgdet{'rsrcname'})) {
      print "Changing rsrcname from $imgdet{'rsrcname'} to $dbrsrcname\n";
      $imgdet{'rsrcname'} = $dbrsrcname;
    }
    my $tempfilename = makeFileName(\%imgdet);
    my $imgok = ($tempfilename eq $imgfilename);
    $imgok = 0 if ($force);
    
#     print("processImages(OK = $imgok): filename $imgfilename, Dimension OK $imgdimok ($imgdim, $dispmax), Suffix OK $imgsuffok ($imgsuff, $newsuff), Path OK $imgpathok ($imgpath, $disppath)\n");

    if ($imgok and not has_len($newpath)) {
      # Ensure this (unaltered) image file is in the database.
      $imgdet{'scale'} = 'full';
      checkDBEntry($dbh, \%imgdet);
    } else {
      my $newimgdet = processImage(\%imgdet, $opt) ;
      
      # If this is the main image, add its new name to g_infiles.
      if (length($newpath) == 0) {
	$mainimagemoved = 1;
	my $newfilename = $newimgdet->{'filename'};
	unless (grep(/$newfilename/, (@g_infiles, @g_newfiles))) {
	  my $n = scalar(@g_newfiles);
	  push(@g_newfiles, $newfilename) ;
	  my $nn = scalar(@g_newfiles);
	  print "was $n now $nn files in g_newfiles: pushed $newfilename\n";
	} else {
	  print "file $newfilename already exists in g_newfiles\n";
	}
      }
    }
  }

  if ($mainimagemoved) {
    # Move the original files out of the directory so they don't get added again.
    my $srcfile  = "${PROGCAPDIR}/$imgfilename";
    my $destfile = "${PROGCAPDIR}/${ORIGDIR}/$imgfilename";
    if ($dummy) {
      print "rename($srcfile, $destfile)\n";
    } else {
      rename($srcfile, $destfile);
    }
  }

}

sub processImage {
  my ($imgdet, $opt) = @_;
  my %imgdet = %$imgdet;

  my %opts = %$opt;
  my ($newpath, $newsuff, $newmaxdim) = @opts{qw(path suffix maxdim)};
  print "------------------------------ processImage($imgdet{'filename'}) to dim $newmaxdim ------------------------------\n";
  my %newimgdet = %imgdet;

  # Scale if necessary.
  my $doscale = 0;
  my ($newwidth, $newheight);
  my $infilename = $imgdet{'filename'};
  if (has_len($newmaxdim)) {
    my ($width, $height);
    ($width, $height) = @imgdet{qw(width height)};
    my $istall = ($height > $width) ? 1 : 0;
    my $sfactor = ($istall) ? $newmaxdim / $height : $newmaxdim / $width;
    $newwidth = int($width * $sfactor);
    $newheight = int($height * $sfactor);
  
    # Modify imgdet so new file name can be created.
    @newimgdet{qw(width height scale)} = ($newwidth, $newheight, $newmaxdim);
    $doscale = 1;
  } else {
    $newimgdet{'scale'} = 'full';
  }
  $newimgdet{'suffix'} = $newsuff;
  $newimgdet{'filename'} = makeFileName(\%newimgdet);
  $newimgdet{'path'} = $newpath;
  $newpath = (has_len($newpath)) ? "${newpath}/" : "";
  my $outfile = "${PROGCAPDIR}/${newpath}$newimgdet{'filename'}";
  my $haveoutfile = (-f $outfile);

  if ($force or not $haveoutfile) {
    # Read, scale, write the image.
    my $image = Image::Magick->new;
    if (my $ret = $image->Read(filename => "${PROGCAPDIR}/${infilename}")) {
      print "ERROR: Could not read $infilename\n";
      return;
    }
    if ($dummy) {
      print "*** image->Scale(width => $newwidth, height => $newheight)\n" if ($doscale);
      print "*** image->Write($outfile)\n";
    } else {
      if ($doscale) {
	$image->Scale(width  => $newwidth, 
		      height => $newheight);
	# Medium-sized images get the magnifier icon.
	if (has_len($newmaxdim) and ($newmaxdim == $MEDDIM)) {
	  $image->Composite(image   => $magimage,
			    compose => 'Atop',
			    gravity => 'SouthEast');
	}
      }
      $image->Write($outfile);
    }
  } else {
    print "File $outfile already exists\n" if ($verbose);
  }

  # Ensure this file has a database entry.
  checkDBEntry($dbh, \%newimgdet);

  return \%newimgdet;
}

sub rsrcNameFor {
  my ($rsrcfld, $rsrcid) = @_;

  my $qstr = "select * from image";
  $qstr .= " where rsrcfld = '$rsrcfld'";
  $qstr .= " and rsrcid = '$rsrcid'";;

  my $qsh = dbQuery($dbh, $qstr);
  my $rsrcname = '';
  if (my $href = $qsh->fetchrow_hashref) {
    $rsrcname = $href->{'rsrcname'};
  }
  print "rsrcNameFor ($rsrcfld, $rsrcid) = $rsrcname\n";
  return $rsrcname;
}

sub makeFileName {
  my ($imgdet) = @_;
  my %imgdet = %$imgdet;

  my ($field, $ident, $name, $ordinal, $width, $height, $suff) = @imgdet{@FIELDNAMES};
  my $newname = "${field}_${ident}_${name}_${ordinal}_${width}_${height}.${suff}";
#   print "makeFileName returning $newname\n";
  return $newname;
}

# Find next ordinal for prog name and id matching this file.
sub nextOrdinal {
  my ($imgdet, $dirfiles) = @_;
  my %imgdet = %$imgdet;
  my @dirfiles = @$dirfiles;

  my ($rsrcid, $rsrcname) = @imgdet{qw(rsrcid rsrcname)};
  my $matchprefix = "${PROGPREFIX}${rsrcid}";
  my @matchfiles = grep(/^$matchprefix/, @dirfiles);

  my $ndir = scalar(@dirfiles);
  print scalar(@matchfiles) . " files of $ndir match $matchprefix: @matchfiles\n";

  my @matchords = ();
  foreach my $matchfile (@matchfiles) {
    if ($matchfile =~ /${PROGPREFIX}${rsrcid}_(.+)_(\d{1,2})_/) {
      push(@matchords, $2);
       print "*** match /${PROGPREFIX}${rsrcid}_(.+)_(d{1,2})_/): $matchfile: matchords now @matchords\n";
    } else {
       print "*** no match /${PROGPREFIX}${rsrcid}_(.+)_(d{1,2})_/): $matchfile: matchords now @matchords\n";
    }
  }

# Find the first non-filled ordinal number within or after @matchords.
  my $lastord = -1;
  foreach my $matchord (sort {$a <=> $b} @matchords) {
    if (($matchord - $lastord) > 1) {
      last;
    }
    $lastord++;
  }
  my $nextord = $lastord + 1;
  return $nextord;
}

# Remove from DB, records for files in given path not on disk.

sub checkDBRec {
  my ($dbh, $path) = @_;

  my $sqlstr = "select filename from image";
  if (has_len($path)) {
    $sqlstr .= " where path = '$path";
  } else {
    $sqlstr .= " where length(path) = 0";
  }
  my $sh = dbQuery($dbh, $sqlstr);
  my $aref = $sh->fetchall_arrayref;
  my $pathstr = (has_len($path)) ? "${path}/" : "";
  my @dbfilenames = @$aref;
  foreach my $dbrec (@dbfilenames) {
    my ($dbfilename) = @$dbrec;
    unless (-f "${PROGCAPDIR}/${pathstr}${dbfilename}") {
      print "Delete record in DB not present on disk: ${PROGCAPDIR}/${pathstr}$dbfilename\n";
      my $delstr = "delete from image where filename = '$dbfilename'";
      $delstr .= " and path = '$path'";
      if ($dummy) {
	print "$delstr\n";
      } else {
	dbQuery($dbh, $delstr);
      }
    }
  }
}

sub checkDBEntry {
  my ($dbh, $imgdet) = @_;

  # Condition string with 'and' is for query, with comma for insert (include filename).
  my $condstrand = conditionString($imgdet, "and", \@FIELDNAMES);
  my $condstrcom = conditionString($imgdet, ",", \@FIELDNAMES);

  # Check if it's already in database and add if not.
  my $querystr = "select * from image where $condstrand";
  my $sh = dbQuery($dbh, $querystr, $verbose);
  unless (my $imgrec = $sh->fetchrow_hashref) {
    # Record for this image does not exist - add it to the database.
    my $addstr = "insert into image set $condstrcom";
    if ($dummy) {
      print "Dummy: $addstr\n";
    } else {
      my $ash = dbQuery($dbh, $addstr, $verbose);
    }
  }
}

sub usage {
  print "Usage: makeimagefiles -[dfhv] <infiles>\n";
  print "  input file format: prog_999_name_9.ext\n";
  print "  Note that ordinal must be a numeral not a letter.\n";
}

#   my %imgdet = (
#     'rsrcfld'  => '',	# 'prog' etc.
#     'rsrcid'   => '',	# Integer
#     'rsrcname' => '',	# Free form program name
#     'ordinal'  => '',	# 0-indexed
#     'width'    => '',	# Pixels
#     'height'   => '',	# Pixels
#     'suffix'   => '',	# 'png' etc.
#     'filename' => '',	# field_ident_name_ordinal_width_height.suff
#       );

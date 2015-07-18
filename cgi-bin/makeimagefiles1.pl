#! /usr/bin/env perl
use warnings;

# makeimagefiles.pl
# Parse image capture file and rename files appropriately.
# Also check for / create and store thumbnail versions of same.
# Naming convention:
#   field_ident_name_ordinal_xdim_ydim.suff
#   field_ident_name_ordinal.suff
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
use FileUtilities;
use Opts qw($OPTS_NAME $OPTS_TYPE $OPTS_TEXT $OPTS_DFLT $OPTS_STRING $OPTS_BOOL);

use Image::Magick;
use Getopt::Std;
use DBI;

my $DB_IMAGING = 'db_imaging';
my $DB_TEST = 'db_test';
my $DB_DATABASE = 'db_database';
my $DB_TABLES = 'db_tables';
my %dbs = (
  $DB_IMAGING => {
    $DB_DATABASE => 'imaging',
    $DB_TABLES   => [qw(author format image monitor program related resource version)],
  },
  $DB_TEST => {
    $DB_DATABASE => 'test',
    $DB_TABLES   => [qw(dfile imagefile recon scan)],
  }
);

# Options.
my $OPT_IDENT   = 'i';
my $OPT_RSRC    = 'r';
my $OPT_NOCHK   = 'c';
my $usage_note = <<END_USAGE;
Valid image file name patterns:
   progname_0.suff (Requires option $OPT_IDENT)
   field_000_progname.suff
   field_000_progname_opttext.suff
   field_000_progname_0_width_height.suff
END_USAGE

my %allopts = (
  $OPT_IDENT => {
    $OPTS_NAME => 'ident',
    $OPTS_TYPE => $OPTS_STRING,
    $OPTS_TEXT => 'Resource ident number.',
    $OPTS_DFLT => '',
  },
  $OPT_RSRC => {
    $OPTS_NAME => 'resource',
    $OPTS_TYPE => $OPTS_STRING,
    $OPTS_TEXT => 'Resource table.',
    $OPTS_DFLT => 'prog',
  },
  $OPT_NOCHK => {
    $OPTS_NAME => 'no_check',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Do not check DB.',
  },
  $Opts::OPT_NOTE => {
    $OPTS_TEXT => $usage_note,
  },
);

my $opts = Opts::process_opts(\%allopts);
if ($opts->{$Opts::OPT_HELP}) {
  Opts::usage(\%allopts);
  exit;
}

my ($force, $verbose, $dummy) = @$opts{($OPT_FORCE, $OPT_VERBOSE, $OPT_DUMMY)};

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------
my $PROGCAPDIR   = "/home/ahc/idoimaging/public_html/img/cap/prog";    # Path for type 'prog'
my $TITLEDIR     = "/home/ahc/idoimaging/public_html/img/prog_title";  # Path for type 'title'

# Image file prefix defines type of file.
my $RSRC_PROG  = 'prog';
my $RSRC_TITLE = 'title';
my @RSRC = ($RSRC_PROG, $RSRC_TITLE);

# Constants for the different types of images.
my %image_details = (
  $RSRC_PROG => {
    'path'   => $PROGCAPDIR,
    'prefix' => $RSRC_PROG,
  },
  $RSRC_TITLE => {
    'path'   => $TITLEDIR,
    'prefix' => $RSRC_TITLE,
  },
    );
our $g_image_details = undef;

my $ICONDIR      = "/home/ahc/idoimaging/public_html/img/icon";
my $MAGICON      = "mag_big.png";
my $SMALLDIR     = "sm";
my $ORIGDIR      = "orig";
my $SMALLDIM     = 200;
my $MEDDIM       = 320;
my @FIELDNAMES   = (qw(rsrcfld rsrcid rsrcname ordinal width height suffix filename path scale));

# ------------------------------------------------------------
# Globals
# ------------------------------------------------------------
my $dbh = hostConnect();

# Take infiles from command line if given, else default.
our @g_infiles = ();
our @g_newfiles = ();

# Resource type comes from parameter or input files.
my $rsrc_type = analyze_input_files($opts);
$rsrc_type = $opts->{$OPT_RSRC} if ($opts->{$OPT_RSRC});
print "rsrc_type $rsrc_type\n";
exit unless ($rsrc_type);

my @image_detail_keys = keys(%image_details);
unless (grep(/$rsrc_type/, @image_detail_keys)) {
  print "ERROR: Image type $rsrc_type is not one of " . join(" ", keys(%image_details)) . "\n";
  exit;
}
print "image type: $rsrc_type\n";
$g_image_details = $image_details{$rsrc_type};

# Magnifier icon to place on small images.
our $magimage = Image::Magick->new;
if (my $err = $magimage->Read(filename => "${ICONDIR}/${MAGICON}")) {
  print "ERROR: Could not read ${ICONDIR}/${MAGICON}: $err\n";
  exit;
}

# Remove from database all records without a matching file.
checkDBRec($dbh, '', $rsrc_type) unless ($opts->{$OPT_NOCHK});

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
    print "$infile matches pattern 0\n";
    @imgdet{qw(rsrcfld rsrcid rsrcname suffix)} = ($1, $2, $3, $4);
    $imgdet{'rsrcfld'} = 'prog' if ($imgdet{'rsrcfld'} eq 'program');

    my @allfiles = (@g_infiles, @g_newfiles);
    $imgdet{'ordinal'} = nextOrdinal($dbh, \%imgdet, \@allfiles);
    $nold++;
  } elsif ($infile =~ /^(.+)_(\d{3})_(.+)_(.+)_(.+)_(.+)\.(.+)/) {
    # Matches 7 fields
    # field_ident_name_ordinal_width_height.suff
    print "$infile matches pattern 1\n";
    @imgdet{@FIELDNAMES} = ($1, $2, $3, $4, $5, $6, $7);
    $imgdet{'filename'} = $infile;
    $nnew++;
  } elsif ($infile =~ /^(.+)_(.{1,2})\.(.+)/) {
    # Matches 3 fields.
    # name_ordinal.suff
    print "$infile matches pattern 2\n";
    if (has_len($opts->{$OPT_IDENT})) {
      @imgdet{qw(rsrcname suffix)} = ($1, $3);
      @imgdet{qw(rsrcfld rsrcid)} = @$opts{($OPT_RSRC, $OPT_IDENT)};
      my @allfiles = (@g_infiles, @g_newfiles);
      $imgdet{'ordinal'} = nextOrdinal($dbh, \%imgdet, \@allfiles);
    }
  } else {
    print "ERROR: file $infile does not match pattern!\n";
  }

  unless (has_len($imgdet{'height'})) {
    my $inpath = $g_image_details->{'path'};
    if (my $ret = $image->Read(filename => "${inpath}/${infile}")) {
      print "ret $ret, ERROR: Could not read $infile from $inpath\n";
      next;
    } else {
      @imgdet{qw(width height)} = $image->Get('width', 'height');
    }
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

  # Create sub-directories if necessary.
  foreach my $sdir ($SMALLDIR, $ORIGDIR) {
    my $subdir = $g_image_details->{'path'} . "/${sdir}";
    print "mkdir($subdir)\n";
    mkdir($subdir);
  }

  # Combine all opts and image details in an array for processing.
  # Sizes to generate: title is <= 200 px.  prog is same plus 320 pix plus full size.
  my @opts;
  if ($rsrc_type =~ /$RSRC_TITLE/) {
    @opts = (\%smopts);    
  } else {
    @opts = (\%optsfull, \%smopts, \%opts320) ;
  }
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

  my $is_first_opt = 1;
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
#       if (length($newpath) == 0) {
      if ($is_first_opt) {
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
    $is_first_opt = 0;
  }

  if ($mainimagemoved) {
    # Move the original files out of the directory so they don't get added again.
    my $img_dir = $g_image_details->{'path'};
    my $srcfile  = "${img_dir}/$imgfilename";
    my $destfile = "${img_dir}/${ORIGDIR}/$imgfilename";
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
  print "------------------------------ processImage($imgdet{'filename'}) to max dim $newmaxdim ------------------------------\n";
  my %newimgdet = %imgdet;

  # Scale if necessary.
  my $doscale = 0;
  my ($newwidth, $newheight);
  my $infilename = $imgdet{'filename'};
  if (has_len($newmaxdim)) {
    my ($width, $height) = @imgdet{qw(width height)};
    my $istall = ($height > $width) ? 1 : 0;
    # Title images smaller than newmaxdim stay so.
    my $is_large_title = (($rsrc_type =~ /$RSRC_TITLE/) and (($height > $newmaxdim) or ($width > $newmaxdim)));
    my $sfactor = 1;
    if (($rsrc_type =~ /$RSRC_PROG/) or $is_large_title) {
      $sfactor = ($istall) ? $newmaxdim / $height : $newmaxdim / $width;
      $doscale = 1;
    }
    $newwidth = int($width * $sfactor);
    $newheight = int($height * $sfactor);
    print "*** doscale $doscale, sfactor $sfactor, newwidth $newwidth, newheight $newheight\n";
  
    # Modify imgdet so new file name can be created.
    @newimgdet{qw(width height scale)} = ($newwidth, $newheight, $newmaxdim);
  } else {
    $newimgdet{'scale'} = 'full';
  }
  $newimgdet{'suffix'} = $newsuff;
  $newimgdet{'filename'} = makeFileName(\%newimgdet);
  $newimgdet{'path'} = $newpath;
  $newpath = (has_len($newpath)) ? "${newpath}/" : "";
  my $img_dir = $g_image_details->{'path'};
  my $outfile = "${img_dir}/${newpath}$newimgdet{'filename'}";
  my $haveoutfile = (-f $outfile);

  if ($force or not $haveoutfile) {
    # Read, scale, write the image.
    my $image = Image::Magick->new;
    if (my $ret = $image->Read(filename => "${img_dir}/${infilename}")) {
      print "ERROR: Could not read $infilename\n";
      return;
    }
    if ($dummy) {
      print "*** image->Scale(width => $newwidth, height => $newheight)\n" if ($doscale);
      print "*** image->Write($outfile)\n";
    } else {
      if ($doscale) {
	$image->Scale(
          width  => $newwidth, 
          height => $newheight,
            );
	# Medium-sized images get the magnifier icon.
	if (has_len($newmaxdim) and ($newmaxdim == $MEDDIM)) {
	  $image->Composite(
            image   => $magimage,
            compose => 'Atop',
            gravity => 'SouthEast',
              );
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
# Seems you should do this by referencing the database, not the directory.

sub nextOrdinal {
  my ($dbh, $imgdet, $dirfiles) = @_;
  my %imgdet = %$imgdet;
  my @dirfiles = @$dirfiles;

  my ($rsrcid, $rsrcname) = @imgdet{qw(rsrcid rsrcname)};
  my $matchprefix = "${rsrc_type}_${rsrcid}";
  print "xxx matchprefix '$matchprefix'\n";

  my @matchfiles = grep(/^$matchprefix/, @dirfiles);

  my $ndir = scalar(@dirfiles);
  print scalar(@matchfiles) . " files of $ndir match $matchprefix: @matchfiles\n";

  my @matchords = ();
  foreach my $matchfile (@matchfiles) {
    if ($matchfile =~ /${rsrc_type}_${rsrcid}_(.+)_(\d{1,2})_/) {
      push(@matchords, $2);
       print "*** match /${rsrc_type}_${rsrcid}_(.+)_(d{1,2})_/): $matchfile: matchords now @matchords\n";
    } else {
       print "*** no match /${rsrc_type}_${rsrcid}_(.+)_(d{1,2})_/): $matchfile: matchords now @matchords\n";
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
  my $next_dir_ord = $lastord + 1;

  # Now get the highest ordinal from the database.
  my $str = "select max(ordinal) from image";
  $str   .= " where rsrcfld = '$rsrc_type'";
  $str   .= " and rsrcid = '$rsrcid'";
  my $sh = dbQuery($dbh, $str, 1);
  my $next_db_ord = -1;
  if (my ($max_ord) = $sh->fetchrow_array()) {
    $next_db_ord = $max_ord + 1;
    print "xxx Found max_ord $max_ord\n";
  }

  my $ret = ($next_dir_ord > $next_db_ord) ? $next_dir_ord : $next_db_ord;
  print "xxx next_dir_ord $next_dir_ord next_db_ord $next_db_ord returning $ret\n";
  return $ret;
}

# Remove from DB, records for files in given path not on disk.

sub checkDBRec {
  my ($dbh, $path, $rsrc_type) = @_;

  my $sqlstr = "select filename from image";
  $sqlstr   .= " where rsrcfld = '$rsrc_type'";
  if (has_len($path)) {
    $sqlstr .= " and path = '$path";
  } else {
    $sqlstr .= " and length(path) = 0";
  }
  my $sh = dbQuery($dbh, $sqlstr);
  my $aref = $sh->fetchall_arrayref;
  my $pathstr = (has_len($path)) ? "${path}/" : "";
  my @dbfilenames = @$aref;
  my $img_dir = $g_image_details->{'path'};
  foreach my $dbrec (@dbfilenames) {
    my ($dbfilename) = @$dbrec;
    unless (-f "${img_dir}/${pathstr}${dbfilename}") {
      print "Delete record in DB not present on disk: ${img_dir}/${pathstr}$dbfilename\n";
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

sub analyze_input_files {
  my ($opts) = @_;

  my @allfiles = ();
  foreach my $infile (@ARGV) {
    push(@allfiles, filesIn($infile));
  }

  my $infile_type = undef;
  if (defined($infile_type = $opts->{$OPT_RSRC})) {
    @g_infiles = @allfiles;
  } else {
    @g_infiles = grep(/^$RSRC_PROG|$RSRC_TITLE/, @allfiles);
    print scalar(@g_infiles) . " files matching '$RSRC_PROG' or '$RSRC_TITLE'\n";
    if (scalar(@g_infiles)) {
      # Analyze g_infiles to determine their type (prog or title).
      my %infile_types = ();
      foreach my $g_infile (@g_infiles) {
	my @bits = split(/_/, $g_infile);
	$infile_types{$bits[0]}++;
      }
      my @infile_types = keys %infile_types;
      foreach my $key (sort @infile_types) {
	print "$key: $infile_types{$key} files\n";
      }

      if (scalar(@infile_types) == 1) {
	$infile_type = $infile_types[0];
      } else {
	# Not all files have the same prefix.
	print "ERROR: Multiple prefixes in file names!\n";
      }
    }
  }
  return $infile_type;
}

sub use_age {
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

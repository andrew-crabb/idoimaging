#! /usr/bin/env perl
use warnings;

package FileUtilities;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(filesIn dirContents stringInFile isDir mkDir pathParts moveFile extnFiles makeDirs safeCopy safeMove isCopyOf fileContents writeFile fileExists fileHasSize storeImageFile columnFromFile fileStat dirStat recurFiles recurFileStat fileSizeStr summarizeFileList convertDirName);
@EXPORT = (@EXPORT, qw($FSTAT_NAME $FSTAT_PATH $FSTAT_HOST $FSTAT_SIZE $FSTAT_MOD $FSTAT_FNAME $FSTAT_VERBOSE $FSTAT_DIRISOK));
@EXPORT = (@EXPORT, qw($DIR_CYGWIN $DIR_CYGWIN_NEW $DIR_DOS));
@EXPORT = (@EXPORT, qw($OPT_VERBOSE $OPT_FORCE $OPT_DUMMY $OPT_NOMOVE));

use strict;
no strict 'refs';

use File::Copy;
use File::Find;

use Cwd;
use Cwd qw(abs_path);
use Sys::Hostname;
use File::Basename;
use File::Spec;
use File::Spec::Unix;

# ============================================================
# Option hash key values
# ============================================================

our $OPT_VERBOSE = 'verbose';
our $OPT_FORCE   = 'force';
our $OPT_DUMMY   = 'dummy';
our $OPT_NOMOVE  = 'nomove';
    

# ============================================================
# Exported hash key names.
# ============================================================

our $FSTAT_VERBOSE  = 'verbose';
our $FSTAT_DIRISOK  = 'dir_is_ok';
our $FSTAT_NAME     = 'name';
our $FSTAT_PATH     = 'path';
our $FSTAT_HOST     = 'host';
our $FSTAT_SIZE     = 'size';
our $FSTAT_MOD      = 'modified';
our $FSTAT_FNAME    = '_fullname';

our $DIR_CYGWIN     = 'cygwin';
our $DIR_CYGWIN_NEW = 'cygwin_new';
our $DIR_DOS        = 'dos';

sub stringInFile {
  my ($filename, $offset, $length, $string) = @_;

  # Occasionally called with an object reference.
 if (ref($filename)) {
#    print "FileUtilities::stringInFile(): Called with ref " . ref($filename) . "\n";
#    dumpStack();
   return 0;
 }
  my $buff = "";
  open(INFILE, '<', $filename) or die("Died opening $filename");
  seek(INFILE, $offset, 0);
  read(INFILE, $buff, $length);
  close(INFILE);
  return ($buff eq $string) ? 1 : 0;
}


# Return all lines in given file as array or scalar depending on context.
#   start: Byte (scalar) or line (array) to start at.
#   len:   Number of bytes or lines to return, or end if omitted.
sub fileContents {
  my ($infile, $start, $len) = @_;
  
  open(INFILE, '<', $infile) or return ();
  chomp(my @arr = (<INFILE>));
  if (wantarray()) {
    if (has_len($start)) {
      $len = (has_len($len)) ? $len : ($#arr - $start + 1);
      return(@arr[$start..($start + $len)]);
    } else {
      return @arr;
    }
  } else {
    my $ret = join("\n", @arr);
    if (has_len($start)) {
      $len = (has_len($len)) ? $len : (length($ret) - $start);
      return substr($ret, $start, $len);
    } else {
      return $ret;
    }
  }
}

# Write file of given name with given contents.
# If contents are array ref, print newline-delimited.
# Return 0 on success, else 1.

sub writeFile {
  my ($outfile, $contents) = @_;

  if (ref($contents) eq "ARRAY") {
    unless ($contents->[0] =~ /\n/) {
      $contents = join("\n", @{$contents}) . "\n";
    } else {
      $contents = join("", @{$contents}) . "\n";
    }
  }
  unless (open(OUTFILE, '>', $outfile)) {
    print "ERROR FileUtilities::writeFile(): Could not open $outfile\n";
    return 1;
  }
  print OUTFILE $contents;
  close(OUTFILE);
  return 0;
}

# Return array of recursive find of files within given dir.

sub recurFiles {
  my ($dirname) = @_;

  return () unless (has_len($dirname));
  my (@contents) = ();
  find sub { push(@contents, $File::Find::name) if -f }, $dirname;
  return @contents;
}

# Return hash by full filename of fileStat structures.

sub recurFileStat {
  my ($dirname) = @_;

  my @contents = recurFiles($dirname);
  my %details = ();
  foreach my $file (@contents) {
    my $dptr = fileStat($file);
    $details{$dptr->{$FSTAT_FNAME}} = $dptr;
  }
  return %details;
}

# Return 1 if given arg is dir or ptr to dir, else 0.

sub isDir {
  my ($dirname) = @_;
  my $isdir = 0;
  
  if (-d $dirname) {
    # It's a dir.
    $isdir = 1;
  } elsif (-l $dirname) {
    # It's a symlink possibly to a dir.
    if (defined(my $destname = readlink($dirname))) {
      if (-d $destname) {
	$isdir = 1;
      }
    }
  }
#    print "FileUtilities::isDir($dirname) returning $isdir\n";
}

# Make given dir including its path.  Mode applied only to leaf.  Return path.

sub mkDir {
  my ($dir, $mode) = @_;
  
  if ($dir =~ /:/) {
    print "*** mkdir(convert $dir)\n";
    $dir = convertDirName($dir)->{'cygwin_new'} ;
    print "*** mkdir(now $dir)\n";
  }
  my $wd = ($dir =~ /^\//) ? "" : cwd();
  return ($dir) if (-d $dir);
  $mode = 0755 unless (has_len($mode));
  my @bits = split(/\//, $dir);
  my $path = $wd;
  foreach my $bit (@bits) {
    next unless (length($bit));
    $path = "${path}/${bit}";
    unless (isDir($path) or mkdir($path, 0755)) {
      print "FileUtilities::mkDir($path) failed\n";
      return "";
    }
  }
  chmod($mode, $path);
  return $path;
}

# pathParts: Return (path, filename) for given full file.

sub pathParts {
  my ($fullname, $verbose) = @_;
  $verbose = 0 unless (has_len($verbose) and $verbose);

  my ($path, $filename) = ("", "");
  if (has_len($fullname)) {
    my (@bits) = split(/\//, $fullname);
    my $nbits = scalar(@bits);
    if (-d $fullname) {
      $path = ($nbits > 1) ? join('/', @bits[0..($nbits - 1)]) : $bits[0];
    }
    else {
      $path = ($nbits > 2) ? join('/', @bits[0..($nbits - 2)]) : ".";
      $filename = $bits[@bits - 1];
    }
  }
  if ($verbose) {
    print "FileUtilities::pathParts($fullname) returning($path, $filename)\n";
  }
  return ($path, $filename);
}

# Return array of files (only files) in given file/directory.
#   infile: File/dir to examine.
#   level:  Level to recurse to (default 0 = current level).

sub filesIn {
  my ($infile, $level) = @_;
  $level = 0 unless (defined($level));
  
#   print "FileUtilities::filesIn($infile, $level)\n";
  my $thislevel = 0;
  my @retfiles = ();
  if (-f $infile) {
    push(@retfiles, $infile);
  } elsif (-d $infile) {
    # infile is a directory: read it or recurse depending on level.
    $infile =~ s/\/$//;
    my @dirfiles = dirContents($infile);
    foreach my $dirfile (@dirfiles) {
      my $fullfile = "${infile}/${dirfile}";
      if (-f $fullfile) {
	push(@retfiles, $fullfile);
      } elsif ($thislevel <= $level) {
	push(@retfiles, filesIn($fullfile, $level - 1));
      }
    }
  }
#   print "FileUtilities::filesIn($infile, $level) returning @retfiles\n";
  return @retfiles;
}

# Return list of files in given directory.

sub dirContents {
  my ($path, $includepath) = @_;

  return($path) if (-f $path);
  opendir (DIR, $path) or return ();
  my @dirfiles = grep(/[^\.]/, readdir(DIR));
  closedir(DIR);

  @dirfiles = sort @dirfiles;
  if ($includepath) {
    my @fullfiles = ();
    foreach my $dirfile (@dirfiles) {
      push(@fullfiles, "${path}/${dirfile}");
    }
    @dirfiles = @fullfiles;
  }
#   print "FileUtilities::dirContents() returning " . join(" ", @dirfiles) . "\n";
  return(@dirfiles);
}

# Move source to dest, and delete source, if successful and not same file.
# Return: 0 on success, else 1.

sub moveFile {
  my ($src, $dst) = @_;
  my $ret = 0;

  print "FileUtilities::moveFile($src, $dst)\n";
  if ($ret = copy($src, $dst)) {
    if (-s $src == -s $dst) {
      if ((stat($src))[1] != (stat($dst))[1]) {
	unlink($src);
      }
    }
  }
  return $ret;
}

# Return list of files optionally ending with given extn in directory.
# case: Search is case sensitive if set (default: 1).

sub extnFiles {
  my ($dir, $extn, $case) = @_;
  $case = 1 unless (defined($case) and length($case));
  my @retn;

  opendir(DIR, $dir) or return ();
  my @allfiles = readdir DIR;
  closedir(DIR);
  if ($case) {
    (@retn) = (defined($extn)) ? grep(/${extn}$/, @allfiles) : @allfiles;
  } else {
    (@retn) = (defined($extn)) ? grep(/${extn}$/i, @allfiles) : @allfiles;    
  }
  return(@retn);
}

# Make dirs given in hash.
# Return: 0 on success, else 1.
# Success includes directories already exist and are writeable.

sub makeDirs {
  my ($pptr, $verbose) = @_;
  $verbose = 0 unless (has_len($verbose));
  my %path = %$pptr;
  my $ret = 0;

  # Avoid zero-length fields.
  my %p = ();
  foreach my $key (keys %path) {
    $p{$key} = $path{$key} if (defined($path{$key}));
  }
  
  foreach my $key (sort {length($p{$a}) <=> length($p{$b})} keys %p) {
    # Certain directories need not exist and may be empty.
    next if ($key =~ /image|backup|existing/);
    my $path = $p{$key};
    print "FileUtilities::makeDirs(): $path\n" if ($verbose);
    mkDir($path, 0755) unless ($verbose > 1);
  }
}

sub checksum {
  my ($file, $verbose) = @_;

  my $sump = '';
  foreach my $sums ("/usr/local/bin/sum", "/usr/bin/sum") {
    $sump = $sums if (-f $sums);
  }
  my $sum = '';
  if (length($sump)) {
    $sum = `$sump $file`;
    my @sum = split(/\s+/, $sum);
    $sum = $sum[0];
#     print "FileUtilities::checksum($file) returning $sum\n" if ($verbose);
  }
  return $sum;
}

# Return 1 if dest is a copy of src, else 0.
# Definition of 'copy': Exact same file, differnent inode.

sub isCopyOf {
  my ($src, $dest, $verbose) = @_;
  my $ret = 0;
  my $s = "FileUtilities::isCopyOf";

  $verbose  = 0;

  print "$s($src, $dest\n" if ($verbose);
  if (-s $src and -s $dest) {
    my @srcstat = stat($src);
    my @deststat = stat($dest);
    if ($srcstat[7] == $deststat[7]) {
      # Src and dest both exist, both same size.
      if ($srcstat[1] != $deststat[1]) {
	# Src and dest are not the same inode.
	my ($ssum, $dsum);
	# Don't checksum files larger than 100 MB (takes forever).
	if ($srcstat[7] < 100000000) {
	  $ssum = checksum($src, $verbose);
	  $dsum = checksum($dest, $verbose);
	} else {
	  $ssum = $dsum = 1;
	}
	if ($ssum == $dsum) {
	  # Src and dest same file, different inode: success.
	  # This is the only success if dest exists already.
	  print "${s}: Dest identical($ssum, $dsum): Success\n" if ($verbose);
	  $ret = 1;
	} else {
	  print "${s}: Dest exists (different sum): Fail\n" if ($verbose);
	}
      } else {
	print "${s}: src and dest same inode: Fail\n" if ($verbose);
      }
    } else {
      print "${s}: Dest different size: Fail.\n" if ($verbose);
    }
  } else {
    print "${s}: Dest non existant: Fail.\n" if ($verbose);
  }
  return $ret;
}

# Copy file from src to dest.
# Returns: 0 on success, else 1.
# Success asserts:
# - dest has same size and checksum as src.
# - Safe to delete src.
# Success includes:
# - dest file already exists, same as src.
# Fail includes:
# - dest file already exists, different than src.
# - dest is same file (inode) as src.

sub safeCopy {
  my ($src, $dest, $verbose) = @_;
  my $ret = 1;		# Default is fail.
  my $s = "FileUtilities::safeCopy";
  
  if (-s $src ) {
    # Src file exists.
    my ($pname, $fname) = pathParts($dest);
    mkDir($pname) or return(1);

    if (-s $dest) {
      # Dest file exists: Only success is exact copy different inode.
      $ret = 0 if (isCopyOf($src, $dest, $verbose));
    } else {
      # Dest does not exist.
      $ret = 0 if (copy($src, $dest) and isCopyOf($src, $dest));
#       printf("${s}: copy %s\n", ($ret) ? "Fail" : "Success") if ($verbose);
    }
  }
   print "${s}($src, $dest) returning $ret\n" if ($verbose);
  return $ret;
}

# Move file from src to dest.
# Returns: 0 on success, else 1.
# Success asserts:
# - dest has same size and checksum as src had.
# - Src is deleted.
# Success can include:
# - dest file already exists, same as src (different inode).
# Fail includes:
# - dest file already exists, different than src.
# - dest is same file (inode) as src.

sub safeMove {
  my ($src, $dest, $verbose) = @_;
  my $ret = 1;
  my $err = "";

#   my $la = length($dest);
#   $dest =~ s/[^a-zA-Z0-9\/\_\.]//g;
#   my $lb = length($dest);  
#   print "FileUtilities::safeMove(): la $la lb $lb\n";

  if (isCopyOf($src, $dest) and unlink($src)) {
    # Dest exists and src has been deleted.
    print "FileUtilities::safeMove($src, $dest) already exists\n" if ($verbose);
    $ret = 0;
  } else {
    # Dest if it exists is a different file.
    my $s = (-s $dest);
    $s = 0 unless (defined($s));
    if ($s == 0) {
      if (move($src, $dest)) {
	$ret = 0;
      } else {
	$err = " ($!)";
      }
    }
  }
  print "FileUtilities::safeMove($src, $dest) returning $ret$err\n" if ($verbose);
  return $ret;
}

# Return 1 if files exist with nonzero size, else 0.

sub fileExists {
  my (@filenames) = @_;
  my $ret = 1;

  foreach my $filename (@filenames) {
    (has_len($filename) and -e $filename and -s $filename) or $ret = 0;
  }
  return $ret;
}

# Return 1 if file exists and has given size, else 0.
# Special case: insize = 1 => accept any size > 0.

sub fileHasSize($$;$) {
  my ($infile, $insize, $verbose) = @_;

  my $ret = 0;
  if ($insize == 1) {
    $ret = ((-f $infile) and ((-s $infile) >= 1)) ? 1 : 0;
    print("FileUtilities::fileHasSize($infile, >= $insize) returning $ret\n") if ($verbose);
  } else {
    $ret = ((-f $infile) and ((-s $infile) == $insize)) ? 1 : 0;
    print("FileUtilities::fileHasSize($infile, == $insize) returning $ret\n") if ($verbose);
  }
  return $ret;
}

# Return given column from input file.

sub columnFromFile {
  my ($infile, $indx) = @_;
  my @ret;

  my @lines = fileContents($infile);
  foreach my $line (@lines) {
    $line =~ s/^\s+//;
    my @bits = split(/\s+/, $line);
    push(@ret, $bits[$indx]);
  }
  return @ret;
}

# Return ptr to hash of file details.

sub fileStat {
  my ($infile, $verbose) = @_;

  # verbose can double as a pointer to a hash of arguments.
  my $dir_is_ok = 0;
  if (ref($verbose)) {
    my %opts = %$verbose;

    $verbose = (defined($opts{$FSTAT_VERBOSE}) and $opts{'verbose'}) ? 1 : 0;
    $dir_is_ok = 1 if (defined($opts{$FSTAT_DIRISOK}) and $opts{'dir_is_ok'});
  }
  $verbose = 0 unless ( has_len( $verbose ));

  return undef unless (has_len($infile));
  $infile =~ s/^\s+//;
  $infile =~ s/\s+$//;
  my $host = hostname();

  return undef unless (-f $infile or ($dir_is_ok and -d $infile));
  my @stat = stat($infile);
  my $mod = $stat[9];
  my $siz = $stat[7];

  # Path of the file depends on infile having absolute or relative path.
  my $absname = File::Spec->rel2abs($infile);
  $absname = abs_path($absname);
  my ($fname, $fpath) = fileparse($absname);
  $fpath =~ s/\/$//;

  # dir_is_ok means it MAY be called on a dir.
  my $path = $fpath;
  $path .= "/${fname}" if ($dir_is_ok and (-d "${fpath}/${fname}"));

  # Fields prefixed with '_' are not in database.
  my %ret = (
    $FSTAT_NAME  => $fname,
    $FSTAT_PATH  => $path,
    $FSTAT_HOST  => $host,
    $FSTAT_SIZE  => $siz,
    $FSTAT_MOD   => $mod,
    $FSTAT_FNAME => "${fpath}/${fname}",
      );
  # Note: DB record has these fields plus checksum, tapedate, tapenum, deleted.
  printHash(\%ret, "FileUtilities::fileStat($infile)") if ($verbose );
  return \%ret;
}

sub dirStat {
  my ($indir, $verbose) = @_;

  my %rfiles = recurFileStat($indir);
  my $totsize = 0;
  my $lastmod = 0;
  foreach my $file (keys %rfiles) {
    my $fstat = $rfiles{$file};
    $totsize += $fstat->{$FSTAT_SIZE};
    $lastmod = ($fstat->{$FSTAT_MOD} > $lastmod) ? $fstat->{$FSTAT_MOD} : $lastmod;
  }
  my %ret = (
    $FSTAT_NAME  => $indir,
    $FSTAT_PATH  => $indir,
    $FSTAT_HOST  => hostname(),
    $FSTAT_SIZE  => $totsize,
    $FSTAT_MOD   => $lastmod,
    $FSTAT_FNAME => $indir,
      );
  printHash(\%ret, "FileUtilities::dirStat($indir)") if ($verbose);
  return \%ret;
}

sub fileSizeStr {
  my ($bytes) = @_;
  my $ret = '';
  
  if ($bytes >= 1000000000) {
    $ret = sprintf "%6.1f GB", $bytes / 1000000000;
  } elsif ($bytes > 1000000) {
    $ret = sprintf "%6.1f MB", $bytes / 1000000;
  } elsif ($bytes > 1000) {
    $ret = sprintf "%6.1f kB", $bytes / 1000;
  } else {
    $ret = "$bytes bytes";
  }
  return trim($ret);
}

# Given list of full file names, return summary hash of (dirname => filecount).

sub summarizeFileList {
  my (@files) = @_;

  my %ret = ();
  foreach my $file (@files) {
    my @bits = split(/\//, $file);
    my $nbits = scalar(@bits);
    my $path = join("/", @bits[0..($nbits - 2)]);
    my $fname = $bits[$nbits - 1];
    $ret{$path}++;
  }
  foreach my $kpath (sort keys %ret) {
    printf "%6d files in %s\n", $ret{$kpath}, $kpath;
  }
  return %ret;
}

# Given a directory name in either format, returns both formats.
#   'cygwin' : /cygdrive/a/foo
#   'dos'    : a:/foo

sub convertDirName {
  my ($indir, $verbose) = @_;

  my $drive = '';
  my $rest = '';
  my ($cygwinpath, $dospath) = ('', '');
  if ($indir =~ m|^/cygdrive/(\w)/(.+)|) {
    # /cygdrive/F/foo/bar
    $drive = $1;
    $rest = $2;
  } elsif ($indir =~ m|^/(\w)/(.+)|) {
    # /F/foo/bar
    $drive = $1;
    $rest = $2;
  } elsif ($indir =~ m|^(\w):/(.+)|) {
    # F:/foo/bar
    $drive = $1;
    $rest = $2;
  } elsif ($indir =~ m|^/(\w{3,})/(.+)|) {
    # /unix/style/directory
    $drive = $1;
    $rest = $2;
  }

  my %ret = (
    $DIR_CYGWIN     => "\/cygdrive\/${drive}\/${rest}",
    $DIR_CYGWIN_NEW => "\/${drive}\/${rest}",
    $DIR_DOS        => "${drive}:/${rest}",
      );
  printHash(\%ret, "convertDirName($indir)") if ($verbose);
  return \%ret;
}

1;

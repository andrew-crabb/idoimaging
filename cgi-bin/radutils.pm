#! /usr/local/bin/perl -w

package radutils;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(authName sortHashVal truncateHashVals selectedVals listPrereq hostConnect formatList nextIdent comment dbRecord linkCountIcon fmtAuthorName dbQuery nextIndex addVersionRecord loggedInIdent monitoredPrograms validDate relatedPrograms truncateString getEnv listHashMembers makeDir dumpParams printTitle printStartHTML urlIcon listParts relatedProgramsTable programsHavingSpeciality sortedcomb makeTableBinary makeemailicon valToSQL valToTDedit valToTDsumm sortedHeadingRow getParams definedVal isNonZero makeProgramLink getSecondaryScreenCaptures printRowWhite printRowWhiteCtr createAdvertTable printPageIntro makeIfaceCell printToolTips addCvars make_cvars_text conditionString getCaptureImages randomSubset allProgNames makeRsrcIcon write_file timeNowHash make_monitor_details is_admin_or_cli);
@EXPORT = (@EXPORT, (qw(%resourcetype %formats %db_program_fields %relationships)));
@EXPORT = (@EXPORT, (qw($DB_INT $DB_CHR $DB_BEN $DB_DAT $DB_FLT)));
@EXPORT = (@EXPORT, (qw($KEY_CGI $KEY_CGI $KEY_IDENT $KEY_URLSTAT $KEY_TABLE $KEY_FIELD $KEY_URL $KEY_TIP0 $KEY_TIP1 $KEY_TIPNA)));
@EXPORT = (@EXPORT, (qw($REL_ISNOW $REL_ISPARTOF $REL_REMOVED $REL_DELREL)));
@EXPORT = (@EXPORT, (qw($RES_DOC $RES_TUT $RES_SIT $RES_DAT $RES_LNK $RES_IMG $RES_BLO $RES_REV $RES_DEM $RES_NOT)));
@EXPORT = (@EXPORT, (qw($STR_FINDER $STR_PROGRAMS $STR_PROGRAM $STR_PEOPLE $STR_FORMATS $STR_SEARCH)));
@EXPORT = (@EXPORT, (qw($STR_RESOURCES $STR_LIST_VERSIONS $STR_USER_HOME)));
@EXPORT = (@EXPORT, (qw($STR_EDIT_AUTHOR $STR_EDIT_RESOURCE $STR_ADD_MONITOR $STR_EDIT_PROGRAM $STR_RM_PROGRAM $STR_REDIRECT $STR_EDIT_DATA $STR_DO_EDIT $STR_DO_EDIT_RES $STR_DO_EDIT_AUTH $STR_EDIT_RELAT)));
@EXPORT = (@EXPORT, (qw($OBFUSCATOR $OBF_USERID)));
# Program monitor icon, text, and tip text.
# @EXPORT = (@EXPORT, (qw($TIP_MONITOR_ON $TIP_MONITOR_OFF $TIP_MONITOR_ADD $TIP_MONITOR_NA $TIP_MONITOR_LOGIN $ICON_NA $ICON_ADD $ICON_REM $ICON_OK $ACT_ADD $ACT_REM)));
@EXPORT = (@EXPORT, (qw($MON_URL $MON_ICON $MON_CVARS $MON_TIPCL $MON_TEXT)));


my $google_snippet =<<EOD;
<script type="text/javascript">

    var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-2402704-1']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
EOD

my $google_api_load = <<EOD;
      <script src="https://www.google.com/jsapi?key=ABQIAAAAeyo6aT6F59as6OD6qBYrXxQgvVD5Xa5VYwliZWIt2cAzPhwOdBRoj8eyNonQS2hVO-0P3gA0wPmW3w" type="text/javascript"></script>
      <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
EOD
# There"s a quote mark here just to fix the Perl syntax highlighting...


# @EXPORT = (@EXPORT, (qw($IMG_SMALLDIR $IMG_SMALLDIM $IMG_MEDDIM)));

use bigint;
use POSIX qw(log10);
use strict;
no strict 'refs';

use Carp;
use FindBin qw($Bin);
use lib $Bin;

use FileUtilities;
use Utility;
use Userbase;
use constants;

# ============================================================
#                        Constants
# ============================================================

our $TABLEWIDTH = 920;
our $HALFWIDTH  = 460;
our $OBFUSCATOR = 314;		# Multiply user ids by this when used in URLs.
our $OBF_USERID = 'obus';	# 'Obfuscated Userid'.  Parameter name.

# Image dimensions.
our $IMG_SMALLDIR = "sm";
our $IMG_SMALLDIM = 200;
our $IMG_MEDDIM   = 320;

our $DB_INT = 0;	# Scalar integer.
our $DB_CHR = 1;	# Character string (0 length = limitless).
our $DB_BEN = 2;	# Binary encoded (2**n). Encodes multiple values.
our $DB_DAT = 3;	# Date
our $DB_FLT = 4;	# Float
our $DB_ORD = 5;	# Ordinal (indexes key-named hash). Encodes single value.
our $DB_CAP = 6;	# Screen cap (img/capture/$table/${field}_${ident}_$name).

# Policy for every hash %db_xxx or %tbl_yyy having array members: there must be a 
# corresponding array named @db_xxx_index of constants denoting element order 
# within the hash member array.

our $FLD_NDX = 0;	# Element is a numerial index of element position in hash.
our $FLD_HKY = 1;	# Element is a hash key.
our $FLD_NAM = 2;	# Element is a field name.
our $FLD_TYP = 3;	# Element is a numerical constant fileld type.
our $FLD_LEN = 4;	# Element is max length (0 for CHR = limitless).
our $FLD_SLN = 5;	# Element is short summary length for display.
our $FLD_DSC = 6;	# Element is a textual description.

# ------------------------------------------------------------
# Hash keys for parameters.
# ------------------------------------------------------------

our $KEY_CGI     = 'cgi';
our $KEY_IDENT   = 'ident';
our $KEY_URL     = 'url';
our $KEY_URLSTAT = 'urlstat';
our $KEY_TABLE   = 'table';
our $KEY_FIELD   = 'field';
our $KEY_TIP0    = 'tip_0';
our $KEY_TIP1    = 'tip_1';
our $KEY_TIPNA   = 'tip_na';

# Fields in database tables: (index, key, name, type, size if applicable, length in summary).
our (%db_program, @db_program_index, %db_data, @db_data_index);

@db_program_index = ($FLD_NDX, $FLD_HKY, $FLD_NAM, $FLD_TYP, $FLD_LEN, $FLD_SLN);
%db_program = (
  'ident'         => ['Identifier'   , $DB_INT,   0],
  'name'          => ['Name'         , $DB_CHR,  30],
  'summ'          => ['Summary'      , $DB_CHR,   0],
  'descr'         => ['Description'  , $DB_CHR,   0],
  'rev'           => ['Revision'     , $DB_CHR,  10],
  'rdate'         => ['Rev Date'     , $DB_DAT,   0],
  'auth'          => ['Author'       , $DB_ORD,   0],
  'plat'          => ['Platform'     , $DB_BEN,   0],
  'lang'          => ['Language'     , $DB_BEN,   0],
  'func'          => ['Function'     , $DB_BEN,   0],
  'prer'          => ['Prerequsites' , $DB_BEN,   0],
  'srcurl'        => ['Source URL'   , $DB_CHR, 100],
  'srcstat'       => ['Src URL Stat' , $DB_ORD,   0],
  'homeurl'       => ['Home URL'     , $DB_CHR, 100],
  'linkcnt'       => ['Link Count'   , $DB_INT,   0],
  'revurl'        => ['Revision URL' , $DB_CHR, 100],
  'revstr'        => ['Rev string'   , $DB_CHR,  40],
  'revtrust'      => ['Rev URL flag' , $DB_ORD,   0],
  'urlstat'       => ['Home URL Stat', $DB_ORD,   5],
  'counturl'      => ['Linkcount URL', $DB_CHR, 100],
  'readfmt'       => ['Input Format' , $DB_BEN,   0],
  'writfmt'       => ['Output Format', $DB_BEN,   0],
  'adddate'       => ['Add Date'     , $DB_DAT,   0],
  'visdate'       => ['Visit date'   , $DB_DAT,   0],
  'capture'       => ['Screen Cap'   , $DB_CAP,  40],
  'interface'     => ['Interface'    , $DB_BEN,   0],
  'feature'       => ['Features'     , $DB_BEN,   0],
  'category'      => ['Speciality'   , $DB_BEN,   0],
  'percentile'    => ['Percentile'   , $DB_INT,   0],
  'homestr'       => ['Home String'  , $DB_CHR, 100],
  'installer'     => ['Installer'    , $DB_INT,   0],
  'obtain'        => ['Obtain'       , $DB_INT,   0],
  'audience'      => ['Audience'     , $DB_INT,   0],
  'rank_activity' => ['Activity'     , $DB_INT,   0],
  'rank_appear'   => ['Appearance'   , $DB_INT,   0],
  'rank_doc'      => ['Documentation', $DB_INT,   0],
  'rank_scope'    => ['Project scope', $DB_INT,   0],
  'rank_overall'  => ['Rank Overall' , $DB_INT,   0],
    );

@db_data_index = ($FLD_NDX, $FLD_HKY, $FLD_NAM, $FLD_TYP, $FLD_LEN, $FLD_SLN);
%db_data = (
  'ident'    => [ 0, 'ident'   ,'Identifier' , $DB_INT,   0,   4],
  'summ'     => [ 1, 'summ'    ,'Summary'    , $DB_CHR,   0,  30],
  'descr'    => [ 2, 'descr'   ,'Description', $DB_CHR,   0,   0],
  'filename' => [ 3, 'filename','File Name'  , $DB_CHR,  80,  20],
  'fileurl'  => [ 4, 'fileurl' ,'File URL'   , $DB_CHR, 100,  20],
  'filesize' => [ 5, 'filesize','File Size'  , $DB_INT,   0,   0],
  'capture'  => [ 6, 'capture' ,'Screen Cap' , $DB_CAP,  40,   0],
  'auth'     => [ 7, 'auth'    ,'Author'     , $DB_INT,   0,   0],  # ORD
  'modality' => [ 8, 'modality','Modality'   , $DB_ORD,   0,   6],
  'species'  => [ 9, 'species' ,'Species'    , $DB_ORD,   0,   6],
  'anatomy'  => [10, 'anatomy' ,'Anatomy'    , $DB_ORD,   0,   6],
  'scanner'  => [11, 'scanner' ,'Scanner'    , $DB_ORD,   0,   0],
  'xpix'     => [12, 'xpix'    ,'X Pixels'   , $DB_INT,   0,   0],
  'ypix'     => [13, 'ypix'    ,'Y Pixels'   , $DB_INT,   0,   0],
  'zpix'     => [14, 'zpix'    ,'Z Pixels'   , $DB_INT,   0,   0],
  'xdim'     => [15, 'xdim'    ,'X Dim'      , $DB_FLT,   0,   0],
  'ydim'     => [16, 'ydim'    ,'Y Dim'      , $DB_FLT,   0,   0],
  'zdim'     => [17, 'zdim'    ,'Z Dim'      , $DB_FLT,   0,   0],
  'bitpix'   => [18, 'bitpix'  ,'Bits/Pix'   , $DB_ORD,   0,   0],
  'format'   => [19, 'format'  ,'Format'     , $DB_ORD,   0,   0],
  'xfersyn'  => [20, 'xfersyn' ,'XferSyn'    , $DB_ORD,   0,   0],
  'endian'   => [21, 'endian'  ,'Endian'     , $DB_ORD,   0,   0],
    );

# Sort order for column headings.

our ($NN, $AS, $DE) = (0, 1, 2);  # Sort order None, Ascending, Descending.
our %hdgorder = ($NN => '',
		 $AS => 'asc',
		 $DE => 'desc');

# %tbl_xxx hashes are used to index ordinal values.  They store one value.
# 0 case is reserved for empty '' value which is added when needed.
# A hash named %tbl_FLD must exist for each DB_ORD type field keynamed FLD.

our (%tbl_species, @tbl_species_index, %tbl_modality, @tbl_modality_index, %tbl_anatomy, @tbl_anatomy_index, %tbl_xfersyn, @tbl_xfersyn_index);

@tbl_species_index = ($FLD_NAM);
%tbl_species = (
  1 => 'Human',
  2 => 'Mouse',
  3 => 'Dog',
  4 => 'Monkey',
  5 => 'Baboon',
  6 => 'Rat',
    );

@tbl_modality_index = ($FLD_NAM);
%tbl_modality = (
  1 => 'CT',
  2 => 'MRI',
  3 => 'FMRI',
  4 => 'PET',
  5 => 'SPECT',
  6 => 'US',
  7 => 'XRAY',
    );

@tbl_anatomy_index = ($FLD_NAM);
%tbl_anatomy = (
  1 => 'Head',
  2 => 'Brain',
  3 => 'Thoracic',
  4 => 'Cardiac',
  5 => 'Lung',
  6 => 'Breast',
  7 => 'Arm',
  8 => 'Leg',
  9 => 'Wholebody',
    );

@tbl_xfersyn_index = ($FLD_NAM, $FLD_DSC);
%tbl_xfersyn = (
  1  => ["1.2.840.10008.1.2",      "Implicit VR, Little Endian"],
  2  => ["1.2.840.10008.1.2.1",    "Explicit VR, Little Endian"],
  3  => ["1.2.840.10008.1.2.2",    "Explicit VR, Big Endian"],
  4  => ["1.2.840.10008.1.2.4.50", "Baseline"],
  5  => ["1.2.840.10008.1.2.4.51", "Extended"],
  6  => ["1.2.840.10008.1.2.4.52", "Extended"],
  7  => ["1.2.840.10008.1.2.4.53", "Spectral selection, non-hierar."],
  8  => ["1.2.840.10008.1.2.4.54", "Spectral selection, non-hierar."],
  9  => ["1.2.840.10008.1.2.4.55", "Full progression, non-hierar."],
  10 => ["1.2.840.10008.1.2.4.56", "Full progression, non-hierar."],
  11 => ["1.2.840.10008.1.2.4.57", "Lossless, non-hierar."],
  12 => ["1.2.840.10008.1.2.4.58", "Lossless, non-hierar."],
  13 => ["1.2.840.10008.1.2.4.59", "Extended, hierar."],
  14 => ["1.2.840.10008.1.2.4.60", "Extended, hierar."],
  15 => ["1.2.840.10008.1.2.4.61", "Spectral selection, hierar."],
  16 => ["1.2.840.10008.1.2.4.62", "Spectral selection, hierar."],
  17 => ["1.2.840.10008.1.2.4.63", "Full progression, hierar."],
  18 => ["1.2.840.10008.1.2.4.64", "Full progression, hierar."],
  19 => ["1.2.840.10008.1.2.4.65", "Lossless, hierar."],
  20 => ["1.2.840.10008.1.2.4.66", "Lossless, hierar."],
  21 => ["1.2.840.10008.1.2.4.70", "Lossless, hierar."],
  22 => ["1.2.840.10008.1.2.5",    "Run Length Encoding, Lossless"],
    );

# ------------------------------------------------------------
# Category: Format
# ------------------------------------------------------------
our %cat_formats = (
  2**1  => ['DICOM'],
  2**2  => ['NEMA'],
  2**3  => ['Analyze'],
  2**4  => ['GE Scand'],
  2**5  => ['GE MRI-4'],
  2**6  => ['GE MRI-5'],
  2**7  => ['GE MRI-LX'],
  2**8  => ['Interfile'],
  2**9  => ['ECAT 6'],
  2**10 => ['ECAT 7'],
  2**11 => ['Picker CT'],
  2**12 => ['Siemens'],
  2**13 => ['Minc'],
  2**14 => ['Raw'],
  2**15 => ['Gif'],
  2**16 => ['JPEG'],
  2**17 => ['TIFF'],
  2**18 => ['PNG'],
  2**19 => ['BMP'],
  #2**20=> 'XIF',
  2**21 => ['Matlab'],
  2**22 => ['PPM'],
  2**23 => ['PGM'],
  2**24 => ['Papyrus'],
  2**25 => ['ADVANCE'],
  2**26 => ['SPM'],
  2**27 => ['Bruker'],
  2**28 => ['QuickTime'],
  2**29 => ['PICT'],
  2**30 => ['VTK'],
  2**31 => ['AFNI'],
  2**32 => ['Own/Unique'],
  2**33 => ['LONI'],
  2**34 => ['NIfTI'],
  2**35 => ['NetCDF'],
  2**36 => ['GIPL'],
    );

# ------------------------------------------------------------
# Category: Platform
# ------------------------------------------------------------
our $PLAT_WIN = 2**0;
our $PLAT_MAC = 2**1;
our $PLAT_LIN = 2**2;
our @cat_plat = ($PLAT_WIN, $PLAT_MAC, $PLAT_LIN);
our %cat_plat = (
  $PLAT_WIN => ['Windows'  , 'win'],
  $PLAT_MAC => ['Macintosh', 'mac'],
  $PLAT_LIN => ['Linux'    , 'linux'],
    );

# ------------------------------------------------------------
# Category: Language
# ------------------------------------------------------------
our $LANG_C      = 2**1;
our $LANG_CPP    = 2**2;
our $LANG_PERL   = 2**3;
our $LANG_TCL    = 2**4;
our $LANG_JAVA   = 2**5;
our $LANG_SHELL  = 2**6;
our $LANG_MATLAB = 2**7;
our $LANG_DELPHI = 2**8;
our $LANG_IDL    = 2**9;
our $LANG_CSHARP = 2**10;
our $LANG_PYTHON = 2**11;
our $LANG_RUBY   = 2**12;
our $LANG_PHP    = 2**13;
our $LANG_JSCRIPT = 2**14;

our %cat_lang = (
  $LANG_C      => ['C'],
  $LANG_CPP    => ['C++'],
  $LANG_PERL   => ['Perl'],
  $LANG_TCL    => ['Tcl'],
  $LANG_JAVA   => ['Java'],
  $LANG_SHELL  => ['Shell'],
  $LANG_MATLAB => ['Matlab'],
  $LANG_DELPHI => ['Delphi'],
  $LANG_IDL    => ['IDL'],
  $LANG_CSHARP => ['C#'],
  $LANG_PYTHON => ['Python'],
  $LANG_RUBY   => ['Ruby'],
  $LANG_PHP    => ['PHP'],
  $LANG_JSCRIPT => ['JavaScript'],
    );

# ------------------------------------------------------------
# Category: Function
# ------------------------------------------------------------
our $FUNC_UTIL = 2**1;
our $FUNC_DISP = 2**2;
our $FUNC_WRIT = 2**3;
our $FUNC_CONV = 2**4;
our $FUNC_XFER = 2**5;
our $FUNC_RGST = 2**6;
our $FUNC_LANG = 2**7;
our $FUNC_SERV = 2**8;
our $FUNC_LIBR = 2**9;
our $FUNC_MODL = 2**10;

our %cat_func = (
  $FUNC_UTIL => ['Utility'],
  $FUNC_DISP => ['Display'],
  $FUNC_WRIT => ['Write'],
  $FUNC_CONV => ['Convert'],
  $FUNC_XFER => ['PACS Client'],
  $FUNC_RGST => ['Register'],
  $FUNC_LANG => ['Lang'],
  $FUNC_SERV => ['Server'],
  $FUNC_LIBR => ['Library'],
  $FUNC_MODL => ['Model'],
    );

our $IF_API = 2**1;
our $IF_CMD = 2**2;
our $IF_GUI = 2**3;

our @cat_interface = ($IF_GUI, $IF_CMD, $IF_API);
our %cat_interface = (
  $IF_API => ['Library' , 'lib'],
  $IF_CMD => ['Cmd Line', 'cmd'],
  $IF_GUI => ['GUI'     , 'gui'],
    );

our $CATE_MRI  = 2**1;
our $CATE_FMRI = 2**2;
our $CATE_CT   = 2**3;
our $CATE_USOU = 2**4;
our $CATE_PET  = 2**5;
our $CATE_SPEC = 2**6;
our $CATE_NEUR = 2**7;
our $CATE_CARD = 2**8;
our $CATE_MODE = 2**9;
our $CATE_REG  = 2**10;
our $CATE_SEG  = 2**11;
our $CATE_PARA = 2**12;
our $CATE_SURF = 2**13;
our $CATE_MEG  = 2**14;
our $CATE_PACS = 2**15;
our $CATE_DTI  = 2**16;

our %cat_category = ( 
  $CATE_MRI  => ['MRI'],
  $CATE_FMRI => ['FMRI'],
  $CATE_CT   => ['CT'],
  $CATE_USOU => ['USound'],
  $CATE_PET  => ['PET'],
  $CATE_SPEC => ['SPECT'],
  $CATE_NEUR => ['Neuro'],
  $CATE_CARD => ['Cardiac'],
  $CATE_MODE => ['Model'],
  $CATE_REG  => ['Reg.'],
  $CATE_SEG  => ['Seg.'],
  $CATE_PARA => ['Param'],
  $CATE_SURF => ['Surf/Vol'],
  $CATE_MEG  => ['MEG'],
  $CATE_PACS => ['PACS'],
  $CATE_DTI  => ['DTI'],
    );

our %cat_feature = (
  2**1  => ['Image Fusion'],
  2**2  => ['Color Maps'],
  2**3  => ['Thresholding'],
  2**4  => ['ROIs'],
  2**5  => ['DICOM'],
  2**6  => ['Filters'],
  2**6  => ['MPEG'],
  2**7  => ['Volume Render'],
  2**8  => ['Registration'],
  2**9  => ['API/Toolkit'],
    );

our %cat_installer = (
  2**0 => ['Manual building and installation'],
  2**1 => ['Ready to run, no installer'],
  2**3 => ['Full installer'],
    );

our %cat_obtain = (
  2**0 => ['Apply to download'],
  2**1 => ['Register and download'],
  2**2 => ['Direct download'],
    );

our %cat_audience = (
  2**0 => ['General user'],
  2**1 => ['Advanced user'],
  2**2 => ['Programmer'],
    );

our $RES_DOC = 1;
our $RES_TUT = 2;
our $RES_SIT = 3;
our $RES_DAT = 4;
our $RES_LNK = 5;
our $RES_IMG = 6;
our $RES_BLO = 7;
our $RES_REV = 8;
our $RES_DEM = 9;
our $RES_NOT = 10;

our %resourcetype = (
  $RES_DOC => 'Document',
  $RES_TUT => 'Tutorial',
  $RES_SIT => 'Web Site',
  $RES_DAT => 'Test Data',
  $RES_LNK => 'Link',
  $RES_IMG => 'Image',
  $RES_BLO => 'Blog Entry',
  $RES_REV => 'Review',
  $RES_DEM => 'Live Demo',
  $RES_NOT => 'Wiki Technical Notes',
    );

# 'Relationships' table.  Prog1 REL Prog2
# Don't use FORMERLY in the DB, is implied by ISNOW.
our $REL_FORMERLY = 0;	# prog1 was formerly prog2.
our $REL_ISNOW    = 1;  # prog1 is now prog2 (reverse of above).
our $REL_ISPARTOF = 2;	# prog1 is part of prog2.
our $REL_REMOVED  = 3;	# prog1 is removed.
our $REL_DELREL   = 9;  # Delete this relationship

our %relationships = (
  ''            => '',
  $REL_FORMERLY => 'was formerly',
  $REL_ISNOW    => 'is now',
  $REL_ISPARTOF => 'is part of',
  $REL_REMOVED  => 'is removed',
  $REL_DELREL   => 'delete relationship',
    );

# Navigation code maps itemname to target.
our $NAV_HOME      = 0;
our $NAV_SEARCH    = 1;
our $NAV_PROGRAMS  = 2;
# our $NAV_PEOPLE    = 3;
our $NAV_FORMATS   = 3;
our $NAV_RESOURCES = 4;
our $NAV_BLOG      = 5;
our $NAV_ABOUT     = 6;

# Strings for top-level URLs.  These must match with .htaccess
our $STR_REDIRECT      = 'redirect';            # redirect.pl
our $STR_FINDER        = 'finder';              # finder.pl
our $STR_PROGRAMS      = 'programs';            # programs.pl
our $STR_PROGRAM       = 'program';             # program.pl
our $STR_PEOPLE        = 'people';              # people.pl
our $STR_FORMATS       = 'formats';             # formats.pl
our $STR_SEARCH        = 'search';              # search.pl
our $STR_RESOURCES     = 'resources';           # resources.pl
our $STR_LIST_VERSIONS = 'list_versions';       # listVersions.pl
our $STR_USER_HOME     = 'user_home';           #
our $STR_EDIT_AUTHOR   = 'edit_author';         # editauthor.pl
our $STR_EDIT_RESOURCE = 'edit_resource';       # editresource.pl
our $STR_ADD_MONITOR   = 'add_monitor';         # editrelationship.pl
our $STR_EDIT_PROGRAM  = 'edit_program';        # editprogram.pl
our $STR_RM_PROGRAM    = 'rm_program';          # rmprogram.pl
our $STR_EDIT_DATA     = 'edit_data';           # editdata.pl
our $STR_DO_EDIT       = 'do_edit_program';     # doeditprogram.pl
our $STR_DO_EDIT_RES   = 'do_edit_resource';     # editresource.pl
our $STR_DO_EDIT_AUTH  = 'do_edit_author';     # editresource.pl
our $STR_EDIT_RELAT    = 'edit_relationship';   # editrelationship.pl

our %nav = (
  $NAV_HOME      => ['Home'     , 'index.php' ],
  $NAV_SEARCH    => ['Search'   , $STR_FINDER   ],
  $NAV_PROGRAMS  => ['Programs' , $STR_PROGRAMS ],
  $NAV_FORMATS   => ['Formats'  , $STR_FORMATS  ],
  $NAV_RESOURCES => ['Resources', $STR_RESOURCES],
  $NAV_BLOG      => ['Blog'     , 'http://www.idoimaging.com/blog/'],
  $NAV_ABOUT     => ['About'    , 'about.php' ],
    );

my %interface_icons = (
  $radutils::IF_API => (['lib', 'API/Programming']),
  $radutils::IF_CMD => (['cmd', 'Command Line']),
  $radutils::IF_GUI => (['gui', 'Graphical']),
    );

# ------------------------------------------------------------
# Program monitor settings (what to display on add/remove icon).
# ------------------------------------------------------------

# Indexes to tip text arrays.
my $TIP_ALT  = 0;
my $TIP_TEXT = 1;
my $TIP_VERB = 2;

# [alt_text, tip_text, verbatim_text]
my $TIP_MONITOR_ON    = [
  'Monitored',
  'You are monitoring this program.  Click to see all monitored programs',
  'You are monitoring this program',
];
my $TIP_MONITOR_OFF   = [
  'Stop monitor',
  'Stop monitoring this program',
  'Stop monitoring this program',
];
my $TIP_MONITOR_ADD   = [
  'Add monitor',
  'Monitor this program (receive occasional emails of new releases)',
  'Monitor this program',
];
my $TIP_MONITOR_NA    = [
  'Not available',
  'Monitoring not available: No version information on website',
  'Monitoring is not available for this program',
];
my $TIP_MONITOR_LOGIN = [
  'Log in',
  'Log in (top of page) to monitor this program',
  'Log in (top of page) to monitor this program',
];

my $ICON_NA  = 'error_add.png';
my $ICON_ADD = 'add.png';
my $ICON_REM = 'cancel.png';
my $ICON_OK  = 'tick.png';

my $ACT_ADD = 'action=add';
my $ACT_REM = 'action=remove';

our $MON_URL   = 'mon_url';	# Url to add/remove/display monitors.
our $MON_ICON  = 'mon_icon';	# Monitor icon.
our $MON_CVARS = 'mon_cvars';	# Tip structure for tool tip.
our $MON_TIPCL = 'mon_tipcl';	# Tip class for tool tip.
our $MON_TEXT  = 'mon_text';	# Verbatim (program page).

my %prog_actions = (
  # Binary mask: user_page, logged_in, is_monitored.
  # Contents   : Icon, URL, Tooltip.
  0000 => [$ICON_ADD, ""                             , $TIP_MONITOR_LOGIN],
  0001 => [$ICON_OK , "${STR_USER_HOME}"             , $TIP_MONITOR_ON   ],
  0010 => [$ICON_ADD, "${STR_ADD_MONITOR}?${ACT_ADD}", $TIP_MONITOR_ADD  ],
  0011 => [$ICON_OK , "${STR_USER_HOME}"             , $TIP_MONITOR_ON   ],
  0100 => [$ICON_ADD, "${STR_ADD_MONITOR}?${ACT_ADD}", $TIP_MONITOR_ADD  ],
  0101 => [$ICON_REM, "${STR_ADD_MONITOR}?${ACT_REM}", $TIP_MONITOR_OFF  ],
  0110 => [$ICON_ADD, "${STR_ADD_MONITOR}?${ACT_ADD}", $TIP_MONITOR_ADD  ],
  0111 => [$ICON_REM, "${STR_ADD_MONITOR}?${ACT_REM}", $TIP_MONITOR_OFF  ],
);
# Actions for programs that can't be monitored (else table above would double in size).
my @no_monitor_actions = ($ICON_NA, '', $TIP_MONITOR_NA);

# ------------------------------------------------------------
#  Functions
# ------------------------------------------------------------

sub authName {
  my ($dbh, $ident, $opts) = @_;
  my %opts = ();
  %opts = %$opts if (ref($opts));
  my $maxlen  = $opts{'maxlen'};
  my $flag    = $opts{'flag'} ? 1 : 0;

  # Get details on author.
  my ($afirst, $alast, $ahome, $acountry) = ('', '', '', '');
  if (my $auth = dbRecord($dbh, "author", $ident)) {
    my %auth = %$auth;
    ($afirst, $alast, $ahome, $acountry) = @auth{qw(name_first name_last home country)};
  }

  my $aname = (length($afirst)) ? "$afirst $alast" : $alast;
  $aname = truncateString($aname, $maxlen) if (has_len($maxlen));
  $aname = "&nbsp;" unless (has_len($aname));
  # Add flag if required.
  my ($flagstr, $fptr) = ("", "");
  if ($flag) {
    if ($fptr = makeFlagIcon($acountry)) {
      $flagstr = $fptr->{'flagstr'};
    }
  }
          
  # Add link to author's home page if we have one.
  my $aurl = "/people/$ident";
  $aname = "<a href='$aurl'>$aname$flagstr</a>";
  my %ret = (
    'urlstr' => $aname,
      );
  if (ref($fptr)) {
    $ret{'auth_cvars'} = $fptr->{'flag_cvars'};
  }
  return \%ret;
}

sub makeFlagIcon {
  my ($country) = @_;

  my $ret = undef;
  if (has_len($country)) {
    my $tipclass = "tip_flag_$country";
    my %tip_cvars = (
      'class'       => $tipclass,
      'str'         => $countries{$country},
      'wrapFn'      => "dw_Tooltip.wrapToWidth",
      'followMouse' => "false",
        );

    my $ccode = "\L$country";
    my $flagfile = "/img/icon/flags/png/${ccode}.png";
    my $flagstr = "&nbsp;<img border='0' class='showTip $tipclass' src='$flagfile' title='' alt='$country' />";
    my %ret = (
      'flagstr'    => $flagstr,
      'flag_cvars' => \%tip_cvars,
        );
    $ret = \%ret;
  }
  return $ret;
}

# Return pointer to hash for resource icon.

sub makeRsrcIcon {
  my ($dbh, $ident) = @_;
  my ($ret, $tipstr, $idstr, $iddiv, $tipdiv) = ('', '', '', '', '');

  # ------------------------------------------------------------
  # Get blog and review resources for this program ident.
  # ------------------------------------------------------------

  my $rstr  = "select * from resource";
  $rstr .= " where (";
  $rstr .= "    (type = $RES_BLO)";
  $rstr .= " or (type = $RES_REV)";
  $rstr .= " or (type = $RES_DEM)";
  $rstr .= " ) and program = '$ident'";
  $rstr .= " order by date desc";
  my $rsh = dbQuery($dbh, $rstr);

  # Create hash by date of resource pointers.
  my %prog_res = ();
  while (my $resp = $rsh->fetchrow_hashref) {
    my $resdate = convert_date($resp->{'date'}, $DATE_MDY);
    my $url = $resp->{'url'};
    $idstr = $idstr . $iddiv . $resp->{'ident'};
    $iddiv = '_';
    my $urlstr = "<a target='new' href='http://${url}'>$resourcetype{$resp->{'type'}}</a>";
    $tipstr .= "${tipdiv}$urlstr, dated $resdate";
    $tipdiv = "<br />";
  }

  if (has_len($tipstr)) {
    $tipstr = "Resources for this program:<br />" . $tipstr;
    my $tipclass = "tip_rsrc_${idstr}";
    my %tip_cvars = (
      'class'       => $tipclass,
      'str'         => $tipstr,
      'wrapFn'      => "dw_Tooltip.wrapToWidth",
      'followMouse' => "false",
      'hoverable'   => "true",
        );
    my $iconfile = "/img/icon/pencil.png";
    my $iconstr = "&nbsp;<img border='0' class='showTip $tipclass' src='$iconfile' title='' alt='Resource' />";

    my %ret = (
      'iconstr'  => $iconstr,
      'icon_cvars' => \%tip_cvars,
        );
    $ret = \%ret;
  }
  return $ret;
}

# Return keys for given hash, sorted by hash value.
sub sortHashVal {
  my ($hash, $index) = @_;
  
  my @retvals = ();
  if (has_len($index)) {
    @retvals = sort {$hash->{$a}->[$index] cmp $hash->{$b}->[$index]} keys %$hash;
  } else {
    @retvals = sort {$hash->{$a} cmp $hash->{$b}} keys %$hash;
  }
  return @retvals;
}

# Return ref to hash of (keys => val) for this hash that make given val.
# If hash values are array references, use val[0] of array.
#   hashname: Plain text name of hash to reference.
#   sumval:   Encoded sum of hash keys.
#   vallen:   Truncate value length to this (omit = don't truncate).
#   icon:     Produce icon string (data comes from referenced hash).
#   sortarr:  Ref to array of keys to sort by (else cmp value or value[0])
#   allicons: Icon string is eg 'plat__mac_linux' rather than 'plat_mac_linux'
# Returns:
#   Hash with following elements:
#   vals:     Ref to hash of (key => value) as per scalar context.
#   iconstr:  Name of icon for selected values.
#   valstr:   Space-separated string of values.
#   skeys:    Ref to array of keys sorted in order.
sub selectedVals {
  my ($args) = @_;
  my %args = %$args;

  my ($hashname, $sumval, $vallen, $sortarr, $field) = @args{qw(hashname sumval vallen sortarr field)};
  $sumval = 0 unless (has_len($sumval));
  $vallen = '' unless (has_len($vallen) and $vallen);

  my %hash = %$hashname;
  unless (scalar(keys(%hash))) {
    warn "ERROR: Hash $hashname is empty";
    return;
  }
  my @hkeys = keys(%hash);
  my $hval = $hash{$hkeys[0]};
  my $valsarearray = (ref($hval) =~ /ARRAY/) ? 1 : 0;

  # Iterate over hash in order, as icon string is order-dependent.
  my @sortkeys = ();
  if (has_len($sortarr)) {
    # Use predefined sort keys - remember to test for their existence later.
    @sortkeys = @$sortarr;
  } else {
    # Sort keys are value, or value[0].
    if ($valsarearray) {
      @sortkeys = sort {$hash{$a}->[0] cmp $hash{$b}->[0]} @hkeys;
    } else {
      @sortkeys = sort {$hash{$a} cmp $hash{$b}} @hkeys;
    }
  }

  my %selvals = ();
  my %allvals = ();
  my (@sortedkeys, @sortedvals) = ((),());
  my ($valstr_w, $valstr_n) = ("", "");
  foreach my $key (@sortkeys) {
    my $hashval = $hash{$key};
    next unless (defined($hashval));
    my $val = $valsarearray ? $hashval->[0] : $hashval;
    $allvals{$key} = $val;
    $val = ($vallen) ? substr($val, 0, $vallen) : $val;
    my $keyistrue = (($key * 1) & ($sumval * 1));
    if ($keyistrue) {
      $selvals{$key} = $val;
      push(@sortedkeys, $key);
      push(@sortedvals, $val);
    }
    # Icon string format: hashname_<key1>..._<keyN>.png
    $valstr_w .= ($keyistrue and defined($hashval->[1])) ? "_$hashval->[1]" : "_";
    $valstr_n .= ($keyistrue and defined($hashval->[1])) ? "_$hashval->[1]" : "";
#     print "*** key $key, sumval $sumval, keyistrue $keyistrue, icons_wide $icons_wide, icons_narr $icons_narr\n";
  }

  # HACK
  $valstr_n = '___' if ($valstr_n eq '');

  # Hashname may come in as 'radutils::cat_plat', or 'cat_plat', or 'plat'.
  my $valstr = join(" ", @sortedvals);
  my $val_str = join("_", @sortedvals);
  $val_str =~ s/\ /_/g;
  my $iconpath = "/img/icon";
  my $cat = $hashname;
  $cat =~ s/radutils::|cat_//g;
  my $icons_wide = "<img src='${iconpath}/${cat}${valstr_w}.png' title='' alt='$val_str' />";
  my $icons_narr = "<img src='${iconpath}/${cat}${valstr_n}.png' title='' alt='$val_str' />";

  # Add tip text if required.
  $field = '' unless (has_len($field));
  my $tipclass = "tip_${field}_${val_str}";
# print STDERR "radutils::selectedVals($cat): valstr_w '$valstr_w', valstr_n '$valstr_n'\n";
  my $icons_wide_t = "<img class='showTip $tipclass' src='${iconpath}/${cat}${valstr_w}.png' title='' alt='$val_str w' />";
  my $icons_narr_t = "<img class='showTip $tipclass' src='${iconpath}/${cat}${valstr_n}.png' title='' alt='$val_str n' />";
  my %field_names = (
    'plat'      => 'Platform',
    'interface' => 'Interface',
      );
  my $tiptext = (exists $field_names{$field}) ? $field_names{$field} : $field;

  $tiptext .= ": " . join(", ", @sortedvals);
  my %tip_cvars = (
    'class'       => $tipclass,
    'str'         => $tiptext,
    'wrapFn'      => "dw_Tooltip.wrapToWidth",
    'followMouse' => "false",
      );

  my %rethash = (
    'wideicons'   => $icons_wide,	# Each categ present ie 'plat_win__lin.png'
    'narricons'   => $icons_narr,	# Unused categs omitted ie 'plat_win_lin.png'
    'wideicons_t' => $icons_wide_t,	# Wide icons with text tips.
    'narricons_t' => $icons_narr_t,	# Narrow icons with text tips.
    'sortkeys'    => \@sortedkeys,	# Keys to hash of selected vals, in order of values.
    'sortvals'    => \@sortedvals,	# NB redundant since == @selvals{@sortedkeys}
    'vals'        => \%selvals,
    'allvals'     => \%allvals,		# Val = 0 or 1 depending if selected.
    'valstr'      => $valstr,		# NB redundant since == join(" ", @sortedvals)
    'val_str'     => $val_str,		# val0_val1_val2 etc
    'cvars'       => \%tip_cvars,       # Hash of values for content_vars.
      );
#      printHash(\%rethash, "selectedvals(hash $hashname val $sumval) returning");
  return \%rethash;
}

sub listPrereq {
  my ($dbh, $prer) = @_;
  my ($name, $ident, @ret);

  return () unless (has_len($prer));
  my $sh = dbQuery($dbh, "select ident, name from program where ident < 100");
  while (($ident, $name) = $sh->fetchrow_array()) {
    if ((2 ** $ident) & ($prer * 1)) {
      push(@ret, $ident) ;
    }
  }
  return @ret;
}

# Return db handle

sub hostConnect {
  my ($db_name) = @_;
  $db_name = "imaging" unless (has_len($db_name));

  # Database init.
  my %attr = (RaiseError => 1);
  my $dsn = "DBI:mysql:$db_name:localhost";
  my $dbh = DBI->connect($dsn,'_www','PETimage', \%attr);
  (has_len($dbh)) or die "Can't get database connection";

  return $dbh;
}

sub getEnv {
  my (@varnames) = @_;
  my @varvals;

  foreach my $varname (@varnames) {
    my $val = $ENV{$varname};
    $val = '' unless (defined($val));
    push(@varvals, $val);
  }
  
  return (scalar(@_) > 1) ? @varvals : $varvals[0];
}

# Given encoded list of formats, return string of format names with URLs.

sub formatList {
  my ($encval) = @_;

  return("") unless (has_len($encval));
  my $fmt = $encval;
  my $str = "";
  my @formats;
  my @vals = sort {$b <=> $a} keys %cat_formats;

  foreach my $key (@vals) {
    if ($fmt >= $key) {
      push(@formats, $key);
      $fmt -= $key;
    }
  }

  my $url = "a href='/${STR_FORMATS}";
  my $comma = "";
  @formats = sort {$cat_formats{$a}->[0] cmp $cat_formats{$b}->[0]}  @formats;
  foreach my $format (@formats) {
    $str .= "${comma}<${url}/$format'>$cat_formats{$format}->[0]</a>";
    $comma = ",\n";
  }
#   tt("formatList($encval) returning $str");
  return $str;
}

# Return the next available program ID.
sub nextIdent {
  my ($dbh, $table) = @_;
  my $newident = '';

  $table = "program" unless (has_len($table));
  my $sh = dbQuery($dbh, "select max(ident) from $table");
  ($newident) = $sh->fetchrow_array();
  $newident += 1;
  return $newident;
}

sub comment {
  my ($str, $blankline) = @_;
  $blankline = (has_len($blankline) and $blankline) ? 1 : 0;

  my $nstr = $blankline ? "\n" : "";
  return "${nstr}<!-- $str -->\n";
}

# Return given database record as a hash.

sub dbRecord {
  my ($dbh, $table, $ident) = @_;

  my $sh = dbQuery($dbh, "select * from $table where ident = '$ident'");
  my $href = $sh->fetchrow_hashref();
  return $href;
}


# sub printHashAsTable {
#   my ($ptr, $brief) = @_;
#   $brief = 0 unless (has_len($brief) and ($brief > 0));
#   my %hash = %$ptr;
#   print "<table>\n";
#   foreach my $key (sort keys %hash) {
#     my $val = $hash{$key};
#     next if ($brief and not (has_len($val)));
#     print "<tr><th align='left' valign='top'>$key</th><td>$hash{$key}</td></tr>\n";
#   }
#   print "</table>\n";
# }

# Return two representations of the current time:
# 10/02/02 11:46:01	Formatted string.
# 021002_114601		File name - will sort alphabetically.

sub timeNowHash {
  my ($sec, $min, $hour, $mday, $mon, $year, @a) = localtime(time());
  my $yearorig = $year;
  $year %= 100;
  $mon += 1;

  my $time = sprintf("%02d/%02d/%02d %02d:%02d:%02d", $mon, $mday, $year, $hour, $min, $sec);
  my $fname = sprintf("%02d%02d%02d_%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
  $year = $yearorig + 1900;
  my $sqltime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
  my $date = sprintf("%02d/%02d/%02d", $mon, $mday, $year);
  my $year2 = sprintf("%02d", $year % 100);
  my $month2 = sprintf("%02d", $mon);
  my $day2 = sprintf("%02d", $mday);
  my $days = daysSinceEpoch($year, $mon, $mday);

  my %ret = (
    'MM/DD/YY'   => $time,	# 4/23/04 14:42:49
    'YYMMDD'     => $fname,	# 040423_144249
    'YYYY-MM-DD' => $sqltime,	# 2004-04-23 14:42:49
    'SQL'        => $sqltime,	# 2004-04-23 14:42:49
    'M/D/Y'      => $date,	# 4/23/04
    'YYYY'       => $year,     # 2004
    'YY'         => $year2,    # 04
    'MM'         => $month2,   # 04
    'DD'         => $day2,     # 23
    'DDDD'       => $days,      # Since epoch
      );
  return \%ret;
}

# Return icon for link count.
# Algorithm for n links: ln(2n) ceiling 100; ie >50 links all maxed.
# Algorithm for m monitors: ln(m/mbar) - mbar is avg monitors/program.

sub linkCountIcon ($) {
  my ($percentile) = @_;
  my $iconpath = "/img/icon";

  my $numballs = ($percentile + 10) / 20;
  my $reticon = "";
  my $i = 0;
  while ( $i < $numballs ) {
    $reticon .= "<img src='${iconpath}/bullet_blue.png' title='' alt='x' />";
    $i++;
  }
  while ( $i < 5 ) {
    $reticon .= "<img src='${iconpath}/bullet_white.png' title='' alt='x' />";
    $i++;
  }
  return $reticon;
}

sub fmtAuthorName {
  my ($ident, $dbh) = @_;
  
  my $formatName = "";
  my $sh = dbQuery($dbh, "select * from author where ident = '$ident'");

  if (my $ref = $sh->fetchrow_hashref()) {
    (my $fname = $ref->{'name_first'}) =~ s/[^a-zA-Z0-9-\ ]//g;
    (my $lname = $ref->{'name_last'}) =~ s/[^a-zA-Z0-9-\ ]//g;
    my $comma = (length($fname)) ? ", " : "";
    $formatName = "$lname$comma$fname";
    if (length($formatName) > 35) {
      $formatName = substr($formatName, 0, 35) . "...";
    }
  }
  return $formatName;
}

# Return the $sh for given query on given dbh
sub dbQuery {
  my ($dbh, $str, $verbose, $dummy) = @_;
  $verbose = 0 unless (has_len($verbose) and $verbose);
  $dummy = 0 unless (has_len($dummy) and $dummy);
  warn("radutils::dbQuery($str)") if ($verbose);
  return "" if ($dummy);

  my ($sh, $errstr);
  unless ($sh = $dbh->prepare($str)) {
    $errstr = $dbh->errstr;
    warn("radutils::dbQuery($str): Error: $errstr");
    $ENV{'ERRMSG'} = $errstr;
    return "";
  }

  unless ($sh->execute) {
    $errstr = $sh->errstr;
    warn("DBI:MySQL sth error: $errstr");
    $ENV{'ERRMSG'} = $errstr;
    return "";
  }

  return $sh;
}

# sub today {
#   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isd) = localtime(time());
#   $mon += 1;
#   $year += 1900;
#   my $date = sprintf "%4d-%02d-%02d", $year, $mon, $mday;
#   return $date;
# }

# Return next available ident from given table.  Assumes correct db.

sub nextIndex {
  my ($dbh, $field, $table) = @_;

  my $sql_str = "select max($field) from $table";
  my $sh = dbQuery($dbh, $sql_str);
  my ($nextIndex) = $sh->fetchrow_array();
  $nextIndex = (has_len($nextIndex)) ? $nextIndex + 1 : 0;

  return $nextIndex;
}

# Add a 'version' table record for this program if date or rev is new.
sub addVersionRecord {
  my ($dbh, $progid, $cgi) = @_;

  # Get the next record number
  my $sql_str = "select max(ident) from version";
  my $sh = dbQuery($dbh, $sql_str);
  my ($nextident) = $sh->fetchrow_array();
  $nextident += 1;

  my ($new_rev, $new_rdate) = getParams($cgi, (qw(rev rdate)));
  $sql_str = "select rev, rdate from program where ident = '$progid'";
  $sh = dbQuery($dbh, $sql_str);
  my ($old_rev, $old_rdate) = $sh->fetchrow_array();
  $old_rdate = convert_date($old_rdate, $DATE_SQL_DATE);
  $new_rdate = convert_date($new_rdate, $DATE_SQL_DATE);
  $new_rev   = "" unless (has_len($new_rev));
  $old_rev   = "" unless (has_len($old_rev));
  $new_rdate = "" unless (has_len($new_rdate));
  $old_rdate = "" unless (has_len($old_rdate));

  # Insert a 'version' record if data added or date changed.

  my $diffrevlen = (length($new_rev) and not length($old_rev)) ? 1 : 0;
  my $diffrdate = ($new_rdate ne $old_rdate) ? 1 : 0;
  my $diffrev = ($new_rev ne $old_rev) ? 1 : 0;

  if ($diffrevlen) {
    print STDERR "radutils::addVersionRecord(revlen): length($new_rev) and not length($old_rev)\n";
  }
  if ($diffrdate) {
    print STDERR "radutils::addVersionRecord(rdate): '$new_rdate' ne '$old_rdate'\n";
  }
  if ($diffrev) {
    print STDERR "radutils::addVersionRecord(rev): '$new_rev' ne '$old_rev'\n";
  }

  if ($diffrevlen or $diffrdate or $diffrev) {
    my $today = today();
    $new_rdate = convert_date($new_rdate, $DATE_SQL_DATE);
    my $update_str = "insert into version set ident = '$nextident', ";
    $update_str .= "progid = '$progid', version = '$new_rev', ";
    $update_str .= "reldate = '$new_rdate', adddate = '$today'";
    print STDERR "radutils::addVersionRecord($diffrevlen, $diffrdate, $diffrev): $update_str\n";
    print "$update_str<br>\n";
    dbQuery($dbh, $update_str);
  }
}

# Return array of program idents monitored by this user.

sub monitoredPrograms {
  my ($dbh, $userid) = @_;
  my @progids = ();

  return () unless (has_len($userid));
  my $str = "select progid from monitor where userid = '$userid' order by progid";

  my $sh = dbQuery($dbh, $str);
  while (my ($progid) = $sh->fetchrow_array) {
    push(@progids, $progid);
  }

  return @progids;
}

sub validDate {
  my ($date) = @_;

  return (defined($date) and length($date) and ($date ne '0000-00-00') and ($date ne '2000-00-00'));
}

# Return ptr to hash of prog (ID, name) with entry in 'related' table sharing ident.
sub relatedPrograms {
  my ($dbh, $ident) = @_;

  my $sh = dbQuery($dbh, "select prog1, prog2 from related where prog1 = '$ident' or prog2 = '$ident'");
  my $ref = $sh->fetchall_arrayref();
  my (%related);
  foreach my $relref (@$ref) {
    my ($p1, $p2) = @$relref;
    my $otherprog = ($ident == $p1) ? $p2 : $p1;
#     $sh = dbQuery($dbh, "select name, summ from program where ident = '$otherprog'");
    $sh = dbQuery($dbh, "select * from program where ident = '$otherprog'");
    my $href = $sh->fetchrow_hashref();
    $related{$otherprog} = $href;
  }
  return \%related;
}

# Return given string, if over length, truncate and append '...'.

sub truncateString {
  my ($str, $len) = @_;

  if (length($str) > $len) {
    $str = substr($str, 0, $len) . "...";
  }
  return $str;
}

# Return alphabetical list of hash members encoded by $val in %$fld.

sub listHashMembers {
  my ($fld, $testval) = @_;
  my %hash = %$fld;

  my @rslt = ();
  foreach my $key (keys %hash) {
    if (int($testval) & int($key)) {
      my $hashval = $hash{$key};
      my $theval = (ref($hashval)) ? $hashval->[0] : $hashval;
      push(@rslt, $theval) ;
    }
  }
# print STDERR "radutils::listHashMembers($fld, $testval) returning " . join(",", @rslt) . "\n";
  return @rslt;
}

# Make given dir including path to it.  Mode is applied only to lowest dir.
sub makeDir {
  my ($dir, $mode) = @_;
  my ($wd) = ($dir =~ /\//) ? "" : cwd();
  
  $mode = 0755 unless (has_len($mode));
  my (@bits) = split(/\//, $dir);
  my $levels = scalar(@bits);
  my $path = $wd;
  my $level = 0;
  foreach my $bit (@bits) {
    $path = "${path}/${bit}";
    unless (-d $path) {
      my $thismode = ($level == ($levels - 1)) ? $mode : 0755;
      mkdir($path) or return "";
    }
    $level++;
  }
  return $path;
}

sub dumpParams {
  my ($cgi) = @_;

  my @params = $cgi->param();
  my $nparam = scalar(@params);
  my $nhasval = 0;
  my $table = "";
  if (scalar(@params)) {
    foreach my $param (sort @params) {
      my $val = '';
      my (@vals) = $cgi->param($param);
      $val = join(" ", @vals) if (scalar(@vals));
      if (has_len($val)) {
	$nhasval++;
      } else {
	$val = "&nbsp;";
      }
      $table .= "<tr><td>$param</td><td>$val</td></tr>\n";
    }
  }
#  if (length($table)) {
    print "<table cellspacing='0' cellpadding='2' border='1'>\n";
    print "<tr><th>Num params</th><th>$nhasval</th></tr>\n";
    print "<tr><th>Key</th><th>Value</th></tr>\n";
    print "<tr><td>Script</td><td>" . $cgi->script_name() . "</td></tr>\n";
    print "$table\n";
    print "</table>\n";
#  }
}

sub printTitle {
  my ($cgi, $wide, $currpage) = @_;
  $wide = 0 unless (has_len($wide) and $wide);

  printPageIntro($wide, $currpage);
  print comment("radutils.pm::printTitle(): End");
}

# Return green or red icon, and stripped URL.
sub urlIcon {
  my ($opts) = @_;
  my %opts = %$opts;
  my ($cgi, $ident, $urlstat, $table, $field, $url) = @opts{qw($KEY_CGI ident urlstat table field url)};

  my $redir_url = "/${STR_REDIRECT}?ident=$ident&amp;field=$field&amp;table=$table";
  my ($iconstr, $tipstr, $html) = ("", "", "", "");
  my $iconpath = "/img/icon";

  # Fill in initial (known) object from which tiptext will be created.
  my %cvars = (
    'wrapFn'      => "dw_Tooltip.wrapToWidth",
    'followMouse' => "false",
      );

  # If url is supplied, test if it is empty or not defined.
  if (exists($opts{'url'}) and not (has_len($url))) {
    # URL string provided, but empty.
    my $tipid = "tip_${table}_${ident}_na";
    $html = "<img  class='showTip $tipid' border='0' src='${iconpath}/cross.png' title='' alt='Go' />";
    my $tiptext = (exists($opts->{'tip_na'})) ? $opts->{'tip_na'} : "Not available";
    $cvars{'class'} = $tipid;
    $cvars{'str'} = $tiptext;
  } else {
    if ($urlstat) {
      # URL provided, link is active.
      my $tipid = "tip_${table}_${ident}_1";
      $cvars{'class'} = $tipid;
      $cvars{'str'} = $opts->{'tip_1'};
#       $iconstr = "<img class='showTip $tipid' border='0' src='${iconpath}/arrow_right.png' title='' alt='Go' />";
      $iconstr = "<img class='showTip $tipid' border='0' src='${iconpath}/download-arrw_sml.png' title='' alt='Go' />";
    } else {
      # URL provided, link is inactive.
      my $tipid = "tip_${table}_${ident}_0";
      $cvars{'class'} = $tipid;
      $cvars{'str'} = $opts->{'tip_0'};
      $iconstr = "<img class='showTip $tipid' border='0' src='${iconpath}/error_go.png' title='' alt='Go' />";
    }
    $html = "<a href='$redir_url' target='new'>${iconstr}</a>";
  }

  my %ret = (
    'urlstr' => $html,
    'url_cvars' => \%cvars,
      );
  return \%ret;
}

# Given long array, return subrange to display and nav list HTML.
#   nitems:   Number of elements in array.
#   nperpage: Number of elements to display per page.
#   page:     Page index (from 0).
#   url:      HTML code for CGI link to another page.
#   condstr:  Conditions to be appended to linkcode.
#   allnames: Names (nitems count) of each item, for tool tips of page-bracketing names.
# Returns:
#   (low, high, navcode)

sub listParts {
  my ($nitems, $nperpage, $page, $url, $condstr, @allnames) = @_;

  # Return empty HTML if only one page.
  if ($nitems <= $nperpage) {
    return(0, ($nitems - 1), "");
  }

  # Calculate index numbers for pages.
  my $low = $page * $nperpage;
  my $first = $low + 1;
  my $max = $low + $nperpage;
  $max = $nitems if ($max > $nitems);
  my $high = $max - 1;
  my $npage = int(($nitems - 1)/$nperpage) + 1;

  # Separators depend on whether there is a condition string.
  my $linkcode = (has_len($condstr)) ? "${url}\?$condstr\&" : "${url}\?";
  
  # Previous page.
  my ($prevurl, $nexturl) = ("Previous", "Next");
  my $prev = $page - 1;
  if ($prev >= 0) {
    my $psumm = pageSumm($prev, $nperpage, $nitems, @allnames);
    $prevurl = "<span title='$psumm'><a class='grey' href='${linkcode}page=$prev'>Previous</a></span>";
  }
  
  # Next page.
  my $next = $page + 1;
  if ($next < $npage) {
    my $nsumm = pageSumm($next, $nperpage, $nitems, @allnames);
    $nexturl = "<span title='$nsumm'><a class='grey' href='${linkcode}page=$next'>Next</a></span>";
  }
  
  my $html = "$nitems items; displaying $first..$max\n<br />\n";
  $html .= "$prevurl\n";

  # Prebuild array of tool tip text.
  my @text = ();
  foreach my $pind (0..($npage - 1)) {
    my $nextpage = $pind + 1;
    my $text = "";
    if ($pind != $page) {
      $text = pageSumm($pind, $nperpage, $nitems, @allnames);
    }
    push(@text, $text);
  }
    
  foreach my $pind (0..($npage - 1)) {
    $html .= "&nbsp;&nbsp;";
    my $nextpage = $pind + 1;
    my $url = "${linkcode}page=$pind";

    if ($pind == $page) {
      $html .= "<tt class='big'><b>$nextpage</b></tt>";
    } else {
      if (length(my $text = $text[$pind])) {
	$html .= "<span title='$text'><a class='grey' href='$url'>$nextpage</a></span>\n";
      } else {
	$html .= "<a class='grey' href='$url'>$nextpage</a>\n";	
      }
    }
  }
  $html .= "&nbsp;&nbsp;";
  $html .= "$nexturl\n";
#   tt("radutils::listParts($nitems, $nperpage, $page, $linkcode) returning low $low, high $high, html $html");
  return ($low, $high, $html);
}

# Return summary of programs on given page.
sub pageSumm {
  my ($pind, $nperpage, $nitems, @allnames) = @_;

  my $nextlow = $pind * $nperpage;
  my $nexthigh = $nextlow + $nperpage - 1;
  $nexthigh = ($nitems - 1) if ($nexthigh >= $nitems);
  my $text;
  if (scalar(@allnames)) {
    $text = $allnames[$nextlow] . " ... " . $allnames[$nexthigh];
  } else {
    $text = "$nextlow ... $nexthigh";
  }
  return $text;
}

sub relatedProgramsTable {
  my ($related, $dbh, $tipstrs, $leadspace) = @_;
  my %related = %$related;

  my @related = sort {"\U$related{$a}->{'name'}" cmp "\U$related{$b}->{'name'}"} keys(%related);
  my $relrows = "";
  foreach my $relid (@related) {
    my $relhash = $related{$relid};

    # Get program link and platform and interface icons.
  my %popts = (
    'ident'   => $relhash,
    'dbh'     => $dbh,
    'maxlen'  => 25,
    'isnew'   => 0,
  );
  my $proglink = makeProgramLink(\%popts);
    my %proglink = %$proglink;
    my ($progstr, $capstr, $platstr) = @proglink{qw(progstr capstr platstr)};
    # Add tooltip objects to global g_tipvars.
    addCvars($proglink, $tipstrs);

    my $relsumm = truncateString($relhash->{'summ'}, 80);
    $relrows .= "<tr>\n";
    if (has_len($leadspace) and $leadspace) {
      $relrows .= "<td width='$leadspace'>&nbsp;</td>\n";
    }
    $relrows .= "<td width='180'>$progstr</td>\n";
    $relrows .= "<td>$capstr</td>\n";
    $relrows .= "<td>$platstr</td>\n";
    $relrows .= "<td>$relsumm</td>\n";
    $relrows .= "</tr>\n";
  }
  my $reltxt = "";
  if (length($relrows)) {
    $reltxt = "<table border='0' cellpadding='2' cellspacing='0'>\n";
    $reltxt .= "${relrows}\n</table>\n";
  }
  return $reltxt;
}

sub programsHavingSpeciality {
  my ($dbh, $speciality) = @_;

  my $sh = dbQuery($dbh, "select ident, name, summ, category from program");
  my %matching = ();
  while (my ($ident, $name, $summ, $categ) = $sh->fetchrow_array()) {
    if ((($categ * 1) & ($speciality * 1)) == $speciality) {
      $matching{$ident} = ([$name, $summ]);
    }
  }
  return \%matching;
}

sub sortedcomb {
  my (@arr) = @_;
  my %rslt = ();
  my $next= combinations(@arr);
  while (my @comb= $next->()) {
    my $s = scalar(@comb);
    if (defined($rslt{$s})) {
      push(@{$rslt{$s}}, \@comb);
    } else {
      $rslt{$s}[0] = (\@comb);
    }
  }
  return \%rslt;
}

sub combinations {
  my @list= @_;
  my @pick= (0) x @list;
  return sub {
    my $i= 0;
    while( 1 < ++$pick[$i]  ) {
      $pick[$i]= 0;
      return   if  $#pick < ++$i;
    }
    return @list[ grep $pick[$_], 0..$#pick ];
  };
}

sub makeTableBinary {
  my ($dbh, $hptr, $mptr, $matchedptr, $tipstrs) = @_;
  my %headings = %$hptr;
  my @matching = @$mptr;
  my @matched = @$matchedptr;	# Which headings are used by >= 1 line.
  my $colwidth = 40;
  my $str = "";
  # Offset of program names from LH due to speciality columns.
  my $offsetwidth = 0;

  $str = "<table border='0' cellpadding='2' cellspacing='0'>\n";
  my @headings = sort {$headings{$a} cmp $headings{$b}} keys %headings;
  $str .= "<tr>";
  my %include = ();
  foreach my $heading (@headings) {
    # Only use those headings used by >= 1 prog.
    my $found = 0;
    foreach my $matched (@matched) {
      if ($matched == $heading) {
	$include{$matched} = 1;
	$found = 1;
	$offsetwidth += $colwidth;
# 	tt("$heading: offsetwidth $offsetwidth += $colwidth");
      }
    }
    next unless ($found);
    $str .= "<th width='$colwidth'>$headings{$heading}</th>";
  }
  $str .= "<td width='180'>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
  $str .= "</tr>\n";
  # Iterate over each item, displaying partial binary code matches.
  foreach my $match (@matching) {
    $str .= "<tr>";
    my ($subcat, $ident, $pname, $psumm) = @$match;
    # Test each heading's category in turn.
    my $numheadings = scalar(@headings);
    foreach my $heading (@headings) {
      # Skip those columns not used at least once.
      next unless (defined($include{$heading}));
      if ((($subcat * 1) & ($heading * 1)) == $heading) {
	$str .= "<td width='$colwidth' align='center'>*</td>";
      } else {
	$str .= "<td>&nbsp;</td>";
      }
    }
    # Get program link and platform and interface icons.
  my %popts = (
    'ident'  => $ident,
    'dbh'    => $dbh,
    'maxlen' => 15,
    'isnew'  => 0,
  );
  my $proglink = makeProgramLink(\%popts);
    my %proglink = %$proglink;
    my ($progstr, $capstr, $platstr) = @proglink{qw(progstr capstr platstr)};
    # Add tooltip objects to global g_tipvars.
    addCvars($proglink, $tipstrs);
    
    # Program name and summary may need to be truncated due to number of columns
    $psumm = truncateString($psumm, 80 - 3 * $numheadings);
    $str .= "<td valign='top' align='left width='180''>$pname</td>\n";
    $str .= "<td valign='top' align='left'>$capstr</td>\n";
    $str .= "<td valign='top' align='left'>$platstr</td>\n";
    $str .= "<td valign='top' align='left'>$psumm</td>\n";
    $str .= "</tr>\n";
  }
  
  $str .= "</table>\n";

  my %ret = (
    'tablestr' => $str,
    'offset'   => $offsetwidth,
      );
  return \%ret;
}

# Given value, and its record type, format it for SQL insertion.
#   val    : Value to be submitted to SQL.
#   field  : Pointer to appropriate field in db_ table.

sub valToSQL {
  my ($val, $field) = @_;
  my ($index, $key, $name, $type, $size, $ssize) = @$field;
  (my $newval = $val) =~ s/^\s+//;
  
  # Case: Strip http header from URL.
  $newval =~ s{^http://}{} if ($key =~ /url$/);
  # Case: Format dates correctly.
  $newval = processDates($newval)->{'SQL'} if ($type == $DB_DAT);

#  tt("radutils::valtosql(): ($index, $key, $name, $type, $size, $ssize): old $val new $newval");
  return $newval;
}

# Given value, and its record, return HTML for its editable form.
# Dates are formatted and displayted in a textarea.
# Binary encoded values are displayed as a dropdown.
# Short text goes in a textfield; long text goes in a textarea.

sub valToTDedit {
  my ($cgi, $dbh, $val, $field, $table) = @_;
  my ($f_index, $f_key, $f_name, $f_type, $f_size, $f_ssize) = @{$field};

  # Use shortened table name for directory path.
  my %stables = ('program' => 'prog');
  my $stable = $stables{$table};
  
  # Process default value if necessary.
  $val = convert_date($val, $DATE_MDY) if ($f_type == $DB_DAT);
  
  # tddata is selector for selection-type fields, else freeform text.
  my $ret = '';
  if (($f_type == $DB_CHR) && (($f_size == 0) || ($f_size > 100))) {
    # Long text fields go in a textarea.
    $ret = $cgi->textarea(
      -name     => "fld_${f_key}",,
      -class    => 'blue',
      -default  => $val,
      -rows    => 5,
      -columns => 50,
        );
  } elsif ($f_type == $DB_BEN) {
    # Binary encoded fields get checkbox selectors.
    $ret = $cgi->textfield(
      -name => "fld_${f_key}",
      -default => "Checkbox: $val",
        );
  } elsif ($f_type == $DB_ORD) {
    # Ordinal values index into hash %tbl_{$fkey}
    $val = 0 unless (has_len($val) and $val);
    my %dtbl = createOrdinalHash($f_key);
    # Add null case.
    %dtbl = (0 => '', %dtbl);
    my @skeys = sort {$dtbl{$a} cmp $dtbl{$b}} keys %dtbl;
    $ret = $cgi->popup_menu(
      -name    => "fld_${f_key}",
      -values  => \@skeys,
      -labels  => \%dtbl,
      -default => $val,
        ) . "\n";
  } elsif ($f_type == $DB_CAP) {
    # Screen cap file: /img/capture/${table}/${table}_${ident}_${name}
    my $imgdir = "/img/cap/${stable}";
    
    my @imgfiles = extnFiles($imgdir);
    @imgfiles = sort(grep(/[^\.]/, @imgfiles));
    @imgfiles = sort(grep(/^${stable}_/, @imgfiles));
    @imgfiles = ("", @imgfiles);
    warn "radutils::valToTDedit(): files in $imgdir: " . join(" ", @imgfiles);
    
    $ret = $cgi->popup_menu(
      -name    => "fld_${f_key}",
      -values  => \@imgfiles,
      -default => $val,
        );
  } else {
    # All other fields (including formatted dates) go in a textarea.
    $ret = $cgi->textfield(
      -name => "fld_${f_key}",
      -default => $val,
        );
  }
}

# Return HTML for summary display of given value in this field.

sub valToTDsumm {
  my ($cgi, $dbh, $val, $field) = @_;
  my ($f_index, $f_key, $f_name, $f_type, $f_size, $f_ssize) = @{$field};

  my $ret = "";
  if ($f_type == $DB_CHR) {
    $ret = substr($val, 0, $f_ssize);
    $ret .= "..." if (length($val) > $f_ssize);
  } elsif ($f_type == $DB_BEN) {
    # Binary encoded: For now, just display the encoding value.
    $ret = $val;
  } elsif ($f_type == $DB_ORD) {
    $val = 0 unless (has_len($val) and $val);
    my %dtbl = createOrdinalHash($f_key);
    $ret = $dtbl{$val};
  } elsif ($f_type == $DB_DAT) {
    $ret = convert_date($val, $DATE_MDY);
  } else {
    $ret = $val;
  }
  $ret = "&nbsp;" unless (has_len($ret));
#   tt("radutils::valToTDsum($val): ($f_index, $f_key, $f_name, $f_type, $f_size, $f_ssize) returning $ret");
  return $ret;
}

# Return hash of text options for an ordinal hash.  If has had scalar elements, 
# return the same.  Otherwise create a hash of the FLD_NAM elements in hash.

sub createOrdinalHash {
  my ($f_key) = @_;

  my $tblname = "tbl_${f_key}";
  my %tbl = %{$tblname};
  # Check if each element is nonscalar, in which case use FLD_NAM
  my $ndxname = "${tblname}_index";
  my @tblndx = @{$ndxname};
  my %dtbl = ();
  if (scalar(@tblndx) == 1) {
    # Display original hash if it has scalar elements.
    %dtbl = %tbl;
  } else {
    ######################################################################
    # Build temporary hash (ugh!).  Might put this into a BEGIN block initially.
    my $namefieldindex = 0;
    foreach my $indexfield (@tblndx) {
      last if ($indexfield ==  $FLD_NAM);
      $namefieldindex++;
    }
    foreach my $key (keys %tbl) {
      my @hashelems = @{$tbl{$key}};
      $dtbl{$key} = $hashelems[$namefieldindex];
    }
  }
  return %dtbl;
}

sub sortedHeadingRow {
  my ($cgi, $order, $url, $keyptr, $hdgptr) = @_;
  my %hdg = %$hdgptr;
  my @keyvals = @$keyptr;

  my $retstr = "<tr>\n";
  foreach my $key (@keyvals) {
    my ($width, $title, $sortorder, $secondary, $secorder) = @{$hdg{$key}};

    # Set isSortKey if this is the sort key.
    my $porder = $order;
    $porder =~ s/\&nbsp\;/ /g;
    my (@order) = split(/[^a-zA-Z0-9\._]/, $porder);
    my $isSortKey = ($order[0] eq $key) ? 1 : 0;

    # Current desc/asc order (of field string in column heading) is:
    # If this is the sort key, then:
    # - Opposite of (second order key, if defined, else sort order); else
    # - Sort order.
    my $currentorder;	# That will be used if this col heading selected.
    if ($isSortKey) {
      if (has_len($order[1])) {
	$currentorder = ($order[1] eq "desc") ? $AS : $DE;
      } else {
	$currentorder = ($sortorder == $DE) ? $AS : $DE;
      }
    } else {
      $currentorder = $sortorder;
    }

    # Primary and secondary sorting strings.
    # asc/desc is reversed if currently-sorted column heading clicked.
    my $arrowimg = "";
    if ($isSortKey) {
      my $arrstr = ($currentorder == $AS) ? "down" : "up";
      $arrowimg = "&nbsp;<img src='/img/icon/arrow_${arrstr}.gif' title='' alt='x' />";
    }
    my $a_str = '';
    my $priord = "${key}&nbsp;$hdgorder{$currentorder}";
    my $secord = has_len($secondary) ? ",${secondary}&nbsp;$hdgorder{$secorder}" : "";
    my $tkey =  "${priord}&nbsp;${secord}";
    if ($sortorder) {
      $a_str = "class='orange_u' href='${url}?order=$tkey'";
    } else {
      $a_str = "class='orange'";
    }
    $retstr .= $cgi->th({-width => $width},
			"<a $a_str>${title}</a>${arrowimg}") . "\n";
  }
  $retstr .= "</tr>\n";
  return $retstr;
}

sub getParams {
  my ($cgi, @names) = @_;
  my @vals = ();

  foreach my $name (@names) {
    my $val = $cgi->param($name);
    $val = '' unless(defined($val));
    push(@vals, $val);
  }
  return @vals;
}

# Return value given, has zero length if param is undef;

sub definedVal {
  my ($val) = @_;
  $val = '' unless (has_len($val));
  return $val;
}

sub isNonZero {
  my ($val) = @_;

  my $isnz = 0;
  if (has_len($val)) {
    $isnz = 1 if ($val);
  }
  return $isnz;
}

# Given a program ID, or a pointer to a program details hash, 
# return full HTML code linking to program.pl, with hover image if available.

#  wideicons   	Each categ present ie 'plat_win__lin.png'
#  narricons   	Unused categs omitted ie 'plat_win_lin.png'
#  wideicons_t 	Wide icons with text tips.
#  narricons_t 	Narrow icons with text tips.
#  sortkeys    	Keys to hash, in order.
#  sortvals    	NB redundant since == @selvals{@sortedkeys}
#  vals        
#  valstr      	NB redundant since == join(" ", @sortedvals)
#  val_str     	val0_val1_val2 etc
#  tiptext            <div id="$val_str" class="tipContent">$tipstr</div>

#  progstr		

#  img_str    	Image string without tip text span class.
#  img_str_t  	Image string with tip text span class.
#  iface_tip  
#  iface_vals   # Goes in <div id="$val_str" class="tipContent">$tipstr</div>


sub makeProgramLink {
  my ($opts) = @_;
  my %opts = %$opts;

  my ($ident, $dbh, $maxlen, $isNew, $showimg) = @opts{qw(ident dbh maxlen isnew showimg)};
  # print STDERR "xxx makeProgramLink($ident, $dbh, $maxlen, $isNew)\n";
  # print STDERR "xxx $ident is new\n" if ($isNew);

  # If ident is a hash pointer, expand it, otherwise query database.
  my %prog = ();
  if (ref($ident) eq "HASH") {
    %prog = %$ident;
  } else {
    my $sstr = "select * from program where ident = '$ident'";
    my $sh = dbQuery($dbh, $sstr);
    if (my $aptr = $sh->fetchrow_hashref()) {
      %prog = %$aptr;
    }
  }
  
  my ($progstr, $prog_cvars) = ("", "");
  my ($capstr, $cap_cvars) = ("", "");
  my ($name, $capture, $plat, $interface);
  my $nsmimg = 0;
  if (scalar(keys(%prog))) {
    ($name, $ident, $capture, $plat, $interface) = @prog{qw(name ident capture plat interface)};
    my $tname = (has_len($maxlen)) ? truncateString($name, $maxlen) : $name;

     $tname .= " <b>(New)</b>" if ($isNew);
    
    # Progstr holds program name href'ed to program.pl
    my $hrefstr = "";
    $progstr = "<a href='/program/$ident'>$tname</a>";

    # Get info for small screen cap image.
    my $smstr = "select * from image";
    $smstr   .= " where rsrcid = '$ident'";
    $smstr   .= " and rsrcfld = 'prog'";
    $smstr   .= " and path = '$IMG_SMALLDIR'";
    $smstr   .= " and scale = '$IMG_SMALLDIM'";
    $smstr   .= " order by ordinal";
    # print STDERR "$smstr\n";
    my $smsh = dbQuery($dbh, $smstr);
    my @smptrs = ();
    while (my $smptr = $smsh->fetchrow_hashref()) {
      push(@smptrs, $smptr);
    }

    $nsmimg = scalar(@smptrs);
    if ($nsmimg) {
       my ($smptr) = randomSubset(\@smptrs, 1);

      my %smdet = %$smptr;
      my ($smwidth, $smheight, $smfilename) = @smdet{qw(width height filename)};

      my $class_thumb = "tip_thumb_${ident}";

       # Show count of images, not icon, if requested.
       if ($showimg) {
	 $capstr = "($nsmimg)";
       } else {
	 $capstr  = "<a href='/program/$ident'>";
	 $capstr .= "<img class='showTip $class_thumb' src='/img/icon/camera.png' border='0' title='' alt='X' />";
	 $capstr .= "</a>";
       }
      
      # content_vars js content for capture tipclass.
      my %cap_cvars = (
	'class'       => $class_thumb,
	'caption'     => $name,
	'img'         => "/img/cap/prog/${IMG_SMALLDIR}/${smfilename}",
	'w'           => $smwidth,
	'h'           => $smheight,
	'wrapFn'      => "dw_Tooltip.wrapImageToWidth",
	'followMouse' => "false",
	  );
      $cap_cvars = \%cap_cvars;
    } else {
      $capstr = "<img src='/img/icon/blank_16.png' title='' alt='X' />";
    }
  }

  # Get platform icons and context_vars for this program.
  my %platargs = (
    'hashname' => 'radutils::cat_plat',
    'sumval'   => $plat,
    'sortarr'  => 'radutils::cat_plat',
    'field'    => 'plat',
      );
  my $platlink = selectedVals(\%platargs);

  # Get interface icons and context_vars for this program.
  my %ifaceargs = (
    'hashname' => 'radutils::cat_interface',
    'sortarr'  => 'radutils::cat_interface',
    'sumval'   => $interface,
    'field'    => 'interface',
      );
  my $ifacelink = selectedVals(\%ifaceargs);

  # Return hash of values for cell contents and content_vars 
  # for program name, capture, platform, interface.
  my %proglink = (
    'progstr'     => $progstr,
    'prog_cvars'  => $prog_cvars,
    'capstr'      => $capstr,
    'cap_cvars'   => $cap_cvars,
    'platstr'     => $platlink->{'wideicons_t'},
    'plat_cvars'  => $platlink->{'cvars'},
    'ifacestr'    => $ifacelink->{'wideicons_t'},
    'iface_cvars' => $ifacelink->{'cvars'},
      );

#   printHash(\%proglink, "radutils::makeProgramLink($ident)");
  return \%proglink;
}

# Return a list of all secondary screen capture file names for this program.

sub getSecondaryScreenCaptures {
  my ($dbh, $ident) = @_;

  my $str  = "select * from resource";
  $str .= " where program = '$ident'";
  $str .= " and type = '$radutils::RES_IMG'";
  my $sh = dbQuery($dbh, $str);
  my @seccaps = ();
  while (my $href = $sh->fetchrow_hashref()) {
    my $imgname = $href->{'url'};
    push(@seccaps, $imgname);
  }
  return @seccaps;
}

sub printRowWhite {
  my ($txt, $width) = @_;

  my $widthstr = has_len($width) ? "width='${width}'" : "";
  print "<tr>\n<td $widthstr class='white'>\n$txt</td>\n</tr>\n";
}

sub printRowWhiteCtr {
  my ($txt, $width, $class) = @_;

  my $widthstr = has_len($width) ? "width='${width}'" : "";
  $class = $class || "white";
  print "<tr>\n<td $widthstr class='$class' align='center'>\n$txt\n</td>\n</tr>\n";
}

# Create a vertically-oriented table of given length, of random adverts from 'advertising'

sub createAdvertTable {
  my ($dbh, $num_ads) = @_;
  $num_ads = 0 unless (has_len($num_ads));

  # Fetch all adverts into an array.
  my $str = "select * from advertising";
  my $sh = dbQuery($dbh, $str);
  my @adverts = ();
  while (my $href = $sh->fetchrow_hashref()) {
    push(@adverts, $href);
  }

  # Select given number at random.
  my $nads = scalar(@adverts);
  my $niter = 0;
  my %sel_ads = ();
  while ((scalar(keys(%sel_ads)) < $num_ads) and ($niter < 1000)) {
    my $randomi = int(rand($nads));
    unless (defined($sel_ads{$randomi})) {
      $sel_ads{$randomi} = $adverts[$randomi];
    }
    # Prevents infinite loop in case num_ads > nads (ads available).
    $niter++;
  }

  # Now have <= num_ads database records in %sel_ads.
  my $tablestr = "";
  $tablestr .= "<table width='150' border='0' cellpadding='0' cellspacing='5'>\n";
  foreach my $key (keys %sel_ads) {
    my $advert = $sel_ads{$key};
    my $ad_text = $advert->{'text'};
    $ad_text =~ s/&/&amp;/g;
    $tablestr .= "<tr>\n";
    $tablestr .= "<td class='r_advert' width='150'>$ad_text</td>\n";
    $tablestr .= "</tr>\n";
  }
  $tablestr .= "</table>\n";
  
  return $tablestr;
}

# Print everything after <body> and before page content.
# Prints title, navigation code, top advertising.

sub printPageIntro {
  my ($wide, $currpage) = @_;
  my $tablewidth = ($wide) ? ($TABLEWIDTH + 200) : $TABLEWIDTH;

  print comment("printPageIntro(): Overall page table is $tablewidth");
  my $imgstr = "/img/title/idoimaging_title.png";
  my $titlestr = "<a href='/index.php'><img border='' src='$imgstr' title='' alt='I Do Imaging' /></a>";

  # Table containing everything in page body.
  print "<table width='$tablewidth' border='0' cellpadding='5' cellspacing='0'>\n";

  # Row 1: Navigation code.
  my $navstr = makeNavCode($currpage);
  print comment(" Main table row for navigation table ");
  print "<tr>\n<td class='white' width='$tablewidth' align='center'>\n";
  print "${navstr}\n</td>\n</tr>\n";
  print comment(" End main table row for navigation table ");

  # Row 2: Page-top advertising.
  print comment(" Main table row for page-top advertising ");
  # Choice of 2 files.
  # my $adfile = (int(rand(2))) ? "advertising.html" : "advertising1.html";
  my $adfile = "advertising.html";
  my @adcontents = fileContents($adfile);
  # Suppress advertising on local computer...
  my $adcontents = join("\n", @adcontents);
  printRowWhiteCtr($adcontents, $tablewidth);
  print comment(" End of table row for page-top advertising");
}

sub makeNavCode {
  my ($currpage) = @_;

  my $navstr = '';
  $navstr .= comment("========== Navigation code ==========");

  $navstr .= "<div class='navcontainer'>\n";
  $navstr .= "<ul class='step1 step2 step3 step4'>\n";
  foreach my $page ($NAV_HOME..$NAV_ABOUT) {
    my $navtext = $nav{$page}->[0];
    my $navaction = $nav{$page}->[1];
      
    if ($navaction !~ /blog/) {
      $navaction = "/${navaction}";
    }

    (my $idstr = $navtext) =~ s/\s/_/g;
    my $classstr = '';
    if (has_len($currpage)) {
      $classstr = ($page == $currpage) ? " class='active'" : "";
    }
    my $astr = "<a href='$navaction'>$navtext</a>";
    $navstr .= "<li id='$idstr'${classstr}>$astr</li>\n";
  }
  $navstr .= "</ul>\n";
  $navstr .= "</div>\n";
  $navstr .= comment("========== End navigation code ==========");
  return $navstr;
}
 
# Return ptr to hash matching input hash, but with values truncated to given length
#   hptr  : Pointer to hash.
#   vallen: Length to truncate value to.
#   index : If present, index to use into array of hash values.

sub truncateHashVals {
  my ($hptr, $vallen, $index) = @_;
  $vallen = '' unless (has_len($vallen) and $vallen);

  croak("Not a hash ref: $hptr") unless (ref($hptr));
  my %inhash = %{$hptr};
  my %outhash = ();
  foreach my $key (keys %inhash) {
    my $val = has_len($index) ? ${$inhash{$key}}->[$index] : $inhash{$key};
    $val = ($vallen) ? substr($val, 0, $vallen) : $val;
    $outhash{$key} = $val;
  }
  return \%outhash;
}

sub makeIfaceCell {
  my ($val) = @_;
  my @tips = ();

  my $imgname = "interface";
  foreach my $if_key ($radutils::IF_GUI, $radutils::IF_CMD, $radutils::IF_API) {
    if ($val & $if_key) {
      $imgname .= "_$interface_icons{$if_key}->[0]";
      push (@tips, $interface_icons{$if_key}->[1]);
    } else {
      $imgname .= "_";
    }
  }
  $imgname .= ".png";
  # print STDERR "radutils::makeIfaceCell(): imgname $imgname\n";
  my $valstr = join(", ", @tips);
  my $val_str = join("_", @tips);
  $val_str =~ s/\ /_/g;
  my $tipstr = "Interfaces: $valstr";
  $tipstr = "<div id='$val_str' class='tipContent'>$tipstr</div>";

#   my $cellstr = "<span title='$tipstr'></span>";
#   return $cellstr;
  my $iconstr = "<img src='/img/icon/$imgname' border='0' title='' alt='interface' />";
  my $icons_t = "<span class='showTip $val_str'>$iconstr</span>";

  my %ret = (
    'img_str'    => $iconstr,	# Image string without tip text span class.
    'img_str_t'  => $icons_t,	# Image string with tip text span class.
    'iface_tip'  => $tipstr,
    'iface_vals' => $val_str,   # Goes in <div id="$val_str" class="tipContent">$tipstr</div>
      );
#   printHash(\%ret, "makeifacecell");
  return \%ret;
}

sub printToolTips {
  my ($tipstrs, $doAdd) = @_;
  my %tipstrs = %$tipstrs;
  $doAdd = 0 unless (has_len($doAdd) and $doAdd);

  print comment("============================================================");
  print comment("javascript for tooltip content_vars");
  print "<script type='text/javascript'>\n";
  unless ($doAdd) {
    print "dw_Tooltip.content_vars = {\n";
  }
  my $ntips = scalar(keys %tipstrs);
  my $tipn = 1;
  foreach my $tipclass (sort keys %tipstrs) {
    my $tip = $tipstrs{$tipclass};
    my %tip = %$tip;
    if ($doAdd) {
      print "  dw_Tooltip.content_vars[\"${tipclass}\"] = {\n";
    } else {
      print "  ${tipclass}: {\n";
    }
    my @tipkeys = sort keys %tip;
    my $nkeys = scalar(@tipkeys);
    my $i = 1;
    foreach my $tipkey (@tipkeys) {
      next if ($tipkey =~ /class/);
      my $comma = ($i++ >= ($nkeys - 1)) ? "" : ",";
      my $val = $tip{$tipkey};
      $val = "\"$val\"" if ($tipkey =~ /str|caption|img/);
      print "    ${tipkey}: ${val}${comma}\n";
    }
    my $tipcomma = ($doAdd or ($tipn++ >= $ntips)) ? "" : ",";
    print "  }${tipcomma}\n";
  }
  unless ($doAdd) {
    print "}\n";
  }
  print "</script>\n";
}

# Add tooltip objects to variable tipstrs if not already defined.
# Keys '*_cvars' in hashptr point to tooltip objects identified by 'class' field.
#   hashptr: Ptr to hash with some cvars elements identified by key = '*_cvars'.
#   tipstrs:  Ptr to hash with elements being cvars objects.

sub addCvars {
  my ($hashptr, $tipstrs) = @_;
  my %hash = %$hashptr;

  my @hashkeys = sort keys %hash;
  foreach my $key (grep(/cvars/, @hashkeys)) {
    my $tipobj = $hash{$key};
    if (has_len($tipobj)) {
      my $tipclass = $tipobj->{'class'};

      if ($key =~ /auth_cvars/) {
        my %hash = %$tipobj;
        foreach my $key (keys %hash) {
        }
      }
      $tipstrs->{$tipclass} = $tipobj unless (exists($tipstrs->{$tipclass}));

    }
  }
}

# Return ptr to hash of cvars values for a text tooltip.
# Required parameter keys: class, str.

sub make_cvars_text {
  my ($args) = @_;

  my %ret = (
    'class'       => $args->{'class'},
    'str'         => $args->{'str'},
    'wrapFn'      => "dw_Tooltip.wrapToWidth",
    'followMouse' => "false",
      );
  return \%ret;
}

# Return an SQL string of field name-value matches for given hash.
# Skips field names prefixed with '_'.
#   sepstr:   Separator ',' or 'and'.
#   indexptr: Optional array of field names to include, in order.

sub conditionString {
  my ($dptr, $sepstr, $indexptr) = @_;
  $sepstr = ", " unless (defined($sepstr) and length($sepstr));

  my $str = "";
  my $separator = "";
  my @indices = (has_len($indexptr) ? @{$indexptr} : sort keys %$dptr);
  foreach my $key (@indices) {
    next if ($key =~ /^_/);
    my $val = (has_len($dptr->{$key}) ? $dptr->{$key} : '');
    $str .= " ${separator} $key = '$val'";
    $separator = $sepstr;
  }
  $str =~ s/\ +/\ /g;
#  print "MySQL::conditionString(): $str\n";
  return $str;
}

# Return hash of screen capture images.
# Structure: (ordinal -> scale -> (hash of values)).

sub getCaptureImages {
  my ($dbh, $progid, $maxsize) = @_;

  my $sqlstr = "select * from image";
  $sqlstr   .= " where rsrcfld = 'prog'";
  $sqlstr   .= " and rsrcid = '$progid'";
  my $sh = dbQuery($dbh, $sqlstr);
  my %dbrecs = ();
  while (my $dbrec = $sh->fetchrow_hashref()) {
    my %dbrec = %$dbrec;
    my ($ordinal, $scale) = @dbrec{qw(ordinal scale)};
    $dbrecs{$ordinal}{$scale} = $dbrec;
  }
#   foreach my $ord (sort {$a <=> $b} keys %dbrecs) {
#     my %ordhash = %{$dbrecs{$ord}};
#     foreach my $scal (sort keys %ordhash) {
#       my $imgptr = $ordhash{$scal};
#       printHash($imgptr, "Ord $ord, Scale $scal");
#     }
#   }

  return \%dbrecs;
}

# Return random subset length n of given array.
sub randomSubset {
  my ($aref, $maxlen) = @_;
  my @arr = @$aref;

  my $narr = scalar(@arr);
  my $len = ($maxlen < $narr) ? $maxlen : $narr;
  my %index = ();
  while (scalar(keys(%index)) < $len) {
    my $index = int(rand($narr));
    $index{$index} = 1 unless (defined($index{$index}));
  }
  my @index = sort keys %index;
  my @subset = @arr[@index];
  return @subset;
}

sub allProgNames {
  my ($dbh) = @_;
  
  my %allprogs = ();
  my $pstr = "select ident, name from program";
  my $p_sh = dbQuery($dbh, $pstr);
  while (my $p_rec = $p_sh->fetchrow_hashref()) {
    $allprogs{$p_rec->{'ident'}} = $p_rec->{'name'};
  }
  return %allprogs;
}

# Write file of given name with given contents.
# If contents are array ref, print newline-delimited.
# Return 0 on success, else 1.

sub write_file {
  my ($outfile, $contents) = @_;

  if (ref($contents) eq "ARRAY") {
    unless ($contents->[0] =~ /\n/) {
      $contents = join("\n", @{$contents}) . "\n";
    } else {
      $contents = join("", @{$contents}) . "\n";
    }
  }
  unless (open(OUTFILE, '>', $outfile)) {
    warn "ERROR FileUtilities::writeFile(): Could not open $outfile\n";
    return 1;
  }
  print OUTFILE $contents;
  close(OUTFILE);
  return 0;
}

# Returns hash of (urlstr, iconstr, tipstr, tipclass).

sub make_monitor_details {
  my ($userid, $progid, $is_monitored, $can_monitor, $included) = @_;

  my $is_logged_in = defined($userid);
  my ($monitored, $monitortip) = ("", "");
  my $userstr = ($is_logged_in) ? "${OBF_USERID}=" . $userid * $OBFUSCATOR : '';

  # Determine the lookup string for %prog_actions.
  # Stored as octal 0abc where a = user_page, b = logged_in, c = is_monitored.
  my $lookup = 0;
  $lookup |= (1 << 0 * 3) if ($is_monitored);	# Program is monitored.
  $lookup |= (1 << 1 * 3) if ($is_logged_in);	# User is logged in.
  $lookup |= (1 << 2 * 3) if ($included);	# Is user_home page (not programs.pl)

  my ($icon, $url, $tip);
  if ($can_monitor) {
    my $aptr = $prog_actions{$lookup};
    ($icon, $url, $tip) = @$aptr;
  } else {
    ($icon, $url, $tip) = @no_monitor_actions;
  }

  my $addurlstr = '';
  if (has_len($url)) {
    $addurlstr = "/$url";
    my @params = ();
    push(@params, "progid=$progid") if (has_len($progid));
    push(@params, $userstr) if ($is_logged_in);
    foreach my $param (@params) {
      my $sep = ($addurlstr =~ /\?/) ? '&amp;' : '?';
      $addurlstr .= "${sep}$param";
      # tt("$addurlstr .= '${sep}' '$param'");
    }
  }
  my $showclass = "tip_class_$lookup";
  my $iconstr = "<img class='showTip $showclass' border='0' src='/img/icon/$icon' alt='$tip->[$TIP_ALT]' />";

  $monitortip =  make_cvars_text({
    'class' => $showclass,
    'str'   => $tip->[$TIP_TEXT],
  });

#  print STDERR "id $progid, is_mon $is_monitored, is_log $is_logged_in, incl $included, lookup = $lookup: icon '$icon', url '$url', tip0 '$tip->[$TIP_ALT]'\n";

  my %ret = (
    $MON_URL   => $addurlstr,
    $MON_ICON  => $iconstr,
    $MON_CVARS => $monitortip,
    $MON_TIPCL => $showclass,
    $MON_TEXT  => $tip->[$TIP_VERB],
  );
  return \%ret;
}

# Ensure logged-in user is admin, or running from command line.

sub is_admin_or_cli {
  my ($do_print) = @_;
  $do_print //= 0;

  my $ret = 0;
  if (is_apache_environment()) {
    my $det = get_user_details();
    if ($det and $det->{$Userbase::UB_IS_ADMIN}) {
      $ret = 1;
    } else {
      print "<tt>I don't think so.</tt><br>\n" if ($do_print);
    }
  } else {
    print "Command line: You may proceed.\n" if ($do_print);
    $ret = 1;
  }
  return $ret;
}

1;

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <?php virtual("print_page_head.php"); ?>
</head>
<body>

  <?php virtual("/pageintro"); ?>



<tr height=22>
<td class='white' valign=top>
<center><h1>Programs Available for Download</h1></center>

<h2>dicomviewer</h2>

The Java source and class files are available here.  They are hosted on this site as the original host site is no longer active.
<br>
<a class='green' href='http://www.idoimaging.com/programs_src/dicomviewer/dicomviewer054.zip'>
<img border=0 src='img/tgz-48x48.png'>&nbsp;dicomviewer054.zip</a> (133 kB) 

<h2>readPET</h2>

readPET reads GE PET files in GE ADVANCE or GE6 (Scanditronix)
formats.  You can dump the header of the files, or convert them to raw
or Analyze format files.  It is written in Standard C++ and compiles
on Unix and Windows machines.

<pre>
usage: readPET &lt;inputfiles&gt; [-abhlmptvw]
   -a: Analyze:     Convert to Analyze format.
   -b: Becquerels:  Use units of MBq/cc (default is nCi/cc).
   -d: Debug:       Print debugging information.
   -h: Header:      Print short header to screen.
   -l: Long Header: Print LONG! header to screen.
   -m: Mean Image:  Calculate mean image and write to disk.
   -p: Parametric:  Calculate parametric image files.
                    Model and slice range: -pMXX or -pMXX-YY.
                    Model M = (P)atlak or (L)ogan.
                    Slices XX to YY (0 indexed) inclusive.
   -t: Times:       Write temporal information to text file.
   -v: Volume:      Save all frames in one volume file.
   -w: Write:       Write data frames to disk.
</pre>

The option <tt>'-a'</tt> will convert the files to Analyze format
file pairs (<tt>*.img</tt>/<tt>*.hdr</tt>).  By default, one file
will be created per time frame; ie, a dynamic scan will result in the
creation of multiple Analyze files.  The file name root is take from
the subject's name in the file header.
<br>
The option <tt>'-h'</tt> will dump the header elements.
<br>
Timing information is difficult to store in the Analyze format as there 
is no header element for it.  So I encode frame start/stop times in the
(usually) unused field 'descrip' (between glmax and aux_file).  The 
format of the entry is:<br>
<tt>frmS    300, frmD     60, scanS  30486</tt><br>
These are frame start time and duration, and scan start time since 
midnight, all in seconds.<br>
The <tt>-t</tt> option causes a text file to be written containing 
all the timing information.  It looks like:<br>
<pre>
# This file holds PET scan frame times.
# FRAMES    line holds number of frames.
# INJECTION line holds injection time (hh:mm:ss)
# FRAMEnn   lines hold start time for frame n
#           (hh:mm:ss) and duration (ss)
FRAMES          24
INJECTION       09/14/2000   08:28:06
FRAME00 0       15
FRAME01 15      15
FRAME02 30      15
</pre>
<p>
Future enhancements include DICOM as an output format.  Write to me if
you'd like to see this option.
<p>
Download C++ source code: 
<a class='green' href='http://www.idoimaging.com/programs_src/readPET/readPET.tar.gz'>
<img border=0 src='img/icon/winzip.gif'>&nbsp;readPET.tar.gz</a> (56 kB) 
&nbsp;&nbsp;
<a class='green' href='http://www.idoimaging.com/programs_src/readPET/readPET.zip'>
<img border=0 src='img/icon/winzip.gif'>&nbsp;readPET.zip</a> (57 kB) 

<br>
Download Windows executable (command line program):
<a class='green' href='http://www.idoimaging.com/programs_src/readPET/readPET.exe'>
<img border=0 src='img/icon/windows.gif'>&nbsp;readPET.exe</a> (2.5 MB)

<br>
<tt>New!</tt>Download Mac OSX executable (command line program):
<a class='green' href='http://www.idoimaging.com/programs_src/readPET/readPET_OSX'>
<img border=0 src='img/icon/macintosh.gif'>&nbsp;readPET_OSX</a> (3.1 MB)

<br>
<tt>New!</tt>Download Solaris 8 executable (command line program):
<a class='green' href='http://www.idoimaging.com/programs_src/readPET/readPET_solaris'>
<img border=0 src='img/icon/solaris.gif'>&nbsp;readPET_solaris</a> (4.1 MB)

</table>

<!--#include virtual="footer.shtml" -->
</body>

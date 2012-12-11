#! /bin/tcsh -f

set LBIN=/Users/ahc/BIN
set WD=/Users/ahc/public_html
set RSYNC="rsync -tq --exclude-from=${WD}/idoimaging/rsync_exclude.txt"
set SSH="ssh acrabb@galeras.pair.com"
set CHMOD644="chmod 644"
set CHMOD755="chmod 755"
set CHMOD700="chmod 700"
set CHMOD600="chmod 600"

set PAIR=acrabb@galeras.pair.com:public_html
set MEDI=acrabb@galeras.pair.com:public_html/medimageworks
set TEST=acrabb@galeras.pair.com:public_html/test
set PBIN=acrabb@galeras.pair.com:BIN

$RSYNC ${WD}/idoimaging/index.php                 ${PAIR}/
$RSYNC ${WD}/idoimaging/idoimaging_php.css        ${PAIR}/
$RSYNC ${WD}/idoimaging/php/*.php                 ${PAIR}/php/
$RSYNC ${WD}/idoimaging/ub_login/ubvars.php          ${PAIR}/ub_login/
$RSYNC ${LBIN}/php/*.php                          ${PBIN}/php/

$SSH "${CHMOD644} public_html/*.php"
$SSH "${CHMOD644} public_html/*.css"
$SSH "${CHMOD644} public_html/php/*.php"
$SSH "${CHMOD644} public_html/login/*.php"
$SSH "${CHMOD644} BIN/php/*.php"

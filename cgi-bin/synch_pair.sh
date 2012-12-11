#! /bin/tcsh -f

set WD=/Users/ahc/public_html
set RSYNC="rsync -tv --exclude-from=${WD}/idoimaging/rsync_exclude.txt"
set SSH="ssh acrabb@galeras.pair.com"
set CHMODR="chmod 644 public_html"
set CHMOD7="chmod 755 public_html"
set CHMOD6="chmod 644 public_html"

set PAIR=acrabb@galeras.pair.com:public_html
set MEDI=acrabb@galeras.pair.com:public_html/medimageworks
set TEST=acrabb@galeras.pair.com:public_html/test
set CGIB=acrabb@galeras.pair.com:public_html/cgi-bin

$RSYNC ${WD}/cgi-bin/imaging/*.p?               ${CGIB}/imaging/
$RSYNC ${WD}/.htaccess                          ${PAIR}/
$RSYNC ${WD}/idoimaging/*html                   ${PAIR}/
$RSYNC ${WD}/idoimaging/*.css                   ${PAIR}/
$RSYNC ${WD}/idoimaging/js/*.js                 ${PAIR}/js/
$RSYNC ${WD}/idoimaging/robots.txt              ${PAIR}/
$RSYNC ${WD}/idoimaging/img/*.png               ${PAIR}/img/
$RSYNC ${WD}/idoimaging/img/*.jpg               ${PAIR}/img/
$RSYNC ${WD}/idoimaging/img/*.gif               ${PAIR}/img/
$RSYNC ${WD}/idoimaging/img/nav/*               ${PAIR}/img/nav/
$RSYNC ${WD}/idoimaging/img/title/*             ${PAIR}/img/title/
$RSYNC ${WD}/idoimaging/img/icon/*              ${PAIR}/img/icon/
$RSYNC ${WD}/idoimaging/img/icon/links/*        ${PAIR}/img/icon/links/
$RSYNC ${WD}/idoimaging/img/icon/flags/png/*    ${PAIR}/img/icon/flags/png/
$RSYNC ${WD}/idoimaging/img/email/*             ${PAIR}/img/email/
$RSYNC ${WD}/idoimaging/img/cap/prog/*          ${PAIR}/img/cap/prog/
$RSYNC ${WD}/idoimaging/img/cap/prog/sm/*       ${PAIR}/img/cap/prog/sm/
$RSYNC ${WD}/idoimaging/phpmylist/*             ${PAIR}/phpmylist/
$RSYNC ${WD}/idoimaging/phpmylist/*             ${PAIR}/phpmylist/
$RSYNC ${WD}/idoimaging/programs/readPET/*      ${PAIR}/programs/readPET/
$RSYNC ${WD}/idoimaging/programs/dicomviewer/*  ${PAIR}/programs/dicomviewer/
#
$RSYNC ${WD}/medimageworks/*html                   ${MEDI}/
#
$RSYNC ${WD}/test/*html                            ${TEST}/
$RSYNC ${WD}/test/.htaccess                        ${TEST}/

$SSH "${CHMODR}/*html"
$SSH "${CHMODR}/img/*.png"
$SSH "${CHMODR}/img/nav/*.png"
$SSH "${CHMODR}/img/title/*"
$SSH "${CHMODR}/img/icon/*.png"
$SSH "${CHMODR}/img/icon/*.gif"
$SSH "${CHMODR}/img/icon/*.jpg"
$SSH "${CHMODR}/img/icon/links/*.png"
$SSH "${CHMODR}/img/icon/flags/png/*.png"
$SSH "${CHMODR}/img/*.jpg"
$SSH "${CHMODR}/img/*.gif"
$SSH "${CHMODR}/img/email/*.gif"
$SSH "${CHMODR}/img/cap/prog/prog_*"
$SSH "${CHMODR}/img/cap/prog/sm/prog*"
$SSH "${CHMOD7}/cgi-bin/imaging/*.pl"
$SSH "${CHMOD6}/cgi-bin/imaging/*.pm"

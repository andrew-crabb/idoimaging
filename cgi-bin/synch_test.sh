#! /bin/tcsh -f

# Synchs a current copy of idoimaging.com onto medimageworks.com
# This is physically the directory 'medimageworks' under www.idoimaging.com

set WD=/Users/ahc/public_html
set RSYNC="rsync -tv --exclude-from=${WD}/idoimaging/rsync_exclude.txt"
set SSH="ssh acrabb@galeras.pair.com"
set CHMODR="chmod 644 public_html/medimageworks"
set CHMOD7="chmod 700 public_html/medimageworks"
set CHMOD6="chmod 600 public_html/medimageworks"

set MEDI=acrabb@galeras.pair.com:public_html/medimageworks
set CGIB=acrabb@galeras.pair.com:public_html/medimageworks/cgi-bin

$RSYNC ${WD}/cgi-bin/imaging/*.p?                    ${CGIB}/imaging/
$RSYNC ${WD}/idoimaging/*html                        ${MEDI}/
$RSYNC ${WD}/idoimaging/*.css                        ${MEDI}/
$RSYNC ${WD}/idoimaging/*.js                         ${MEDI}/
$RSYNC ${WD}/idoimaging/robots.txt                   ${MEDI}/
$RSYNC ${WD}/idoimaging/img/*.png                    ${MEDI}/img/
$RSYNC ${WD}/idoimaging/img/*.jpg                    ${MEDI}/img/
$RSYNC ${WD}/idoimaging/img/*.gif                    ${MEDI}/img/
$RSYNC ${WD}/idoimaging/img/nav/*                    ${MEDI}/img/nav/
$RSYNC ${WD}/idoimaging/img/email/*                  ${MEDI}/img/email/
# $RSYNC ${WD}/idoimaging/img/capture/program/*        ${MEDI}/img/capture/program/
# $RSYNC ${WD}/idoimaging/img/capture/program/thumb/*  ${MEDI}/img/capture/program/thumb/
# $RSYNC ${WD}/idoimaging/phpmylist/*                  ${MEDI}/phpmylist/
# $RSYNC ${WD}/idoimaging/phpmylist/*                  ${MEDI}/phpmylist/
# $RSYNC ${WD}/idoimaging/programs/readPET/*           ${MEDI}/programs/readPET/
# $RSYNC ${WD}/idoimaging/programs/dicomviewer/*       ${MEDI}/programs/dicomviewer/
#
#

$SSH "${CHMODR}/*html"
$SSH "${CHMODR}/img/*.png"
$SSH "${CHMODR}/img/nav/*.png"
$SSH "${CHMODR}/img/*.jpg"
$SSH "${CHMODR}/img/*.gif"
$SSH "${CHMODR}/img/email/*.gif"
$SSH "${CHMODR}/img/capture/program/program_*"
$SSH "${CHMOD7}/cgi-bin/imaging/*.pl"
$SSH "${CHMOD6}/cgi-bin/imaging/*.pm"


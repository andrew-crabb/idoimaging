#! /bin/tcsh -f

set WD=/Users/ahc/public_html
set BIN=/Users/ahc/BIN/perl
set RSYNC="rsync -ti --exclude-from=${WD}/idoimaging/rsync_exclude.txt"
set SSH="ssh ahc@idoimaging.macminicolo.net"
set CHMODR="chmod 644 public_html"
set CHMOD7="chmod 755 public_html"
set CHMOD6="chmod 644 public_html"

set MMC=ahc@idoimaging.macminicolo.net:public_html/idoimaging
set CGIB=ahc@idoimaging.macminicolo.net:public_html/cgi-bin

# $RSYNC ${WD}/cgi-bin/imaging/*.p?               ${CGIB}/imaging/
# $RSYNC ${WD}/idoimaging/.htaccess               ${MMC}/
# $RSYNC ${WD}/idoimaging/*html                   ${MMC}/
# $RSYNC ${WD}/idoimaging/*php                    ${MMC}/
# $RSYNC ${WD}/idoimaging/php/*php                ${MMC}/php/
# $RSYNC ${WD}/idoimaging/*.css                   ${MMC}/
$RSYNC ${WD}/idoimaging/js/*.js                 ${MMC}/js/
$RSYNC ${WD}/idoimaging/robots.txt              ${MMC}/
$RSYNC ${WD}/idoimaging/img/*.png               ${MMC}/img/
$RSYNC ${WD}/idoimaging/img/*.jpg               ${MMC}/img/
$RSYNC ${WD}/idoimaging/img/*.gif               ${MMC}/img/
$RSYNC ${WD}/idoimaging/img/nav/*               ${MMC}/img/nav/
$RSYNC ${WD}/idoimaging/img/title/*             ${MMC}/img/title/
$RSYNC ${WD}/idoimaging/img/icon/*              ${MMC}/img/icon/
$RSYNC ${WD}/idoimaging/img/icon/links/*        ${MMC}/img/icon/links/
$RSYNC ${WD}/idoimaging/img/icon/flags/png/*    ${MMC}/img/icon/flags/png/
$RSYNC ${WD}/idoimaging/img/email/*             ${MMC}/img/email/
$RSYNC ${WD}/idoimaging/img/cap/prog/*          ${MMC}/img/cap/prog/
$RSYNC ${WD}/idoimaging/img/cap/prog/sm/*       ${MMC}/img/cap/prog/sm/

$SSH "${CHMODR}/*html"
$SSH "${CHMODR}/*php"
$SSH "${CHMODR}/php/*php"
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

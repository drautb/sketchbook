#!/usr/bin/env sh

LDS_LOGIN_SCRIPT=~/GitHub/drautb/sketchbook/js/paas-portal/portal.js
PORTAL_LOGIN_SCRIPT=~/GitHub/drautb/sketchbook/racket/paas-portal.rkt

$PORTAL_LOGIN_SCRIPT $(casperjs $LDS_LOGIN_SCRIPT $LDS_USER $LDS_PASSWORD) $1

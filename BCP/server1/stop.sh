#!/bin/ksh
TOMCAT=/opt/DMS/tomcat
CATALINA_HOME=/apps/mwauto/links/tomcat9_current
export CATALINA_HOME
APP_LIST="webtop ewebtop da iam server3"

if [[ $1 == "all" ]]; then
  for app in $APP_LIST; do
    CATALINA_BASE=$TOMCAT/$app
    export CATALINA_BASE
    $CATALINA_HOME/bin/shutdown.sh
  done
else
  CATALINA_BASE=$TOMCAT/$1
  export CATALINA_BASE
  $CATALINA_HOME/bin/shutdown.sh
fi

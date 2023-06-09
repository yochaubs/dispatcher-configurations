#!/bin/bash
#
# Following are the key steps I did to update redirects automatically after publishing.
# Thanks again Dan and Ahmed!
#
# 1. Create one or more redirect "pages" on http://localhost:4502/miscadmin#/etc/acs-commons/redirect-maps.
#    In this example, we're using dummy names of web-301 and web-302.
#
# 2. Create a folder on the Dispatcher server owned by apache:apache.  Our folder is:
#    /etc/aem/scripts/redirect-map-manager.
#
#
# 4. Add one line to dispatcher.any, under /cache:
#    # /cache
#      # {
#      # /docroot "/var/www/html"
#      # Here's the line we added, which automatically passes the path that holds all the authorable redirect "pages":
#      /invalidateHandler "/etc/aem/scripts/redirectmap.sh"
#
#    # Or to run a cron job every 10 minutes, we'd need to explicitly pass the path param:
#    # */10 * * * * /etc/aem/scripts/redirectmap.sh /etc/acs-commons/redirect-maps/
#
# 5. Add one entry in httpd.conf for each unique map you're creating, e.g.:
#    # Custom redirect grouping #1.  Use more descriptive names than these!
#    RewriteMap map.web301 dbm:/etc/httpd/conf.d/redirectmap/web-301.map
#    RewriteCond ${map.web301:$1} !=""
#    RewriteRule ^(.*)$ ${map.web301:$1|/} [L,R=301]
#
#

LOG_FILE="/data/logs/update-redirect-map.log"
# replace the ip address with publish ip address
PUBLISHER_IP="10.154.1.18"
REDIRECT_MAP_FOLDER="/etc/httpd/conf.d/redirectmap"

echo "Preparing to update redirects."

MAPS=(
  "web-301"
  "web-302"

)

for MAP_FILE in "${MAPS[@]}"
do
  rm /data/tmp/${MAP_FILE}.txt
  # Your server admin should do something to hide the password.  You could also configure anonymous access to the file in AEM if that's permitted by your security team.
  curl -o "/data/tmp/${MAP_FILE}.txt" "http://${PUBLISHER_IP}:4503/etc/acs-commons/redirect-maps/${MAP_FILE}/jcr:content/redirectMap.txt" >> "$LOG_FILE" 2>&1
  # Temporarily create the map files with "tmp-" in the name, and then rename them immediately after.
  httxt2dbm -i "/data/tmp/${MAP_FILE}.txt" -o "$REDIRECT_MAP_FOLDER/tmp-${MAP_FILE}.map" >> "$LOG_FILE" 2>&1
  mv "$REDIRECT_MAP_FOLDER/tmp-${MAP_FILE}.map.dir" "$REDIRECT_MAP_FOLDER/${MAP_FILE}.map.dir"
  mv "$REDIRECT_MAP_FOLDER/tmp-${MAP_FILE}.map.pag" "$REDIRECT_MAP_FOLDER/${MAP_FILE}.map.pag"
done

echo "Finished updating redirects."

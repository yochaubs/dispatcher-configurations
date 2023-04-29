#!/bin/bash

CACHEDIRS="/etc/httpd/temp/cachedir.vars"
REDIRECTMAPENTRY="/etc/httpd/temp/redirectmapentry"
VHOST_PATTERN="/etc/httpd/conf.d/available_vhosts/*.vhost"
#VHOST_DIR="/etc/httpd/conf.d/enabled_vhosts"

FARM_PATTERN="/etc/httpd/conf.dispatcher.d/available_farms/*.any"
#FARM_DIR="/etc/httpd/conf.d/enabled_farms"

#create backup directory if not exist
if [ ! -d /data/dispatcher/backup ]; then
   sudo mkdir -p /data/dispatcher/backup
fi

#create backup of dispatcher
sudo zip -r "/data/dispatcher/backup/$(date +'%m%d%Y-%s').zip" /etc/httpd/conf.d/ /etc/httpd/conf.dispatcher.d/ /etc/sysconfig/httpd

#unzip artifacts
sudo unzip -o  /data/dispatcher/deploy/"$(filename)" -d /etc/httpd/

echo "adding cache directory"
if [[ -e $CACHEDIRS ]]
        then
                while IFS= read -r line
                        do
                          #echo "$line"
                         if  ! grep -Fxq "$line" /etc/sysconfig/httpd
                            then
                                  echo "Add $line"
                                  sudo echo "$line" >> /etc/sysconfig/httpd
                         fi
                        done <"$CACHEDIRS"
fi

if [ ! -d /etc/httpd/conf.d/redirectmap ]; then
   sudo mkdir -p /etc/httpd/conf.d/redirectmap
fi

echo "creating static redirectmap entry"
if [[ -e $REDIRECTMAPENTRY ]]
  then
        while IFS= read -r file
                do
                 if [[ ! -e $file ]]
                  then
                        sudo touch "$file"
                fi
                done <"$REDIRECTMAPENTRY"
fi

# create symlink for pattern
function createSymlink(){
        for FILE in $1
        do

                IDENTIFIER="$(echo "$FILE" | awk -F/ '{print$(NF-1)}')"
                TARGET="$(echo "$FILE" | awk -F/ '{print$(NF)}')"

                if [[ "$IDENTIFIER" == "available_vhosts" ]]
                then
                        TARGET_LINK="/etc/httpd/conf.d/enabled_vhosts/$TARGET"
                else
                        TARGET_LINK="/etc/httpd/conf.dispatcher.d/enabled_farms/$TARGET"
                fi
                if [ ! -h "$TARGET_LINK" ]; then
                    echo "Source .. $FILE Target.. $TARGET_LINK"
                    sudo ln -s "$FILE" "$TARGET_LINK"
                fi
        done

}

createSymlink "$VHOST_PATTERN"
createSymlink "$FARM_PATTERN"


echo " Initate configuration validation"
if sudo service httpd configtest 2>&1 | grep -Fxq 'Syntax OK'; then
        echo "Syntax OK. Initate Apache restart"
        var=$(sudo service httpd restart  2>&1)
        if [[ "$var" == "Redirecting to /bin/systemctl restart httpd.service" ]]
        then
                echo "Apache Restart Done"
        else
                echo "Apache restart failed. Please correct the errors"
        fi
else
       sudo service httpd configtest
fi

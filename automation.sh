sudo apt update -y


pkgs='apache2 awscli'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get install $pkgs
  sudo systemctl start apache2
fi


apache2servicestat=$(systemctl status apache2)
if [[ $apache2servicestat == *"active (running)"* ]]; then
	 echo "apache process is running"
else
	echo "apche process is not running"
	sudo systemctl start apache2
    echo "apache process started"
fi

systemctl is-enabled apache2 | grep 'enabled'
if [[ $? -eq '0' ]]; then
    echo "apache2 is enabled"
else
    echo "apache2 is disabled"
    sudo systemctl enable apache2
    echo "apache2 enabled"
fi


cwd=$(pwd)
timestamp=$(date '+%d%m%Y-%H%M%S')
name=Girish
fileName=${name}-httpd-logs-${timestamp}

cd /var/log/apache2/
sudo tar -cvf ${fileName}.tar access.log  error.log
sudo mv ${fileName}.tar /tmp/
cd ${cwd}


s3_bucket=upgrad-girish

aws s3 \
cp /tmp/${fileName}.tar \
s3://${s3_bucket}/${fileName}.tar



FILE=/var/www/html/inventory.html

if ! [ -f "$FILE" ]; then
    echo "$FILE does not exist."
    touch ${FILE}
    echo "$FILE: created."
    bold_style=$(tput bold)
    echo -e "${bold_style}Log Type\tTime Created\tType\tSize" >> $FILE
    echo "$FILE: header added."
else
    echo "$FILE exists."
fi

file_size=$(du -sh /tmp/${fileName}.tar | cut -f1)
normal_style=$(tput sgr0)
echo -e "${normal_style}httpd-logs\t${timestamp}\ttar\t${file_size}" >> $FILE
echo "$FILE: log added."

rm /tmp/${fileName}.tar

CRON_FILE=/etc/cron.d/automation
if ! [ -f "$CRON_FILE"]; then
    echo "$CRON_FILE: does not exist"
    touch ${CRON_FILE}
    crontab $CRON_FILE
fi


grep -qi "automation.sh" $CRON_FILE
if [ $? != 0 ]; then
    echo "Updating cron job for setting up automation.sh"
    echo "0 0 * * * root /root/Automation_Project/automation.sh 1> /dev/null 2> /tmp/cronjob-log.err"  >> $CRON_FILE
    echo "@reboot root /root/Automation_Project/automation.sh 1> /dev/null 2> /tmp/cronjob-reboot-log.err" >> $CRON_FILE
fi

crontab -l

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

rm /tmp/${fileName}.tar

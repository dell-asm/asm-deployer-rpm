# configure nagios
/sbin/chkconfig nagios on

/bin/sed -i 's:enable_notifications=1:enable_notifications=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:enable_flap_detection=1:enable_flap_detection=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:cfg_file=/etc/nagios/objects/localhost.cfg:#cfg_file=/etc/nagios/objects/localhost.cfg:' /etc/nagios/nagios.cfg

/sbin/restorecon -v /usr/lib64/nagios/plugins/*

# configure graphite
grep -q ^SECRET_KEY /etc/graphite-web/local_settings.py

if [ $? -eq 1 ]
then
  echo "SECRET_KEY = '$(openssl rand 32 -hex)'" >> /etc/graphite-web/local_settings.py
  echo "TIME_ZONE = 'UTC'" >> /etc/graphite-web/local_settings.py

  python /usr/lib/python2.6/site-packages/graphite/manage.py syncdb --noinput

  cat << EOF > /etc/carbon/storage-schemas.conf
[carbon]
pattern = ^carbon\.
retentions = 60:90d

[default]
pattern = .*
retentions = 5m:30d, 1h:1y, 1d:5y
EOF
  
  /bin/sed -i 's:^:#:' /etc/httpd/conf.d/graphite-web.conf
  
  chkconfig carbon-cache on
fi


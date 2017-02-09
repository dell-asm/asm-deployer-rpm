# configure nagios
/sbin/chkconfig nagios on

/sbin/chkconfig --add asm-deployer
/sbin/chkconfig asm-deployer on

/bin/sed -i 's:enable_notifications=1:enable_notifications=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:enable_flap_detection=1:enable_flap_detection=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:cfg_file=/etc/nagios/objects/localhost.cfg:#cfg_file=/etc/nagios/objects/localhost.cfg:' /etc/nagios/nagios.cfg
/bin/sed -i 's:max_concurrent_checks=4:max_concurrent_checks=0:' /etc/nagios/nagios.cfg

/sbin/restorecon -v /usr/lib64/nagios/plugins/*

# configure graphite
touch /etc/carbon/storage-aggregation.conf

/bin/sed -i 's:LOG_LISTENER_CONNECTIONS = True:LOG_LISTENER_CONNECTIONS = False:' /etc/carbon/carbon.conf
/bin/sed -i 's:LOG_CACHE_QUEUE_SORTS = True:LOG_CACHE_QUEUE_SORTS = False:' /etc/carbon/carbon.conf
/bin/sed -i 's:ENABLE_LOGROTATION = True:ENABLE_LOGROTATION = False:' /etc/carbon/carbon.conf

grep -q ^SECRET_KEY /etc/graphite-web/local_settings.py

if [ $? -eq 1 ]
then
  echo "SECRET_KEY = '$(openssl rand 32 -hex)'" >> /etc/graphite-web/local_settings.py
  echo "TIME_ZONE = 'UTC'" >> /etc/graphite-web/local_settings.py

  python /usr/lib/python2.6/site-packages/graphite/manage.py syncdb --noinput
  chown apache:apache /var/lib/graphite-web/graphite.db

  cat << EOF > /etc/carbon/storage-schemas.conf
[carbon]
pattern = ^carbon\.
retentions = 60:90d

[asm_thresholds]
pattern = ^asm\..+Threshold
retentions = 1h:30d, 1d:5y

[default]
pattern = .*
retentions = 5m:30d, 1h:1y, 1d:5y
EOF

  /bin/sed -i 's:^:#:' /etc/httpd/conf.d/graphite-web.conf

  chkconfig carbon-cache on
fi

# Pick up local gem changes from Dell-ASM-Gems
cd /opt/asm-deployer
env PATH=/opt/jruby/9k/bin:$PATH bundle update --local

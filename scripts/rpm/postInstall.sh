# configure nagios
/sbin/chkconfig nagios on

/bin/sed -i 's:enable_notifications=1:enable_notifications=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:enable_flap_detection=1:enable_flap_detection=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:cfg_file=/etc/nagios/objects/localhost.cfg:#cfg_file=/etc/nagios/objects/localhost.cfg:' /etc/nagios/nagios.cfg

/sbin/restorecon -v /usr/lib64/nagios/plugins/*

# configure graphite
touch /etc/carbon/storage-aggregation.conf

/bin/sed -i 's:LOG_LISTENER_CONNECTIONS = True:LOG_LISTENER_CONNECTIONS = False:' /etc/carbon/carbon.conf
/bin/sed -i 's:LOG_CACHE_QUEUE_SORTS = True:LOG_CACHE_QUEUE_SORTS = False:' /etc/carbon/carbon.conf
/bin/sed -i 's:ENABLE_LOGROTATION = True:ENABLE_LOGROTATION = False:' /etc/carbon/carbon.conf

if [ -e "/opt/asm-deployer/Gemfile.lock" ]
  then
  chown root:razor "/opt/asm-deployer/Gemfile.lock" && chmod 0664 "/opt/asm-deployer/Gemfile.lock"
fi

if ! /opt/jruby-1.7.8/bin/gem list systemu | grep systemu ; then
  /opt/jruby-1.7.8/bin/gem install --local /opt/Dell/gems/systemu-2.6.5.gem
fi

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

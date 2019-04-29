# configure nagios
/sbin/chkconfig nagios on

# Configure asm-deployer service
rm /etc/rc.d/init.d/asm-deployer
/usr/bin/systemctl daemon-reload
/usr/bin/systemctl enable asm-deployer.service

/bin/sed -i 's:enable_notifications=1:enable_notifications=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:enable_flap_detection=1:enable_flap_detection=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:cfg_file=/etc/nagios/objects/localhost.cfg:#cfg_file=/etc/nagios/objects/localhost.cfg:' /etc/nagios/nagios.cfg
/bin/sed -i 's:max_concurrent_checks=4:max_concurrent_checks=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's/cfg_dir=\/etc\/nagios\/conf.d/ /' /etc/nagios/nagios.cfg
/bin/sed -i 's/status_file=\/var\/log\/nagios\/status.dat/status_file=\/var\/spool\/nagios\/status.dat/' /etc/nagios/nagios.cfg

# Grant sudo access to script to build iPXE UEFi floppy
if [ $(grep -c "%razor ALL=NOPASSWD:/opt/asm-deployer/scripts/build_bootable_floppy.sh" /etc/sudoers) -eq 0 ]; then
  echo "%razor ALL=NOPASSWD:/opt/asm-deployer/scripts/build_bootable_floppy.sh" >> /etc/sudoers
fi

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

  python /usr/lib/python2.7/site-packages/graphite/manage.py syncdb --noinput
  
  
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

# Update asm-deployer database
psql -U orion asm_dev < /opt/asm-deployer/db/schema.sql > /dev/null

# executing by default below permissions without validating SECRET_KEY
chown -R csadmin:csadmin /var/lib/graphite-web/
chown -R csadmin:csadmin /var/log/graphite-web/

# Updates for nagios
grep -q asm.cfg /etc/nagios/nagios.cfg || echo "cfg_file=/etc/nagios/objects/asm.cfg" >> /etc/nagios/nagios.cfg
chown -R nagios:nagios /var/log/nagios/
chown -R nagios:nagios /var/spool/nagios/


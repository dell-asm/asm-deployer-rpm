/sbin/chkconfig nagios on

/bin/sed -i 's:enable_notifications=1:enable_notifications=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:enable_flap_detection=1:enable_flap_detection=0:' /etc/nagios/nagios.cfg
/bin/sed -i 's:process_performance_data=0:process_performance_data=1:' /etc/nagios/nagios.cfg
/bin/sed -i 's:#service_perfdata_command=process-service-perfdata:service_perfdata_command=process-perfdata:' /etc/nagios/nagios.cfg
/bin/sed -i 's:cfg_file=/etc/nagios/objects/localhost.cfg:#cfg_file=/etc/nagios/objects/localhost.cfg:' /etc/nagios/nagios.cfg

/sbin/restorecon -v /usr/lib64/nagios/plugins/check-*rb /usr/lib64/nagios/plugins/process_perf_data.rb


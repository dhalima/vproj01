#!/bin/bash

function _configure_host() {
    _host_path=$1
    
    while read _line; do
	if [ -n "${_line}" ]; then
	    _hostname=`echo ${_line} | awk '{print $2}'`
	    #echo ${_hostname}
	    sed -i.bak "s/\(.* ${_hostname}\)$/#\1/g" /etc/hosts	    
	fi
    done < ${_host_path}
    
    echo '' >> /etc/hosts
    echo "# ${_host_path}" >> /etc/hosts
    cat ${_host_path} >> /etc/hosts
}

function _configure_apache() {
    _conf_path=$1
    _conf_name=`basename ${_conf_path}`
    # http://www.linuxjournal.com/article/8919
    _conf_name=`echo ${_conf_name%*.apache}` # removes .apache from the right

    if [ ! -e /etc/httpd/conf.d/${_conf_name} ]; then
	ln -n -s ${_conf_path} /etc/httpd/conf.d/${_conf_name}
    fi
}

function _configure_mysql() {
    _dump_path=$1    
    _user=`basename $1`

    # http://www.linuxjournal.com/article/8919
    _user=`echo ${_user%*.mysql}` # removes .mysql from the right


    #echo "xxx ${_user}"

    if ! mysql -u root -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${_user}'" | grep -i -q ${_user}; then
	mysql -u root << END
CREATE USER '${_user}'@'localhost' IDENTIFIED BY '${_user}';
CREATE DATABASE ${_user};
GRANT ALL PRIVILEGES ON ${_user}.* TO '${_user}'@'localhost';
FLUSH PRIVILEGES;
END
    
	cat ${_dump_path} | mysql -u ${_user} -p${_user} ${_user}
    fi
}

export -f _configure_host _configure_apache _configure_mysql

#find sites/conf -name '*.apache' -type f -print0 | xargs -I {} -0 bash -c '_configure_apache "$@"' _ {}
find /vagrant/apps/conf -name '*.hosts' -type f -print0 | xargs -I {} -0 bash -c '_configure_host "$@"' _ {}
find /vagrant/apps/conf -name '*.apache' -type f -print0 | xargs -I {} -0 bash -c '_configure_apache "$@"' _ {}
find /vagrant/apps/dump -name '*.mysql' -type f -print0 | xargs -I {} -0 bash -c '_configure_mysql "$@"' _ {}

/sbin/service httpd restart
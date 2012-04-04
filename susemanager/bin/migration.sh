#!/bin/bash

DO_MIGRATION=0
DO_SETUP=0
LOGFILE=0
WAIT_BETWEEN_STEPS=0

MIGRATION_ENV="/root/migration_env.sh"
SETUP_ENV="/root/setup_env.sh"

SATELLITE_HOST=""
SATELLITE_DOMAIN=""
SATELLITE_DB_USER=""
SATELLITE_DB_PASS=""
SATELLITE_DB_SID=""

SATELLITE_FQDN=""
SATELLITE_IP=""

SATELLITE_IS_RH=1
KEYFILE="/root/migration-key"

RSYNC_PASSWORD=""

# oracle only
DEFAULT_TABLESPACE="data_tbs"

LOCAL_DB=1
DB_BACKEND="postgresql"

rpm -q oracle-server > /dev/null
if [ $? -eq "0" ]; then
    DB_BACKEND="oracle"
fi


# setup_hostname()
# setup_db_xe()
# setup_db_full()
# setup_spacewalk()
# dump_remote_db()
# import_db()
# upgrade_schema()
# copy_remote_files()

function help() {
    echo "
Usage: $0 [OPTION]
helper script to do migration or setup of SUSE Manager

  -m             full migration of an existing RHN Satellite
  -s             fresh setup of the SUSE Manager installation
  -r             only sync remote files (useful for migration only)
  -w             wait between steps (in case you do -r -m)
  -l LOGFILE     write a log to LOGFILE
  -h             this help screen

"
}

wait_step() {
    if [ $WAIT_BETWEEN_STEPS = "1" ];then
        echo "Press Return to continue"
        read
    fi;
}

setup_swap() {

SWAP=`LANG=C free | grep Swap: | sed -e "s/ \+/\t/g" | cut -f 2`
FREESPACE=`LANG=C df / | tail -1 | sed -e "s/ \+/\t/g" | cut -f 4`

if [ $SWAP -eq 0 ]; then
    echo "No swap found; trying to setup additional swap space..."
    if [ $FREESPACE -le 3000000 ]; then
        echo "Not enough space on /. Not adding swap space. Good luck..."
    else
        dd if=/dev/zero of=/SWAPFILE bs=1M count=2000
        sync
        mkswap -f /SWAPFILE
        echo "/SWAPFILE swap swap defaults 0 0" >> /etc/fstab
        swapon -a
    fi
fi
}

setup_mail () {

# fix hostname for postfix
REALHOSTNAME=`hostname -f`
if [ -z "$REALHOSTNAME" ]; then
        for i in `ip -f inet -o addr show scope global | awk '{print $4}' | awk -F \/ '{print $1}'`; do
                for j in `dig +noall +answer +time=2 +tries=1 -x $i | awk '{print $5}' | sed 's/\.$//'`; do
                        if [ -n "$j" ]; then
                                REALHOSTNAME=$j
                                break 2
                        fi
                done
        done
fi
if [ -n "$REALHOSTNAME" ]; then
        echo "$REALHOSTNAME" > /etc/HOSTNAME
fi
SuSEconfig --module postfix
}

setup_hostname() {
    # The SUSE Manager server needs to have the same hostname as the·
    # old satellite server.·

    cp /etc/hosts /etc/hosts.backup.suse.manager

    # change the hostname to the satellite hostname
    hostname $SATELLITE_HOST

    # modify /etc/hosts to fake the own hostname
    #
    # add line·
    # <ip>  <fqdn> <shortname>
    #
    echo -e "\n$MANAGER_IP $SATELLITE_FQDN $SATELLITE_HOST" >> /etc/hosts

    # test if the output of "hostname -f" is equal to $SATELLITE_FQDN
    # test if "ping $SATELLITE_HOST" ping the own host
}

cleanup_hostname() {
    if [ -f /etc/hosts.backup.suse.manager ]; then
        mv /etc/hosts.backup.suse.manager /etc/hosts
    fi;
}

compute_oracle_mem() {
  # SGA & PGA algo
   sgamin=146800640
   pgamin=16777216
   TM=`cat /proc/meminfo | grep '^MemTotal' | awk '{print $2}'`
   TM=`echo $TM / 1024 | bc`
   TM=`echo 0.40 \* $TM | bc | sed "s/\..*//"`
   TMSP=`echo $TM-40 | bc`
   sga_target=`echo 0.75 \* $TMSP | bc`
   pga_target=`echo 0.25 \* $TMSP | bc `
   sga=`echo $sga_target \* 1048576  | bc | sed "s/\..*//"`
   pga=`echo $pga_target \* 1048576  | bc | sed "s/\..*//"`
   check=`echo $sga \< $sgamin | bc`
   if test $check != 0
   then
           sga=$sgamin
   fi

   check=`echo $pga \< $pgamin | bc`
   if test $check != 0
   then
           pga=$pgamin
   fi

   echo "sga=$sga"
   echo "pga=$pga"
}

# setup a local oracle database
setup_db_oracle() {
    /opt/apps/oracle/setup "$SYS_DB_PASS"
    # remove suid bits for bnc#736240
    find /opt/apps/oracle/product/ -perm -4000 -exec chmod -s {} \;
    cp /opt/apps/oracle/product/11gR2/dbhome_1/network/admin/tnsnames.ora /etc
    compute_oracle_mem
    echo "Create database user for SUSE Manager..."
    echo "select value from nls_database_parameters where parameter='NLS_CHARACTERSET';
shutdown immediate;
startup mount;
alter system enable restricted session;
alter system set job_queue_processes=0;
alter database open;
alter database character set internal_use utf8;
shutdown immediate;
startup;
select value from nls_database_parameters where parameter='NLS_CHARACTERSET';
alter system set job_queue_processes=1000;
alter profile DEFAULT limit PASSWORD_LIFE_TIME unlimited;
create smallfile tablespace $DEFAULT_TABLESPACE datafile '/opt/apps/oracle/oradata/susemanager/data_01.dbf' size 500M autoextend on blocksize 8192;
create user $MANAGER_USER identified by \"$MANAGER_PASS\" default tablespace $DEFAULT_TABLESPACE;
grant dba to $MANAGER_USER;
alter system set processes = 400 scope=spfile;
alter system set deferred_segment_creation=FALSE;
alter system set sga_target=$sga scope=spfile;
alter system set pga_aggregate_target=$pga scope=spfile;
alter system set nls_territory='AMERICA' scope=spfile;
BEGIN
dbms_sqltune.set_auto_tuning_task_parameter( 'ACCEPT_SQL_PROFILES', 'TRUE');
END;
/
quit
" > /tmp/dbsetup.sql

# See http://stackoverflow.com/questions/4153807/oracle-sequence-starting-with-2-instead-of-1
#
# alter system set deferred_segment_creation=FALSE;
#

    su -s /bin/bash - oracle -c "ORACLE_SID=$MANAGER_DB_NAME sqlplus / as sysdba @/tmp/dbsetup.sql;"
    rm /tmp/dbsetup.sql

    echo "###########################
# Dobby configuration
###########################
dobby.sid = susemanager
dobby.sysdba_username = sys
dobby.sysdba_password = $SYS_DB_PASS
dobby.normal_username = $MANAGER_USER
dobby.normal_password = $MANAGER_PASS
dobby.remote_dsn =
dobby.oracle_home = /opt/apps/oracle/product/11gR2/dbhome_1
dobby.data_dir_format = /opt/apps/oracle/oradata/susemanager
dobby.hot_backup_dir_format =
dobby.archive_dir_format = /opt/apps/oracle/flash_recovery_area/susemanager
dobby.oracle_user = oracle
###########################" >> /etc/rhn/rhn.conf

}

setup_db_postgres() {
    insserv postgresql
    rcpostgresql start
    su - postgres -c "createdb $MANAGER_DB_NAME ; createlang plpgsql $MANAGER_DB_NAME ; echo \"CREATE ROLE $MANAGER_USER PASSWORD '$MANAGER_PASS' SUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;\" | psql"

    echo "local $MANAGER_DB_NAME $MANAGER_USER md5
host $MANAGER_DB_NAME $MANAGER_USER 127.0.0.1/8 md5
host $MANAGER_DB_NAME $MANAGER_USER ::1/128 md5
" > /tmp/pg_hba.conf
    cat /var/lib/pgsql/data/pg_hba.conf >> /tmp/pg_hba.conf
    mv /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak
    mv /tmp/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf
    if [ -x "/usr/bin/pgtune" ]; then
      mv /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.orig
      /usr/bin/pgtune -T Mixed -i /var/lib/pgsql/data/postgresql.conf.orig -o /var/lib/pgsql/data/postgresql.conf
    fi
    rcpostgresql restart
}

setup_spacewalk() {
    CERT_COUNTRY=`echo -n $CERT_COUNTRY|tr [:lower:] [:upper:]`

    echo "admin-email = $MANAGER_ADMIN_EMAIL
ssl-set-org = $CERT_O
ssl-set-org-unit = $CERT_OU
ssl-set-city = $CERT_CITY
ssl-set-state = $CERT_STATE
ssl-set-country = $CERT_COUNTRY
ssl-password = $CERT_PASS
ssl-set-email = $CERT_EMAIL
ssl-config-sslvhost = Y
ssl-ca-cert-expiration = 10
ssl-server-cert-expiration = 10
db-backend=$DB_BACKEND
db-user=$MANAGER_USER
db-password=$MANAGER_PASS
db-name=$MANAGER_DB_NAME
db-host=$MANAGER_DB_HOST
db-port=$MANAGER_DB_PORT
db-protocol=$MANAGER_DB_PROTOCOL
enable-tftp=$MANAGER_ENABLE_TFTP
ncc-user = $NCC_USER
ncc-pass = $NCC_PASS
ncc-email = $NCC_EMAIL
" > /root/spacewalk-answers

    if [ "$DO_MIGRATION" = "1" ]; then
        /usr/bin/spacewalk-setup --ncc --skip-db-population --answer-file=/root/spacewalk-answers
    else
        /usr/bin/spacewalk-setup --ncc --answer-file=/root/spacewalk-answers
    fi
    if [ "x" = "x$MANAGER_MAIL_FROM" ]; then
        MY_DOMAIN=`hostname -d`
        MANAGER_MAIL_FROM="SUSE Manager ($REALHOSTNAME) <root@$MY_DOMAIN>"
    fi
    if ! grep "^web.default_mail_from" /etc/rhn/rhn.conf > /dev/null; then
        echo "web.default_mail_from = $MANAGER_MAIL_FROM" >> /etc/rhn/rhn.conf
    fi
    rm /root/spacewalk-answers
}

dump_remote_db() {
    echo "Dumping remote database. Please wait..."
    ssh -i $KEYFILE root@$SATELLITE_IP "su -s /bin/bash - oracle -c \"exp \\\"$SATELLITE_DB_USER\\\"/\\\"$SATELLITE_DB_PASS\\\"@\\\"$SATELLITE_DB_SID\\\" owner=$SATELLITE_DB_USER compress=n consistent=y statistics=none file=/tmp/sat.oracleXE.dmp log=/tmp/rhn.oracleXE.log\""

    echo "Copy remote database dump to local machine..."
    scp -i $KEYFILE root@$SATELLITE_IP:/tmp/sat.oracleXE.dmp /tmp

    echo "Delete remote database dump..."
    ssh -i $KEYFILE root@$SATELLITE_IP "rm -f /tmp/sat.oracleXE.dmp"
}

import_db() {
    echo "Importing database dump. Please wait..."
    MANAGER_DB_NAME=`echo -n $MANAGER_DB_NAME|tr [:lower:] [:upper:]`
    su -s /bin/bash - oracle -c "imp system/$SYS_DB_PASS@$MANAGER_DB_NAME fromuser=$SATELLITE_DB_USER touser=$MANAGER_USER file=/tmp/sat.oracleXE.dmp log=/tmp/spacewalk.oracleXE.imp.log ignore=y"
    if [ $? -eq 0 ]; then
        echo "Database dump successfully imported."
        rm -f /tmp/sat.oracleXE.dmp
    fi
}

upgrade_schema() {
    spacewalk-schema-upgrade
    if [ "$LOCAL_DB" != "0" ]; then
        su -s /bin/bash - oracle -c "ORACLE_SID=$MANAGER_DB_NAME sqlplus sys/\"$SYS_DB_PASSWORD\"@$MANAGER_DB_NAME as sysdba <<ENDPLUS @/opt/apps/oracle/product/11gR2/dbhome_1/rdbms/admin/utlrp.sql; exit;ENDPLUS"
    else
        echo "You may need to recompile the schema on your database host using:"
        echo "su -s /bin/bash - oracle -c \"ORACLE_SID=$MANAGER_DB_NAME sqlplus sys/\\\"<SYS_DB_PASSWORD>\\\"@$MANAGER_DB_NAME as sysdba <<ENDPLUS @\$ORACLE_HOME/rdbms/admin/utlrp.sql; exit;ENDPLUS\""
    fi
# FIXME: not needed for postgres ?
}

backup_files() {
    DATE=`date +"%Y-%m-%d-%H-%M"`
    BACKUPDIR="backup-$DATE"

    mkdir -p /root/$BACKUPDIR/pub
    mkdir -p /root/$BACKUPDIR/ssl/jabberd
    mv /srv/www/htdocs/pub/RHN-ORG-TRUSTED-SSL-CERT /root/$BACKUPDIR/pub/ 2> /dev/null
    mv /srv/www/htdocs/pub/rhn-org-trusted-ssl-cert*.rpm /root/$BACKUPDIR/pub/ 2> /dev/null
    mv /root/ssl-build /root/$BACKUPDIR/ 2> /dev/null
    cp /etc/apache2/ssl.crt/spacewalk.crt /root/$BACKUPDIR/ssl/ 2> /dev/null
    cp /etc/apache2/ssl.key/spacewalk.key /root/$BACKUPDIR/ssl/ 2> /dev/null
    cp /etc/pki/spacewalk/jabberd/server.pem /root/$BACKUPDIR/ssl/jabberd/ 2> /dev/null
}

copy_remote_files_common() {
    # copy only new files (new kickstart profiles, snippets, trigger, etc.)
    rsync -e "ssh -i $KEYFILE -l root" -a -v -z --ignore-existing root@$SATELLITE_IP:/var/lib/cobbler/ /var/lib/cobbler/
    rsync -e "ssh -i $KEYFILE -l root" -a -v -z root@$SATELLITE_IP:/var/lib/rhn/kickstarts /var/lib/rhn/
    chown -R tomcat.tomcat /var/lib/rhn/kickstarts
    rsync -e "ssh -i $KEYFILE -l root" -a -v -z --exclude='libexec/*' root@$SATELLITE_IP:/var/lib/nocpulse/ /var/lib/nocpulse/
    chown -R nocpulse.nocpulse /var/lib/nocpulse
    rsync -e "ssh -i $KEYFILE -l root" -avz root@$SATELLITE_IP:/root/ssl-build /root/
    scp -i $KEYFILE root@$SATELLITE_IP:/etc/pki/spacewalk/jabberd/server.pem /etc/pki/spacewalk/jabberd/server.pem
    chmod 600 /etc/pki/spacewalk/jabberd/server.pem
    chown jabber:jabber /etc/pki/spacewalk/jabberd/server.pem
}

copy_remote_files_redhat() {
    echo "Copy files from old satellite..."
    # maybe add -H for hardlinks?
    rsync -e "ssh -i $KEYFILE -l root" -avz root@$SATELLITE_IP:/var/satellite/ /var/spacewalk/
    chown -R wwwrun.www /var/spacewalk
    rsync -e "ssh -i $KEYFILE -l root" -avz --ignore-existing root@$SATELLITE_IP:/var/www/html/pub/ /srv/www/htdocs/pub/

    scp -i $KEYFILE root@$SATELLITE_IP:/etc/pki/tls/certs/spacewalk.crt /etc/apache2/ssl.crt/spacewalk.crt
    scp -i $KEYFILE root@$SATELLITE_IP:/etc/pki/tls/private/spacewalk.key /etc/apache2/ssl.key/spacewalk.key
}

copy_remote_files_suse() {
    echo "Copy files from old SUSE Manager..."
    # maybe add -H for hardlinks?
    rsync -e "ssh -i $KEYFILE -l root" -avz root@$SATELLITE_IP:/var/spacewalk/ /var/spacewalk/
    chown -R wwwrun.www /var/spacewalk
    rsync -e "ssh -i $KEYFILE -l root" -avz --ignore-existing root@$SATELLITE_IP:/srv/www/htdocs/pub/ /srv/www/htdocs/pub/

    scp -i $KEYFILE root@$SATELLITE_IP:/etc/apache2/ssl.crt/spacewalk.crt /etc/apache2/ssl.crt/spacewalk.crt
    scp -i $KEYFILE root@$SATELLITE_IP:/etc/apache2/ssl.key/spacewalk.key /etc/apache2/ssl.key/spacewalk.key
}

create_ssh_key() {
    echo "Please enter the root password of the remote machine."
    ssh-keygen -q -N "" -C "spacewalk-migration-key" -f $KEYFILE
    ssh-copy-id -i $KEYFILE root@$SATELLITE_IP > /dev/null
}

remove_ssh_key() {
    ssh root@$SATELLITE_IP -i $KEYFILE "grep -v spacewalk-migration-key /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.tmp && mv /root/.ssh/authorized_keys.tmp /root/.ssh/authorized_keys"
    rm -f $KEYFILE
}

check_remote_type() {
    ssh -i $KEYFILE root@$SATELLITE_IP "test -e /etc/apache2/ssl.crt/spacewalk.crt"
    if [ $? -eq 0 ]; then
       echo "Remote machine is SUSE Manager"
        SATELLITE_IS_RH=0
    else
       ssh -i $KEYFILE root@$SATELLITE_IP "test -e /etc/pki/tls/certs/spacewalk.crt"
       if [ $? -eq 0 ]; then
           echo "Remote machine is Red Hat Satellite"
            SATELLITE_IS_RH=1
       else
           echo "Remote machine appears to be neither SUSE Manager nor Red Hat Satellite. Exit."
           exit
       fi
    fi
}

copy_remote_files() {
    backup_files
    if [ $SATELLITE_IS_RH = "1" ];then
        copy_remote_files_redhat
        mv /var/spacewalk/redhat /var/spacewalk/packages
    else
        copy_remote_files_suse
    fi
    copy_remote_files_common
}


do_migration() {
    echo "Migration needs to execute several commands on the remote machine."
    create_ssh_key

    if [ "x" = "x$SATELLITE_HOST" ]; then
        echo -n "SATELLITE_HOST:";   read SATELLITE_HOST
        echo -n "SATELLITE_DOMAIN:"; read SATELLITE_DOMAIN
        echo -n "SATELLITE_DB_USER"; read SATELLITE_DB_USER
        echo -n "SATELLITE_DB_PASS"; read SATELLITE_DB_PASS
        echo -n "SATELLITE_DB_SID";  read SATELLITE_DB_SID
        echo -n "MANAGER_IP";        read MANAGER_IP
        echo -n "MANAGER_USER";      read MANAGER_USER
        echo -n "MANAGER_PASS";      read MANAGER_PASS
    fi;
    setup_hostname

    # those values will be overwritten by the copied certificate
    CERT_O="dummy"
    CERT_OU="dummy"
    CERT_CITY="dummy"
    CERT_STATE="dummy"
    CERT_COUNTRY="DE"
    CERT_PASS="dummy"
    CERT_EMAIL="dummy@example.net"
    MANAGER_ENABLE_TFTP="n"

    check_remote_type
    wait_step

    do_setup
    sleep 10
    wait_step

    dump_remote_db
    wait_step

    import_db
    wait_step

    upgrade_schema
    wait_step

    copy_remote_files
    wait_step

    cleanup_hostname
    remove_ssh_key
}

do_setup() {
    if [ -f $SETUP_ENV ]; then
        . $SETUP_ENV
    else
        # ask for the needed values if the setup_env file does not exist
        echo -n "MANAGER_USER=";        read MANAGER_USER
        echo -n "MANAGER_PASS=";        read MANAGER_PASS
        echo -n "MANAGER_ADMIN_EMAIL="; read MANAGER_ADMIN_EMAIL
        echo -n "CERT_O="             ; read CERT_O
        echo -n "CERT_OU="            ; read CERT_OU
        echo -n "CERT_CITY="          ; read CERT_CITY
        echo -n "CERT_STATE="         ; read CERT_STATE
        echo -n "CERT_COUNTRY="       ; read CERT_COUNTRY
        echo -n "CERT_EMAIL="         ; read CERT_EMAIL
        echo -n "CERT_PASS="          ; read CERT_PASS
        echo -n "LOCAL_DB="           ; read LOCAL_DB
        echo -n "DB_BACKEND="         ; read DB_BACKEND
        echo -n "MANAGER_DB_NAME="    ; read MANAGER_DB_NAME
        echo -n "MANAGER_DB_HOST="    ; read MANAGER_DB_HOST
        echo -n "MANAGER_DB_PORT="    ; read MANAGER_DB_PORT
        echo -n "MANAGER_DB_PROTOCOL="; read MANAGER_DB_PROTOCOL
        echo -n "MANAGER_ENABLE_TFTP="; read MANAGER_ENABLE_TFTP
        echo -n "NCC_USER="           ; read NCC_USER
        echo -n "NCC_PASS="           ; read NCC_PASS
        echo -n "NCC_EMAIL="          ; read NCC_EMAIL
    fi;
    if [ -z "$SYS_DB_PASS" ]; then
        SYS_DB_PASS=`dd if=/dev/urandom bs=16 count=4 2> /dev/null | md5sum | cut -b 1-8`
    fi
    if [ -z "$MANAGER_DB_NAME" ]; then
        MANAGER_DB_NAME="susemanager"
    fi
    if [ "$DB_BACKEND" != "oracle" -a "$DB_BACKEND" != "postgresql" ]; then
        echo "Unknown dabase backend '$DB_BACKEND'. Allowed values: oracle, postgresql"
        exit 1
    fi

    setup_swap
    setup_mail
    if [ "$LOCAL_DB" != "0" -a "$DB_BACKEND" = "postgresql" ]; then
        setup_db_postgres
    elif [ "$LOCAL_DB" != "0" -a "$DB_BACKEND" = "oracle" ]; then
        setup_db_oracle
    fi

    # should be done by cobbler with "--sync" but we had a case where those
    # files were missing (bnc#668908)
    cp /usr/share/syslinux/menu.c32 /srv/tftpboot/
    cp /usr/share/syslinux/pxelinux.0 /srv/tftpboot/

    setup_spacewalk
}

for p in $@; do
    if [ "$LOGFILE" = "1" ]; then
        LOGFILE=$p
        continue
    fi

    case "$p" in
    -m)
        DO_MIGRATION=1
        . $MIGRATION_ENV 2> /dev/null
        . $SETUP_ENV
        SATELLITE_FQDN="$SATELLITE_HOST.$SATELLITE_DOMAIN"
        SATELLITE_IP=`dig +short $SATELLITE_FQDN`
        if [ "$LOGFILE" = "0" ]; then
            LOGFILE=/tmp/migration.log
        fi
       ;;
    -s)
        DO_SETUP=1
       ;;
    -r)
        . $MIGRATION_ENV 2> /dev/null
        . $SETUP_ENV
        SATELLITE_FQDN="$SATELLITE_HOST.$SATELLITE_DOMAIN"
        SATELLITE_IP=`dig +short $SATELLITE_FQDN`
        create_ssh_key
        check_remote_type
        backup_files
        copy_remote_files
        remove_ssh_key
       ;;
    -h)
        help
       ;;
    -l)
        LOGFILE="1"
        ;;
    -w)
        WAIT_BETWEEN_STEPS=1
        ;;
    *)
       echo "That option is not recognized"
       ;;
    esac
done

if [ "$LOGFILE" != "0" ]; then
    #set -x
    exec >> >(tee $LOGFILE | sed 's/^/  /' ) 2>&1
fi

wait_step

if [ "$DO_SETUP" = "1" ]; then
    do_setup

    # rename the default org
    echo "UPDATE web_customer SET name = '$CERT_O' WHERE id = 1;" > /tmp/changeorg.sql
    echo "COMMIT;" >> /tmp/changeorg.sql
    /usr/bin/spacewalk-sql --verbose --select-mode-direct /tmp/changeorg.sql
    rm /tmp/changeorg.sql
fi
wait_step

if [ "$DO_MIGRATION" = "1" ]; then
    if [ -z "$DB_BACKEND" -o "$DB_BACKEND" != "oracle" ]; then
        echo "Migration only supported with oracle DB Backend"
        exit 1
    fi
    do_migration
fi

# Finaly call mgr-ncc-sync
/usr/sbin/mgr-ncc-sync

# vim: set expandtab:

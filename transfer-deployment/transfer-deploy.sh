#!/bin/bash

. ./conf

init_vars () {
  # PROGRAMS TO USE
  PSQL="/usr/bin/psql"
  FIXTURE_DRVR="${CLI_HOME}/${PM_CLI_TOOL}/$FIXTURE_DRVR"
  
  # ENVIRONMENT VARS
  export $PGUSER
  export $PGHOST
  #export $PGPORT
  export PGPASSWORD=$PGPASSWORD
  export $TOMCAT_HOME

  # DATABASES
  PM_DB="${DB_PREFIX}_package_modeler"
  JBPM_DB="${DB_PREFIX}_jbpm32"

  # TRANSFER CORE ROLES
  ROLE_PRIVS="NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE LOGIN"
  XFER_FIXTURE_WRITER="${ROLE_PREFIX}_transfer_fixture_writer_user"
  XFER_FIXTURE_WRITER_PASSWD=""
  XFER_READER="${ROLE_PREFIX}_transfer_reader_user"
  XFER_READER_PASSWD=""
  XFER_WRITER="${ROLE_PREFIX}_transfer_data_writer_user"
  XFER_WRITER_PASSWD=""
  JBPM="${ROLE_PREFIX}_jbpm_user"
  JBPM_PASSWD=""

  # PACKAGE MODLER ROLES
  OWNER_PRIVS="NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE"
  PKG_MODEL_FIXTURE_WRITER="${ROLE_PREFIX}_package_modeler_fixture_writer_role"
  PKG_MODEL_READER="${ROLE_PREFIX}_package_modeler_reader_role"
  PKG_MODEL_WRITER="${ROLE_PREFIX}_package_modeler_data_writer_role"
  JBPM_OWNER="${ROLE_PREFIX}_jbpm_role"
}

sanity_checks () {
  # ARE YOU 'postgres'?
#  if [ $LOGNAME != "postgres" ]
#    then printf "ERROR: *** You are not using the correct account ***\n"
#    usage
#    exit 1;
#  fi
  
  # CAN I CONNECT?
  echo "\q" | $PGSQL
  if [[ \$? != '0' ]]
    then printf "ERROR: *** Cannot connect to the PostgreSQL database\n"
    usage
    exit 1;
  fi
  
  # IS PM CLI DEPLOY DIR WRITABLE?
  if [ `touch ${CLI_DIR}/test 2> /dev/null; echo "$?"` -ne 0 ]
    then printf "ERROR: *** Package Modeler Command Line Tool install directory NOT WRITABLE\n"
    usage
  else
    rm $CLI_DIR/test
  fi
  
  # ARE REQUIRED FILES READABLE
  if [ -r $PM_CORE_SQL ]
    then printf "\n!!! Can't read ${PM_CORE_SQL}\nPlease fix this and try again.\nExitintg....\n"
    exit 1;
  fi
  if [ -r $PM_NDNP_SQL ]
    then printf "\n!!! Can't read ${PM_NDNP_SQL}\nPlease fix this and try again.\nExitintg....\n"
    exit 1;
  fi
  if [ -r $JBPM_SQL ]
    then printf "\n!!! Can't read ${JBPM_SQL}\nPlease fix this and try again.\nExitintg....\n"
    exit 1;
  fi
  if [ -r $CONSOLE_WAR ]
    then printf "\n!!! Can't read ${CONSOLE_WAR}\nPlease fix this and try again.\nExitintg....\n"
    exit 1;
  fi
  if [ -r $CLAYPOOL_WAR ]
    then printf "\n!!! Can't read ${CLAYPOOL_WAR}\nPlease fix this and try again.\nExitintg....\n"
    exit 1;
  fi
  if [ -r $PM_CLI_TOOL ]
    then printf "\n!!! Can't read ${PM_CLI_TOOL}\nPlease fix this and try again.\nExitintg....\n"
    exit 1;
  fi
}

#chech_manifest () {
#  digest -a md5 -v << ./Manifest
#  if [[ \$? != '0' ]]
#    then printf "ERROR: *** MD5 Checksum mismatch in \n"
#    usage
#    exit 1;
#  fi
#}

# Create Databases
create_dbs () {
  echo "CREATE DATABASE ${PM_DB} ENCODING = 'UTF8';" | $PSQL
  echo "CREATE DATABASE ${JBPM_DB} ENCODING = 'UTF8';" | $PSQL
}

# Create Database Roles 
init_roles () {
  # OWNER ROLES FIRST
  echo "CREATE ROLE $PKG_MODEL_FIXTURE_WRITER $OWNER_PRIVS;" | $PSQL
  echo "CREATE ROLE $PKG_MODEL_READER $OWNER_PRIVS;" | $PSQL
  echo "CREATE ROLE $PKG_MODEL_WRITER $OWNER_PRIVS;" | $PSQL
  echo "CREATE ROLE $JBPM_OWNER $OWNER_PRIVS;" | $PSQL

  # NOW USER ROLES
  echo "CREATE ROLE $XFER_FIXTURE_WRITER WITH PASSWORD $XFER_FIXTURE_WRITER_PASSWD $ROLE_PRIVS;" | $PSQL
  echo "CREATE ROLE $XFER_READER WITH PASSWORD $XFER_READER_PASSWD $ROLE_PRIVS;" | $PSQL
  echo "CREATE ROLE $XFER_WRITER WITH PASSWORD $XFER_WRITER_PASSWORD $ROLE_PRIVS;" | $PSQL
  echo "CREATE ROLE $JBPM WITH PASSWORD $JBPM_PASSWORD $ROLE_PRIVS;" | $PSQL

# GRANT PERMISSIONS TO ROLES
  echo "GRANT $PKG_MODEL_FIXTURE_WRITER TO $XFER_FIXTURE_WRITER;" | $PSQL
  echo "GRANT $PKG_MODEL_READER TO $XFER_FIXTURE_READER;" | $PSQL
  echo "GRANT $PKG_MODEL_WRITER TO $XFER_WRITER;" | $PSQL
  echo "GRANT $JBPM_OWNER TO $JBPM;" | $PSQL
}

# Grant PM Core Permissions
init_core_perms () {
  export PGDATABASE=$PG_DB
  echo "GRANT CONNECT ON DATABASE $PG_DB TO $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA core TO $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA agent TO $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT ON TABLE agent.agent TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT ON TABLE agent.agent_role TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT ON TABLE agent.'role' TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.repository TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.canonicalfile TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.canonicalfile_fixity TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.event_file_examination_group TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.event_file_location TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.event_package TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.external_filelocation TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.fileexamination TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.fileexamination_fixity TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.fileexamination_group TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.fileinstance TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.fileinstance_fixity TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.filelocation TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.package TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.storagesystem_filelocation TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT CONNECT ON DATABASE package_modeler TO $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA core TO $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA agent TO $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE agent.agent TO GROUP $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE agent.agent_role TO GROUP $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE agent.'role' TO GROUP $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE core.repository TO GROUP $PKG_MODEL_FIXTURE_WRITER;" | $PSQL
  echo "GRANT CONNECT ON DATABASE package_modeler TO $PKG_MODEL_READER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA core TO $PKG_MODEL_READER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA agent TO $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE agent.agent TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE agent.agent_role TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE agent.'role' TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.repository TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.canonicalfile TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.canonicalfile_fixity TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.event_file_examination_group TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.event_file_location TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.event_package TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.external_filelocation TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.fileexamination TO public;" | $PSQL
  echo "GRANT SELECT ON TABLE core.fileexamination_fixity TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.fileexamination_group TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.fileinstance TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.fileinstance_fixity TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.filelocation TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.package TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE core.storagesystem_filelocation TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT ALL ON TABLE hibernate_sequence TO public;" | $PSQL
}

# Grant PM NDNP Permissions
init_ndnp_perms () {
  export PGDATABASE=$PG_DB
  echo "GRANT USAGE ON SCHEMA ndnp TO $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ndnp.batch TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ndnp.batch_lccn TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ndnp.batch_reel TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ndnp.lccn TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ndnp.reel TO GROUP $PKG_MODEL_WRITER;" | $PSQL
  echo "GRANT USAGE ON SCHEMA ndnp TO $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE ndnp.batch TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE ndnp.batch_lccn TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE ndnp.batch_reel TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE ndnp.lccn TO GROUP $PKG_MODEL_READER;" | $PSQL
  echo "GRANT SELECT ON TABLE ndnp.reel TO GROUP $PKG_MODEL_READER;" | $PSQL
}

# Grant JBPM Permissions
init_jbpm_perms () {  
  export PGDATABASE=$JBPM_DB
  echo "GRANT CONNECT ON DATABASE jbpm32 TO $JBPM;" | $PGSQL
  echo "GRANT ALL ON TABLE hibernate_sequence TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_action TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_bytearray TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_byteblock TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_comment TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_decisionconditions TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_delegation TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_event TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_exceptionhandler TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_id_group TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_id_membership TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_id_permissions TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_id_user TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_job TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_log TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_moduledefinition TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_moduleinstance TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_node TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_pooledactor TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_processdefinition TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_processinstance TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_runtimeaction TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_swimlane TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_swimlaneinstance TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_task TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_taskactorpool TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_taskcontroller TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_taskinstance TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_token TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_tokenvariablemap TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_transition TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_variableaccess TO GROUP $JBPM_OWNER;" | $PSQL
  echo "GRANT ALL ON TABLE jbpm_variableinstance TO GROUP $JBPM_OWNER;" | $PSQL
}

# Deploy The Package Modeler Core DB
deploy_pm_core () {
  export PGDATABASE=$PM_DB
  $PSQL -f $PM_CORE_SQL
}

# Deploy The Package Modeler NDNP 
deploy_pm_ndnp () {
  export PGDATABASE=$PM_DB  
  $PSQL -f $PM_NDNP_SQL
}

# Deploy The Package Modeler NDNP 
deploy_jbpm () {
  export PGDATABASE=$JBPM_DB
  $PSQL -f $JBPM_SQL
}

# Deploy the Package Modeler Command Line Tool
deploy_pm_cli () {
  unzip -d $CLI_INSTALL_DIR $PM_CLI_TOOL
}

# Create the package modler database fixtures
install_pm_fixtures () {
  $FIXTURE_DRVR createrepository -id ndnp
  $FIXTURE_DRVR createperson -id ray -firstname Ray -surname Murray
  $FIXTURE_DRVR createperson -id myron -firstname Myron -surname Briggs
  $FIXTURE_DRVR createperson -id scott -firstname Scott -surname Phelps
  $FIXTURE_DRVR createsystem -id rdc-workflow
  $FIXTURE_DRVR createrole -id ndnp_awardee
  $FIXTURE_DRVR createorganization -id CU-Riv -name "University of California, Riverside" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id FUG -name "University of Florida Libraries, Gainesville" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id KyU -name "University of Kentucky Libraries, Lexington" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id NN -name "New York Public Library, New York City" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id UUML -name "University of Utah, Salt Lake City" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id VIC -name "Library of Virginia, Richmond" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id DLC -name "Library of Congress" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id MnHi -name "Minnesota Historical Society" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id NbU -name "University of Nebraska, Lincoln" -roles ndnp_awardee
  $FIXTURE_DRVR createorganization -id TxDN -name "University of North Texas, Denton" -roles ndnp_awardee
}

# Create the JBPM identity fixtures
install_jbpm_fixtures () {
  export PGDATABASE=$JBPM_DB
  echo "INSERT INTO JBPM_ID_GROUP VALUES(1,'G','ndnp-qr','organisation',NULL);" | $PSQL
  echo "INSERT INTO JBPM_ID_GROUP VALUES(2,'G','ndnp-sysadmin','organisation',NULL);" | $PSQL
  echo "INSERT INTO JBPM_ID_GROUP VALUES(3,'G','ndnp-participant','security-role',NULL);" | $PSQL
  echo "INSERT INTO JBPM_ID_GROUP VALUES(4,'G','ndnp-administrator','security-role',NULL);" | $PSQL
  echo "INSERT INTO JBPM_ID_USER VALUES(1,'U','ray','foo@loc.gov','ray');" | $PSQL
  echo "INSERT INTO JBPM_ID_USER VALUES(2,'U','myron','foo@loc.gov','myron');" | $PSQL
  echo "INSERT INTO JBPM_ID_USER VALUES(3,'U','scott','foo@loc.gov','scott');" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(1,'M','ray','ndnp-participant',1,3);" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(2,'M','ray','ndnp-qr',1,1);" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(3,'M','myron','ndnp-participant',2,3);" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(4,'M','myron','ndnp-qr',2,1);" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(5,'M','scott','ndnp-sysadmin',3,2);" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(6,'M','scott','ndnp-participant',3,3);" | $PSQL
  echo "INSERT INTO JBPM_ID_MEMBERSHIP VALUES(7,'M','scott','ndnp-administrator',3,4);" | $PSQL
}

# Deploy the Console App
deploy_console () {
  cp $CONSOLE_WAR $TOMCAT_HOME
}

# Deploy the Dashboard
deploy_claypool () {
  cp $CLAYPOOL_WAR $TOMCAT_HOME
  #TODO:
    # Open and modify
    # /Claypool/apps/NDNPTransfer/application-context.json to set the relative url of the transfer webapp
}

process_opts () {
  CALLER=`basename $0`
  while getopts iuh:d:r:t: ARG
    do case ${ARG} in
      u)   UPGRADE="true";;
      [?]) usage;;
      *)   usage;;  
    esac
  done
  #shift $(($OPTIND - 1))
  # Tests true if no switch is used at all
  #if [ $1 ]; then
  #  usage
  #fi
}

usage() {
  cat << EOF

  NDNP Transfer Deployment Script

  USAGE: $CALLER [-i -q -d -r] [-b] [-s SOURCE_DIRECTORY] [-d DESTINATION DIRECTORY]
  WHERE: -h = 
         -u = Upgrede 
         
EOF
}

process_opts
init_vars
sanity_checks

create_dbs
init_roles
init_core_perms
init_ndnp_perms
init_jbpm_perms

deploy_pm_core
deploy_pm_ndnp
deploy_jbpm
deploy_pm_cli

install_pm_fixtures
install_jbpm_fixtures
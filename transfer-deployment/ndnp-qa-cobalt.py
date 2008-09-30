#!/usr/bin/env python
""" Deploys a build of NDNP Transfer Services to QA 
"""

from transfer.core import services

config = {
    'DEBUG': False, # If True, will print out actions rather than take them (e.g., will not hit database)
    'TRANSFER_SERVICES_INSTALL_DIR': '/opt/transfer', # Set the directory that the CLI tools will be unzipped to (default = '.')
    'VERSION': 'CHANGEME_VERSION', # This is the version of the release being deployed
    'COMPONENT_PROJECTS': ("core","ndnp"),
    'HOST': 'cobalt', #The hostname, e.g., localhost or ac, that the service container is to be exposed under.  Also used to identify the responder.  Default is localhost.    
    'QUEUES': "jobqueue,firewirejobqueue,nasheadjobqueue", #List of the queues to listen to, e.g., jobqueue,firewirejobqueue.  Default is jobqueue
    'JOBTYPES': "test,inventoryfilesondisk,ndnplocalcopy,calculatedirectorysize,filesystemcreate", #List of the job types to handle, e.g., test,inventoryfilesondisk.  Default is test
    'DELEGATE_JOBTYPES': "inventoryfilesondisk,ndnplocalcopy",
    'COMPONENT_SELECTION': {'filesystemcreate': "mkDirFileSystemCreator"}, #Map of jobTypes to beanIds.  Used to select beans to use when there are multiple beans for a single jobType.
    'PGHOST': 'californium', # This is the host that the PostgreSQL database lives on (default = localhost)
    'PGPORT': '5432', # This is the port that PostgreSQL listens on (default = 5432)      
    'DB_PREFIX': 'qa', # This will prepend a custom prefix to the database name that will get created.  An _ will be appended. (default = '')
    'ROLE_PREFIX': 'qa', # This will prepend a custom prefix to the roles that will get created.  An _ will be appended. (default = '')
    'TRANSFER_PASSWD': '', # Set a password for the package modeler user role (default = 'transfer_user')
    'REQUEST_BROKER_PASSWD': '', # Set a password for the service_request_broker role (default = 'service_request_broker_user')
    'USER':'qatransfer', #Set the user that the service container should run as (default = 'transfer')
    'GROUP':'qatransfer', #Set the group for the service container (default = 'transfer')
    'RUN_NUMBER':'', #Set the run number for the service container (default = 85)

}

transfer_services = services.TransferServices(config)

# Uncomment to deploy transfer service drivers
transfer_services.deploy_drivers()
transfer_services.start_container()
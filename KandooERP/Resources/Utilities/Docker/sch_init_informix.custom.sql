database sysadmin;
grant dba to root;

execute function admin ('modify chunk extendable', 1);

execute function admin('STORAGEPOOL ADD', '/opt/ibm/data/spaces',
                      0,0,'10MB',1);
execute function admin('CREATE DBSPACE FROM STORAGEPOOL',
                       'datadbs', '1 GB');
execute function admin ('modify chunk extendable', 2);
execute function admin('CREATE SBSPACE FROM STORAGEPOOL',
                       'sbspace', '50 MB');
execute function admin('CREATE TEMPDBSPACE FROM STORAGEPOOL',
                       'tmpdbspace', '50 MB');

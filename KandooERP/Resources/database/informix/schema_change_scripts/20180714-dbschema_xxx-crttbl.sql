--# description: this script re-initializes the tables dbschema_fix and dbschema_properties
--# dependencies: 
--# tables list: dbschema_fix,dbschema_properties
--# author: ericv
--# date: 2018-12-23
--# Ticket # :
--# more comments: this script is mandatory to apply for snapshots < 2018-12-23
# it can also be used in case some patches have been ommitted
# this script must always contain the current schema of both tables
# eventually the unloaded data can be reloaded after creation 

unload to /tmp/dbschema_properties.unl.backup select * from dbschema_properties;
drop table if exists dbschema_properties;
create table "informix".dbschema_properties 
  (
    dbsname nchar(48),
    dbsvendor nchar(32),
    snapshot_date date,
    last_patch_date date,
    last_patch_apply datetime year to second,
    build_id nchar(32),
    last_patch_ok_scripts smallint,
    last_patch_ko_scripts smallint
  );

revoke all on "informix".dbschema_properties from "public" as "informix";

unload to /tmp/dbschema_fix.unl.backup select * from dbschema_fix;
drop table if exists dbschema_fix ;
create table "informix".dbschema_fix 
  (
    fix_name nchar(48),
    fix_dbvendor nchar(15) not null ,
    fix_abstract nchar(80) not null ,
    fix_type nchar(15) not null ,
    fix_dependencies nvarchar(255) not null ,
    fix_tableslist nvarchar(255) not null ,
    fix_create_date date,
    git_commit_hash nchar(50),
    fix_apply_date datetime year to second,
    fix_status nchar(2),
    primary key (fix_name)  constraint "informix".pk_dbschema_fix
  );

revoke all on "informix".dbschema_fix from "public" as "informix";

create index "informix".i_fix_abstract on "informix".dbschema_fix (fix_type,fix_abstract) using btree ;
create index "informix".i_fix_apply_date on "informix".dbschema_fix (fix_apply_date) using btree ;
create index "informix".i_fix_githash on "informix".dbschema_fix (git_commit_hash) using btree ;
create index "informix".i_fix_tabllist on "informix".dbschema_fix (fix_tableslist) using btree ;
create unique index "informix".pk_schemafix on "informix".dbschema_fix (fix_name,fix_status) using btree ;



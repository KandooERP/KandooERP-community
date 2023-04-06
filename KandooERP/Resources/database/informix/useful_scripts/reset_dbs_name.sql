begin work;
set constraints all deferred;
-- reset the database name in the dbschema_properties table
update dbschema_properties
set dbsname = "kandoodb_demo"
where 1 = 1;

-- reset the database name in the dbschema_fix table
update dbschema_fix
set fix_dbsname = "kandoodb_demo"
where 1 = 1;

-- reset the last date for OK patches series (ie starting from there to replay all patches)
-- this one is not mandatory to execute if no specific problem detected
--update dbschema_properties
--set last_patch_date = 
--(select max(fix_create_date) from dbschema_fix where fix_status matches 'OK*' and fix_create_date <= 
--( SELECT min(fix_create_date) FROM dbschema_fix WHERE fix_status IN ('KO','WAD') and dbsname = "kandoodb_demo" ))
--where 1 = 1;
--commit work;


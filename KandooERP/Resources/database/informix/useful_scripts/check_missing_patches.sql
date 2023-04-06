begin work;
set constraints all deferred;
insert into kandoodb_test:dbschema_fix
select * from kandoodb_clean:dbschema_fix
where fix_name not in ( select fix_name from dbschema_fix )
and fix_name matches "20191205-customertype-createpkconstraint"
and fix_create_date >= 
( SELECT max(snapshot_date)
FROM (
SELECT snapshot_date FROM kandoodb_clean:dbschema_properties
UNION ALL SELECT snapshot_date FROM dbschema_properties
)) order by 1 desc ;

update kandoodb_test:dbschema_fix
set fix_dbsname = "kandoodb_test"
--fix_status = NULL,
--fix_apply_date = NULL
where fix_dbsname = "kandoodb_clean";
--commit;

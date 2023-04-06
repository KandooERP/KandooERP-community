drop database if exists kandoodb_newly_imported ;

-- please check if the databdbs01 value is in your instance list of dbspaces
-- else do not modify "kandoodb_newly_imported"
-- at the bottom of this script, check and eventually fix the values of parameters of execute procedure import_from_external
create database kandoodb_newly_imported in datadbs01 ;
database kandoodb_newly_imported;

CREATE FUNCTION import_from_external(source_dbname varchar(250),load_path LVARCHAR(1024),target_dbname varchar(250),set_dbschema_tables CHAR(1)) 
       RETURNING varchar(250),INTEGER, INTEGER 
DEFINE table_num               INTEGER;
DEFINE bad               INTEGER;
DEFINE load_dir 	 LVARCHAR(512);
DEFINE create_database_stmt LVARCHAR(512);
DEFINE create_tables_file LVARCHAR(512);
DEFINE create_ext_tab    LVARCHAR(8192);
DEFINE ins               LVARCHAR(512);
DEFINE drop_ext_tab      LVARCHAR(512);
DEFINE intermediate_dbname,tname,constr_name,trigger_name,index_name VARCHAR(250);
DEFINE ext_tname         VARCHAR(250);
DEFINE dbschema          LVARCHAR(1024);
DEFINE create_tables_cmd         LVARCHAR(512);
DEFINE cmd         LVARCHAR(512);
DEFINE numrows,stringlength,table_id           INTEGER;

LET table_num=0;
LET bad=0;

SET DEBUG FILE TO "/tmp/import_from_external.log";
TRACE ON;
IF TRIM(source_dbname) = '' THEN
	LET source_dbname = DBINFO("dbname")  ;
END IF

IF TRIM(target_dbname) = '' THEN
	LET target_dbname = "kandoodb";
END IF

LET intermediate_dbname = DBINFO("dbname")  ;

IF set_dbschema_tables = '' THEN
	LET set_dbschema_tables = 'Y';
ELSE
	LET set_dbschema_tables = 'Y';
END IF

LET load_dir = TRIM(load_path) || "/" || TRIM(source_dbname) || ".exp" ;
LET create_tables_file = TRIM(load_dir) || "/" || TRIM(source_dbname) ;
-- first create the tables from the database.exp/database.sql file
LET create_tables_cmd = "dbaccess kandoodb_newly_imported " || create_tables_file ;
SYSTEM create_tables_cmd ;

SELECT count(*)
INTO table_num
FROM systables
WHERE tabid > 99;
RETURN "NumberOfTablesCreated ",table_num,1 WITH RESUME;

-- disable foreign keys
FOREACH SELECT constrname,constrid
INTO constr_name,table_id
FROM sysconstraints
WHERE tabid > 99
AND constrtype in ("R")
ORDER BY constrid DESC
     LET cmd = "SET CONSTRAINTS "|| constr_name || " DISABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH


-- disable primary keys and unique keys
FOREACH SELECT constrname,constrid
INTO constr_name,table_id
FROM sysconstraints
WHERE tabid > 99
AND constrtype in ("P","U")
ORDER BY constrid DESC
     LET cmd = "SET CONSTRAINTS "|| constr_name || " DISABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH

-- disable triggers
FOREACH SELECT trigname,trigid
INTO trigger_name,table_id
FROM systriggers
WHERE tabid > 99
ORDER BY trigid DESC
     LET cmd = "SET TRIGGERS "|| trigger_name || " DISABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH

RETURN "IndexesConstraintsTriggersDisabled ",table_num,1 WITH RESUME;
LET table_num = 0;

-- now we load all the tables
FOREACH SELECT   TRIM(tabname),length(trim(tabname)),tabid
     INTO tname,stringlength,table_id
     FROM systables
     WHERE tabid >99 
     AND tabtype = "T"
	ORDER by tabid 

     LET ext_tname = trim(tname)||"_ext" ;
     LET drop_ext_tab = "DROP TABLE IF EXISTS "||ext_tname;
     EXECUTE IMMEDIATE drop_ext_tab;

     LET create_ext_tab = "CREATE EXTERNAL TABLE "||ext_tname||
        " SAMEAS "||tname||" USING (" ||
        "DATAFILES('DISK:"||load_dir||"/"||tname||".unl'),"||
        "FORMAT 'DELIMITED', "|| "DELIMITER '|', "||
        "EXPRESS, ESCAPE, "||
        "NUMROWS 100000 , MAXERRORS  100, "||
        "REJECTFILE '"||load_dir||"/"||tname||".reject' " ||
        " )";
     EXECUTE IMMEDIATE create_ext_tab;

     -- disable indexes for this table
     LET cmd = "SET INDEXES FOR "|| tname || " DISABLED" ;
     EXECUTE IMMEDIATE cmd;
     LET ins = "INSERT INTO "||tname || " SELECT * FROM "||ext_tname;
     -- LET ins = "CREATE TABLE " || tname || " AS  SELECT * FROM "||ext_tname;
     EXECUTE IMMEDIATE ins;

     EXECUTE IMMEDIATE drop_ext_tab;

	LET cmd = "SELECT count(*) FROM " || trim(tname) ;
	PREPARE p_stmt FROM cmd;
	DECLARE crs_count_rows CURSOR FOR p_stmt;
	OPEN crs_count_rows;
	FETCH crs_count_rows INTO numrows ;
	CLOSE crs_count_rows;
	FREE crs_count_rows;
	FREE p_stmt;

     LET table_num= table_num + 1;
	RETURN tname,table_num,numrows WITH RESUME;

END FOREACH

-- adapt dbschema_xx table contents with the target database name
IF set_dbschema_tables = 'Y' THEN
	--SET CONSTRAINTS FOR dbschema_properties DISABLED;
	--SET CONSTRAINTS FOR dbschema_fix DISABLED;
	-- delete 'old' patch history, i.e delete all before first error or waiting patch
	LET cmd="TRUNCATE TABLE dbschema_fix_errors" ;
	EXECUTE IMMEDIATE cmd;
	LET cmd="TRUNCATE TABLE dbschema_fix_log" ;
	EXECUTE IMMEDIATE cmd;
	LET cmd = "DELETE FROM dbschema_fix WHERE fix_create_date < ( SELECT min(fix_create_date) FROM dbschema_fix WHERE fix_status IN ('KO','WA'))";
	EXECUTE IMMEDIATE cmd;
	-- reset the right database name (because export data come from kandoodb_demo and this database is kandoodb
	LET cmd = "UPDATE dbschema_properties SET dbsname = '"||trim(target_dbname)||"' WHERE 1=1 ";
	EXECUTE IMMEDIATE cmd;
	LET cmd = "UPDATE dbschema_fix SET fix_dbsname = '"||trim(target_dbname)||"' WHERE 1=1 ";
	EXECUTE IMMEDIATE cmd;
END IF

-- enable indexes for all tables
FOREACH SELECT   TRIM(tabname)
     INTO tname
     FROM systables
     WHERE tabid >99 
     AND tabtype = "T"
     LET cmd = "SET INDEXES FOR "|| tname || " ENABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH

-- enable primary keys and unique keys
FOREACH SELECT constrname,constrid
INTO constr_name,table_id
FROM sysconstraints
WHERE tabid > 99
AND constrtype in ("P","U")
ORDER BY constrid 
     LET cmd = "SET CONSTRAINTS "|| constr_name || " ENABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH

-- enable foreign keys
FOREACH SELECT constrname,constrid
INTO constr_name,table_id
FROM sysconstraints
WHERE tabid > 99
AND constrtype in ("R")
ORDER BY constrid
     LET cmd = "SET CONSTRAINTS "|| constr_name || " ENABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH

-- enable triggers
FOREACH SELECT trigname,trigid
INTO trigger_name,table_id
FROM systriggers
WHERE tabid > 99
ORDER BY trigid DESC
     LET cmd = "SET TRIGGERS "|| trigger_name || " ENABLED" ;
     EXECUTE IMMEDIATE cmd;
END FOREACH

RETURN "allTables",table_num, bad;

END FUNCTION;

---- execute the import procedure
-- description of arguments:
--import_from_external(source_dbname ,load_path,target_dbname,set_dbschema_tables CHAR(1)) 
execute procedure import_from_external("kandoodb_demo","/home/informix/Projects/KandooERP/KandooERP/Resources/database/informix/db_snapshots/community_database","kandoodb","Y");

-- set the database to the right log mode
database sysadmin;
EXECUTE FUNCTION task("alter logmode","kandoodb_newly_imported","b");

-- execute final ontape to validate log mode change
EXECUTE FUNCTION task("ontape archive level 0", "/dev/null");
close database;

RENAME DATABASE kandoodb_newly_imported TO kandoodb;

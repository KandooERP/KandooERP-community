DROP FUNCTION IF EXISTS export_kandoo_database ;
CREATE FUNCTION export_kandoo_database(load_path LVARCHAR(512) ) 
       RETURNING INTEGER, INTEGER
DEFINE rc                INTEGER;
DEFINE bad               INTEGER;
DEFINE load_dir 	 LVARCHAR(512);
DEFINE create_ext_tab    LVARCHAR(8192);
DEFINE ins               LVARCHAR(512);
DEFINE drop_ext_tab      LVARCHAR(512);
DEFINE tname             VARCHAR(250);
DEFINE ext_tname         VARCHAR(250);
DEFINE dbschema          LVARCHAR(1024);
DEFINE mkdir_cmd         VARCHAR(250);
DEFINE opendb_stmt       VARCHAR(250);
DEFINE numrows           INTEGER;
DEFINE sql_statement     LVARCHAR(1024);
DEFINE dbname VARCHAR(128);

LET rc=0;
LET bad=0;

--SET DEBUG FILE TO "/tmp/export_kandoo_database.log";
--TRACE ON;
LET dbname = DBINFO("dbname")  ;
LET load_dir = TRIM(load_path) || "/" || TRIM(dbname) || ".exp" ;
LET mkdir_cmd = "mkdir -p " || load_dir;
SYSTEM mkdir_cmd ;

SET ISOLATION TO DIRTY READ;

FOREACH SELECT   TRIM(tabname) ,nrows
     INTO tname,numrows
     FROM systables
     WHERE tabid >99 AND tabtype = "T"

     LET ext_tname = tname||"_ext" ;
     LET drop_ext_tab = "DROP TABLE IF EXISTS "||ext_tname;
     EXECUTE IMMEDIATE drop_ext_tab;

     LET create_ext_tab = "CREATE EXTERNAL TABLE "||ext_tname||
        " SAMEAS "||tname||" USING (" ||
        "DATAFILES('DISK:"||load_dir||"/"||tname||".unl'),"||
        "FORMAT 'DELIMITED', "|| "DELIMITER '|', "||
        "RECORDEND '', "||  "EXPRESS, ESCAPE, "||
        "NUMROWS "|| numrows+1||", "||    "MAXERRORS  100, "||
        "REJECTFILE '"||load_dir||"/"||tname||".reject' " ||
        " )";

     LET ins = "INSERT INTO "||tname||"_ext SELECT * FROM "||tname;

     EXECUTE IMMEDIATE create_ext_tab;
     EXECUTE IMMEDIATE ins;

     EXECUTE IMMEDIATE drop_ext_tab;

     LET rc = rc + 1;

END FOREACH

LET dbschema = "dbschema -q -d "||TRIM(dbname)||" -it DR -ss "||
                TRIM(load_dir)||"/"||TRIM(dbname)||".sql";

SYSTEM dbschema;
-- external tables are dropped after dbschema
FOREACH SELECT tabname
	INTO ext_tname 
	FROM systables
	WHERE tabtype = 'E'
	AND tabname MATCHES "*_ext"
	AND created = today

	LET drop_ext_tab = "DROP TABLE " || ext_tname;
	EXECUTE IMMEDIATE drop_ext_tab ;
END FOREACH

RETURN rc, bad;

END FUNCTION;

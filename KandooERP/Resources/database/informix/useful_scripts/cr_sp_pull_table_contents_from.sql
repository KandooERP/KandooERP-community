drop procedure if exists "informix".pull_table_contents_from ;
create procedure "informix".pull_table_contents_from (tabname varchar(128),source_dbname varchar(128),truncate_target char(10),special_statement LVARCHAR(1024) DEFAULT NULL);
DEFINE sql_statement LVARCHAR(2048);
SET DEBUG FILE TO "/tmp/pull_table_contents_from.dbg";
trace on;

IF ( truncate_target matches "trunc*" ) THEN
    LET sql_statement = "DELETE FROM " || trim(tabname) ;
    EXECUTE IMMEDIATE sql_statement;
END IF;
LET sql_statement = " INSERT INTO " || trim (tabname)  || " SELECT * FROM " || trim(source_dbname)|| ":" || trim(tabname) ;
EXECUTE IMMEDIATE sql_statement;

END PROCEDURE;


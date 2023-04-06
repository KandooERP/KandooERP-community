CREATE FUNCTION "informix".copy_company_data_for_table(p_table_name VARCHAR(128),p_source_cmpy CHAR(2),p_target_cmpy CHAR(2),p_source_database_name VARCHAR(128) default NULL)
       RETURNING INTEGER
DEFINE sql_statement     LVARCHAR(4096);
DEFINE l_colname     LVARCHAR(128);
DEFINE l_colno     INTEGER;
DEFINE l_colnumber INTEGER;

-- This function allows to copy the data of some kandoo company to another company
-- it can be used for instance to copy some "template" tables from one company to another,
-- such as COA, products hierarchy, categories etc
-- the target company needs to exist, unless you copy the company itself (in that case, you will have to modify new company data manually
-- referential constraints must of course be respected
-- inbound parameters: table name, source company and target company
-- ex: execute function copy_company_data_for_table("product","99","XX") will copy the contents of the product table in company 99 to the XX company
--SET DEBUG FILE TO "/tmp/copy_company_data_for_table.log";
--TRACE ON;

SET ISOLATION TO DIRTY READ;
-- first build the first part of insert statement with column names
LET l_colnumber = 0;
LET sql_statement = "INSERT INTO  "||trim(p_table_name)|| " (";

FOREACH SELECT c.colname,c.colno
    INTO l_colname,l_colno
    FROM systables t,syscolumns c
    where t.tabname = trim(p_table_name)
    AND t.tabid = c.tabid
    AND t.tabtype = "T"
    ORDER BY c.colno

    IF l_colname = "cmpy_code" THEN
        CONTINUE FOREACH;
    END IF
    LET l_colnumber = l_colnumber + 1;
    LET sql_statement = trim(sql_statement)||trim(l_colname)||",";

END FOREACH

-- we put cmpy_code at the end to make it easy for the last ,
LET sql_statement = trim(sql_statement)|| "cmpy_code ) SELECT ";

FOREACH SELECT c.colname,c.colno
    INTO l_colname,l_colno
    FROM systables t,syscolumns c
    where t.tabname = trim(p_table_name)
    AND t.tabid = c.tabid
    AND t.tabtype = "T"
    ORDER BY c.colno

    IF l_colname = "cmpy_code" THEN
        CONTINUE FOREACH;
    END IF

    IF p_table_name = "company" AND l_colname = "name_text" THEN
        -- name this company as "duplicate of " this company
--TRACE ON;
        LET sql_statement =trim(sql_statement)||" 'duplicate of ||trim(l_colname)'"||", ";
--TRACE off;
    ELSE
        LET sql_statement =trim(sql_statement)||" "||trim(l_colname)||",";
    END IF

END FOREACH

-- we put cmpy_code at the end to make it easy for the last ,
IF p_source_database_name IS NULL THEN
	LET sql_statement = trim(sql_statement)||"'"||trim(p_target_cmpy)||"' FROM "||trim(p_table_name)|| " WHERE cmpy_code = '" || trim(p_source_cmpy) || "'"  ;
ELSE
	LET sql_statement = trim(sql_statement)||"'"||trim(p_target_cmpy)||"' FROM "||trim (p_source_database_name)||":"||trim(p_table_name)|| " WHERE cmpy_code = '" || trim(p_source_cmpy) || "'"  ;
END IF
EXECUTE IMMEDIATE sql_statement;

RETURN l_colnumber;

END FUNCTION;


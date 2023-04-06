--# description:  this script creates 2 generic new tables whose purpose is to manage database driven comments on tables and columns
--# dependencies:
--# tables list:  qx_table_comments,column_documentation,table_documentation
--# author: ericv
--# date: 2019-06-09
--# Ticket # :
--# more comments: Also creates describe_table and describe_column stored procedures

-- drop the table with the former name
drop table if exists qx_table_comments;
drop table if exists table_documentation ;
create table table_documentation (
   tabname varchar(128),
   tabtype char(10),
   language_code char(3),
   documentation nvarchar(255)
)
;
create unique index ui_table_documentation on table_documentation(tabname,language_code) ;
--

drop table if exists qx_column_comments;
drop table if exists column_documentation ;
create table column_documentation (
   tabname varchar(128),
   colname varchar(128),
   language_code char(3),
   colno integer,
   documentation nvarchar(255)
);
create unique index ui_column_table_documentation on column_documentation(tabname,colname,language_code) ;
create index di_column_table_documentation on column_documentation(tabname,language_code) ;

-- use the following query to proceed to initial feed of the table_documentation table
insert into table_documentation
SELECT t.tabname,
CASE
      WHEN t.tabtype = "T" THEN "table"
      WHEN t.tabtype = "Q" THEN "sequence"
      WHEN t.tabtype = "V" THEN "view"
      WHEN t.tabtype = "E" THEN "external"
      ELSE NULL
END,
"ENU",
"documentation of " || t.tabname
from systables t
where t.tabid > 99
and t.tabname not in ( SELECT tabname from table_documentation );

-- use the following query to proceed to the initial feed if  the column_documentation table
insert into column_documentation
SELECT t.tabname,c.colname,"ENU",c.colno,"documentation of " || c.colname
from syscolumns c,systables t
where c.tabid > 99
and c.tabid = t.tabid
and (t.tabname not in ( SELECT tabname from column_documentation ) and c.colname not in ( SELECT colname from column_documentation )) ;

-- adding primary keys and foreign key
alter table table_documentation add constraint primary key(tabname,language_code) constraint pk_table_documentation ;
alter table column_documentation add constraint primary key(tabname,colname,language_code) constraint pk_column_documentation ;
alter table column_documentation add constraint foreign key(tabname,language_code) references table_documentation (tabname,language_code) constraint fk_column_table_documentation ;

 -- use the follwoing query to query the table comments
--select t.tabname,d.documentation,d.tabtype
--from systables t,table_documentation d
--where t.tabname = d.tabname 
--and d.tabtype != "table"
--order by d.tabname ;

-- use the following query to query the columns comments
--select t.tabname,c.colname,column_documentation.documentation,c.colno
--from systables t,syscolumns c,column_documentation
--where t.tabname = column_documentation.tabname
--and c.tabid = t.tabid
--and c.colname = column_documentation.colname
--order by  1,4


drop procedure if exists print_table_doc;
create procedure print_table_doc ( p_tabname varchar(128),p_language_code char(3)) returning nvarchar(255) ;
DEFINE p_documentation nvarchar(255);

IF p_language_code IS NULL THEN
   LET p_language_code = "ENU";
END IF;

LET p_documentation = 
( SELECT documentation FROM table_documentation
WHERE tabname = p_tabname
AND language_code = p_language_code ) ;

IF p_documentation IS NOT NULL THEN
	RETURN p_documentation;
ELSE
	RETURN "table not documented for this language";
END IF

end procedure;

drop procedure if exists set_table_doc;
-- this procedure set the value of the table documentation, for the specified language
-- it will update the value if the record exists, else it will insert it
create procedure set_table_doc ( p_tabname varchar(128),p_language_code char(3),p_documentation nvarchar(255)) returning nvarchar(255) ;
DEFINE p_tabtype char(10);
DEFINE return_message  nvarchar(255);

IF p_language_code IS NULL THEN
   LET p_language_code = "ENU";
END IF;


-- we directly attempt to update the eventually existing record
UPDATE table_documentation
SET documentation = p_documentation
WHERE tabname = p_tabname
AND language_code = p_language_code ;
IF DBINFO('sqlca.sqlerrd2') > 0 THEN
	LET return_message = p_tabname || ":documentation updated!" ;
END IF

-- if the record does not exist, it is inserted!
IF DBINFO('sqlca.sqlerrd2') = 0 THEN
	LET p_tabtype = ( SELECT tabtype FROM systables WHERE tabname = p_tabname ) ;
	INSERT INTO table_documentation VALUES ( p_tabname,p_tabtype,p_language_code,p_documentation);
	LET return_message = p_tabname || ":documentation inserted!" ;
END IF;
RETURN return_message ;

end procedure;

drop procedure if exists print_column_doc;
-- this procedure print the documentation of the column, within a given table, for a specified language
create procedure print_column_doc ( p_tabname varchar(128),p_colname varchar(128),p_language_code char(3)) returning nvarchar(255) ;
DEFINE p_documentation nvarchar(255);

IF p_language_code IS NULL THEN
   LET p_language_code = "ENU";
END IF;

LET p_documentation = 
( SELECT documentation FROM column_documentation
WHERE tabname = p_tabname
AND colname = p_colname
AND language_code = p_language_code ) ;

IF p_documentation IS NOT NULL THEN
	RETURN p_documentation;
ELSE
	RETURN "column not documented for this language";
END IF

end procedure;


drop procedure if exists set_column_doc;
-- this procedure set the value of the column documentation, for the specified language
-- it will update the value if the record exists, else it will insert it
create procedure set_column_doc ( p_tabname varchar(128),p_colname varchar(128),p_language_code char(3),p_documentation nvarchar(255)) returning nvarchar(255) ;
DEFINE return_message  nvarchar(255);

IF p_language_code IS NULL THEN
   LET p_language_code = "ENU";
END IF;


-- we directly attempt to update the eventually existing record
UPDATE column_documentation
SET documentation = p_documentation
WHERE tabname = p_tabname
AND colname = p_colname
AND language_code = p_language_code ;
IF DBINFO('sqlca.sqlerrd2') > 0 THEN
	LET return_message = p_tabname || "." || p_colname || ":documentation updated!" ;
END IF

-- if the record does not exist, it is inserted!
IF DBINFO('sqlca.sqlerrd2') = 0 THEN
	INSERT INTO column_documentation VALUES ( p_tabname,p_colname,p_language_code,p_documentation);
	LET return_message = p_tabname || "." || p_colname || ":documentation inserted!" ;
END IF;
RETURN return_message ;

end procedure;


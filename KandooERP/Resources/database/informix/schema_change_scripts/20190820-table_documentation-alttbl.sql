--# description: this script renames some columns of table_documentation
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: table_documentation,column_documentation
--# author: eric vercelletto
--# date: 2019-08-10
--# Ticket # :
--# more comments:
alter table table_documentation add mtime datetime year to second;
alter table column_documentation add mtime datetime year to second;

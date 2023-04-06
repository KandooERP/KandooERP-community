--# description: this script renames prodledg.adj_type_code to source_code
--# tables list: prodledg
--# dependencies: 
--# author: ericv
--# date: 2020-09-01
--# Ticket #  	
--# Comments: finally we found out that this column points to 7 tables keys
--# so: we use a generic name 'source_code' that will point to all the tables, with same datatype for all 
--# source_text will be used for free text only
--# we add source_type to specify the type of source_code, values are  CUST,WARE,VEND,PERS,PRAD
rename column prodledg.adj_type_code to source_code;
alter table prodledg add (source_type CHAR(4));
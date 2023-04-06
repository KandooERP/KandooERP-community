--# description: this script creates 2 new columns to the company table
--# dependencies: 20200416.000-company-dependency
--# tables list: company
--# author: ericv
--# date: 2020-04-16
--# Ticket # : KD-1965
--# 
ALTER TABLE company ADD (cmpy_type NCHAR(4), sic_code NCHAR(8)) ;
update company set cmpy_alias = cmpy_code where 1 = 1;
update company set cmpy_type = "DEMO" where 1 = 1;

ALTER TABLE company add constraint check (cmpy_type in ("TMPL","DEMO","PROD","TEST","DEVL")) constraint ck_cmpy_type;

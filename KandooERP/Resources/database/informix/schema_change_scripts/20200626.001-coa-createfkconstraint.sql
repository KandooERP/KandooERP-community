--# description: this script creates a foreign key from coa to groupinfo
--# tables list: groupinfo,coa
--# author: ericv
--# date: 2020-06-26
--# Ticket 	
--# Comments: check data with this query
--# SELECT group_code,cmpy_code from coa WHERE group_code||cmpy_code not in ( SELECT group_code||cmpy_code FROM groupinfo )

alter table groupinfo modify (group_code nchar(7));
drop index if exists d01_coa ;
create index if not exists d01_coa on coa (group_code,cmpy_code);
alter table coa add constraint foreign key (group_code,cmpy_code) references groupinfo (group_code,cmpy_code) constraint fk_coa_groupinfo;

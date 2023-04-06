--# description: this script creates a foreign key from validflex to groupinfo
--# tables list: groupinfo,validflex
--# author: ericv
--# date: 2020-07-09
--# Ticket 	
--# Comments: check data with this query
--# SELECT group_code,cmpy_code from validflex WHERE group_code||cmpy_code not in ( SELECT group_code||cmpy_code FROM groupinfo )

drop index if exists d01_validflex ;
create index if not exists d01_validflex on validflex (group_code,cmpy_code);
alter table validflex add constraint foreign key (group_code,cmpy_code) references groupinfo (group_code,cmpy_code) constraint fk_validflex_groupinfo;

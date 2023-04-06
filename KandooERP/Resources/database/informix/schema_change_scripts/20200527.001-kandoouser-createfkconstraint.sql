--# description: this script create foreign key for kandoouser table to company
--# tables list: kandoouser
--# author: ericv
--# date: 2020-05-27
--# Ticket # : 	
--# dependencies:
--# more comments: check violations with the following query
--# select cmpy_code from kandoouser where  cmpy_code not in (select  cmpy_code from company)

create index if not exists d01_kandoouser on kandoouser(cmpy_code);
alter table kandoouser add constraint foreign key (cmpy_code) references company(cmpy_code) constraint "informix".fk_kandoouser_company ;
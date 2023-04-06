--# description: this script create foreign key for prodledg table to prodstatus
--# tables list: prodledg
--# author: ericv
--# date: 2020-05-26
--# Ticket # : 	
--# dependencies:
--# more comments: check violations with the following query
--# select part_code||ware_code||cmpy_code from prodledg where  part_code||ware_code||cmpy_code not in (select  part_code||ware_code||cmpy_code from prodstatus)

create index d01_prodledg on prodledg(part_code,ware_code,cmpy_code);
alter table prodledg add constraint foreign key (part_code,ware_code,cmpy_code) references prodstatus(part_code,ware_code,cmpy_code) constraint "informix".fk_prodledg_prodstatus ;


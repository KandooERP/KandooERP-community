--# description: this script creates a foreign key for ibtdetl to ibthead
--# tables list: ibtdetl
--# author: ericv
--# date: 2020-06-01
--# Ticket # : 	
--# dependencies:
--# more comments:

create index if not exists d02_ibtdetl on ibtdetl (trans_num,cmpy_code);
alter table ibtdetl add constraint foreign key(trans_num,cmpy_code) references ibthead(trans_num,cmpy_code) constraint fk3_ibtdetl_ibthead;

--# description: this script create indexes and constraints on coa
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: coa
--# author: eric vercelletto
--# date: 2019-09-29
--# Ticket # :
--# more comments: 
create index d_coa_01 on coa(cmpy_code) ;
alter table coa add constraint foreign key (cmpy_code) references company(cmpy_code) constraint fk_coa_company;

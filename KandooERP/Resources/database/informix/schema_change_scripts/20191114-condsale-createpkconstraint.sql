--# description: this script create a PK constraints on condsale
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: condsale
--# author: eric vercelletto
--# date: 2019-11-14
--# Ticket # :
--# more comments: 
--rollback;
begin work;
delete from condsale where 1=1;
create unique index if not exists u_condsale on condsale (cond_code,cmpy_code);
alter table condsale add constraint primary key (cond_code,cmpy_code) constraint pk_condsale;
load from unl/20191114-condsale.unl insert into condsale;
commit work;

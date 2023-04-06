--# description: this script creates a primary key for vendorinvs
--# dependencies: 
--# tables list:  vendorinvs
--# author: Eric Vercelletto
--# date: 2020-12-29
--# Ticket: 
--# more comments:

alter table vendorinvs drop constraint pk_vendorinvs ;
drop index if exists vendi_key;
create unique index if not exists u_vendorinvs_inv_text on vendorinvs (inv_text,vend_code,year_num,cmpy_code);
alter table vendorinvs add constraint primary key (inv_text,vend_code,year_num,cmpy_code) constraint pk_vendorinvs ;
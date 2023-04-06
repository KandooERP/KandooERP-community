--# description: this script makes changes in vendornote (more modern schema)
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: vendornote
--# author: eric vercelletto	
--# date: 2019-08-22
--# Ticket # : 	KD-926
--# more comments:
drop index if exists "informix".vendnote_key ;
create unique index "informix".u_vendnote on "informix".vendornote (vend_code,note_date,cmpy_code) using btree ;
alter table "informix".vendornote add constraint primary key (vend_code,note_date,cmpy_code) constraint "informix".pk_vendornote  ;
create index "informix".i_vendnote_01 on "informix".vendornote (vend_code,cmpy_code) using btree ;
alter table "informix".vendornote add constraint foreign key (vend_code,cmpy_code) references vendor (vend_code,cmpy_code) constraint "informix".fk_vendornote_vendor  ;


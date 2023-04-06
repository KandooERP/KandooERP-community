--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: poaudit
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
create unique index u_poaudit on poaudit(po_num,line_num,seq_num,cmpy_code);
alter table poaudit add constraint primary key (po_num,line_num,seq_num,cmpy_code) constraint pk_poaudit;


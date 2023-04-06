--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: faaudit
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_faaudit on faaudit(batch_num,batch_line_num,cmpy_code);
alter table faaudit add constraint primary key (batch_num,batch_line_num,cmpy_code) constraint pk_faaudit;

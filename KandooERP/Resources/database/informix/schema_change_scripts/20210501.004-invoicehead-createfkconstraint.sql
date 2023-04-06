--# description: this script foreign keys on invoicehead to job
--# dependencies: 
--# tables list:  invoicehead,job
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicehead  add constraint foreign key (job_code,cmpy_code) references  job (job_code,cmpy_code)  constraint fk_invoicehead_job;
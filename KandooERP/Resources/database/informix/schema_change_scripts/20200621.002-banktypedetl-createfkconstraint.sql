--# description: this script creates a foreign key from banktypedetl to banktype
--# tables list: banktypedetl
--# author: albo
--# date: 2020-06-21
--# Ticket # KD-2121 	

on exception -623 status=OKE ;
alter table banktypedetl drop constraint fk_banktypedetl_banktype;
alter table banktypedetl add constraint (foreign key (type_code) references banktype (type_code) constraint fk_banktypedetl_banktype);

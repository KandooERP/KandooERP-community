--# description: this script creates creates a new column on contact_address
--# dependencies: 
--# tables list: contact_address
--# author: ericv
--# date: 2018-09-22
--# Ticket # :
--# more comments:

alter table contact_address add contact_id integer before address_id;
create index fk_contact_addr_02 on contact_address(contact_id );
--alter table contact_address  add constraint foreign key(contact_id )
--references contact(contact_id) constraint fk_contact_addr_02;

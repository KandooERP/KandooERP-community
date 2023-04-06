--# description: this script creates a foreign key constraint from voucher to vendor
--# dependencies: n/a
--# tables list: voucher
--# author: ericv
--# date: 2020-05-15
--# Ticket # : 
--# Comments: please try the following command if you get a constraint violation, and DELETE those rows if any shows up
--# SELECT cmpy_code from voucher WHERE cmpy_code NOT IN (SELECT cmpy_code FROM vendor )

create index d01_voucher on voucher (vend_code,cmpy_code) using btree;
ALTER TABLE voucher ADD CONSTRAINT FOREIGN KEY (vend_code,cmpy_code) references vendor CONSTRAINT fk_voucher_vendor;

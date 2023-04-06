--# description: this script creates a foreign key constraint from postinvoice to coa
--# dependencies: n/a
--# tables list: postinvoice
--# author: ericv
--# date: 2020-05-28
--# Ticket # : 
--# 
create index d02_postinvoice on postinvoice (ar_acct_code, cmpy_code);
ALTER TABLE postinvoice ADD CONSTRAINT FOREIGN KEY (ar_acct_code, cmpy_code) references coa(acct_code, cmpy_code) CONSTRAINT fk1_postinvoice_coa;

create index d03_postinvoice on postinvoice(freight_acct_code, cmpy_code);
ALTER TABLE postinvoice ADD CONSTRAINT FOREIGN KEY (freight_acct_code, cmpy_code) references coa(acct_code, cmpy_code) CONSTRAINT fk2_postinvoice_coa;

create index d04_postinvoice on postinvoice (lab_acct_code, cmpy_code);
ALTER TABLE postinvoice ADD CONSTRAINT FOREIGN KEY (lab_acct_code, cmpy_code) references coa(acct_code, cmpy_code) CONSTRAINT fk3_postinvoice_coa;

create index d05_postinvoice on postinvoice (tax_acct_code, cmpy_code);
ALTER TABLE postinvoice ADD CONSTRAINT FOREIGN KEY (tax_acct_code, cmpy_code) references coa(acct_code, cmpy_code) CONSTRAINT fk4_postinvoice_coa;
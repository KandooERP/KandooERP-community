--# description: this script adds columns iban and bic to vendor
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: vendor
--# author: eric vercelletto	
--# date: 2019-08-23
--# Ticket # : 	
--# more comments:
alter table vendor add iban_code nchar(34) before pay_meth_ind;	-- IBAN or NACHA bank references for money transfers
alter table vendor add bic_code nchar(11) before pay_meth_ind; -- BIC or SWIFT bank references for money transfers

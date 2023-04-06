--# description: this script adds columns iban and bic to customer
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: customer
--# author: eric vercelletto	
--# date: 2019-08-23
--# Ticket # : 	
--# more comments:
alter table customer add iban_code nchar(34) before delete_flag;   -- IBAN or NACHA bank references for money transfers
alter table customer add bic_code nchar(11) before delete_flag;   -- BIC or SWIFT bank references for money transfers

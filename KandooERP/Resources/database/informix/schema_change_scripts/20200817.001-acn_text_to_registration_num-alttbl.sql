--# description: this script renames the field acn_text to registration_num
--# tables list: company,customeraudit,customer,vendoraudit,vendor
--# dependencies: 20200817.000-acn_text-dependencies 
--# author: ericv
--# date: 2020-03-20
--# Ticket # : 	KD-1859
--# more comments:

rename column customer.acn_text to registration_num

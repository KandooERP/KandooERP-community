--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: vendor
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
rename constraint pky_vendor to pk_vendor

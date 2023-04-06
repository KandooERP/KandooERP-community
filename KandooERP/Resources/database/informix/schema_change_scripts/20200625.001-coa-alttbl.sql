--# description: this script extends the description of coa
--# tables list: coa
--# dependencies: 
--# author: ericv
--# date: 2020-06-25
--# Ticket #  	

 
alter table coa modify (desc_text nvarchar(90,50)) ;

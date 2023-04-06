--# description: this script makes changes in data of country table
--# dependencies: 
--# tables list: country
--# author: albo	
--# date: 2021-01-27
--# Ticket # : 	KD-2541
update country set post_code_text = "PostCode" where country_code = "GB";

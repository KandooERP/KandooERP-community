--# description: this script loads data to coatempltdetl
--# tables list: coatempltdetl
--# dependencies: 
--# author: ericv
--# date: 2020-06-24
--# Ticket #  KD-2239	

delete from coatempltdetl WHERE language_code = "FR" and country_code = "FR";
delete from coatemplthead WHERE language_code = "FR" and country_code = "FR";
INSERT INTO coatemplthead VALUES ("FR","FR","The French Chart of Account in French","01/01/2019","Very detailed chart");
load from unl/coa-FR-FR.tmplt INSERT INTO coatempltdetl ; 
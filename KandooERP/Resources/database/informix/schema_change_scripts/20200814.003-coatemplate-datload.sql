--# description: this script loads data to coatempltdetl
--# tables list: coatempltdetl
--# dependencies: 
--# author: ericv
--# date: 2020-06-24
--# Ticket #  KD-2239	

delete from coatempltdetl WHERE language_code = "ENG" and country_code in ("FR");
delete from coatemplthead WHERE language_code = "ENG" and country_code in ("FR");
INSERT INTO coatemplthead VALUES ("FR","ENG","The French Chart of Account in English","14/08/2020","Very detailed chart, may be used for European countries");
load from unl/20200814-coa-FR-ENG.tmplt INSERT INTO coatempltdetl;
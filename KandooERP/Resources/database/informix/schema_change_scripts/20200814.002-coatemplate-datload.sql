--# description: this script loads data to coatempltdetl, new version
--# tables list: coatempltdetl
--# dependencies: 
--# author: ericv
--# date: 2020-08-14
--# Ticket #  KD-2239	

delete from coatempltdetl WHERE language_code = "FRA" and country_code = "FR";
delete from coatemplthead WHERE language_code = "FRA" and country_code = "FR";
INSERT INTO coatemplthead VALUES ("FR","FRA","The French Chart of Account in French","14/08/2020","Very detailed chart");
load from unl/20200814-coa-FR-FRA.tmplt INSERT INTO coatempltdetl ;
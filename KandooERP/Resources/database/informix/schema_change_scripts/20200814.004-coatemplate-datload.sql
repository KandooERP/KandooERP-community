--# description: this script loads data to coatempltdetl
--# tables list: coatempltdetl
--# dependencies: 
--# author: ericv
--# date: 2020-06-24
--# Ticket #  KD-2239	

delete from coatempltdetl WHERE language_code in ("ENU","ENG") and country_code in ("IFR");
delete from coatemplthead WHERE language_code in ("ENU","ENG") and country_code in ("IFR");
INSERT INTO coatemplthead VALUES ("IFR","ENG","The I.F.R.S Chart of Account in English","14/08/2020","Very detailed chart from International Financial Report System");
load from unl/20200814-coa-IFR-ENG.tmplt INSERT INTO coatempltdetl;
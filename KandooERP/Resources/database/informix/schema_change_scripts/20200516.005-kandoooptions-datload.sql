--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: ericv
--# date: 2020-05-16
--# Ticket # : KD-2071
--# dependencies:
--# more comments:

DELETE FROM kandoooption where cmpy_code='KA' AND module_code='GW' AND feature_code='D1';
DELETE FROM kandoooption where cmpy_code='99' AND module_code='GW' AND feature_code='D1';
on exception -691 status=OKE;
INSERT INTO kandoooption values ('KA','GW','D1','Report - Multi Language Report Template (Kandooreport)', 'Y') ; 
INSERT INTO kandoooption values ('99','GW','D1','Report - Multi Language Report Template (Kandooreport)', 'Y');
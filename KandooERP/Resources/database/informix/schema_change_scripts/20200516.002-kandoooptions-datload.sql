--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: ericv
--# date: 2020-05-16
--# Ticket # : KD-2071
--# dependencies:
--# more comments:

DELETE FROM kandoooption WHERE cmpy_code = 'KA' and module_code = 'GW' and feature_code = 'D1';
on exception -691 status=OKE;
INSERT INTO kandoooption values ('KA','GW','D1','Report - Multi Language Report Template (Kandooreport)', 'N');
DELETE FROM kandoooption WHERE cmpy_code = '99' and module_code = 'GW' and feature_code = 'D1';
INSERT INTO kandoooption values ('99','GW','D1','Report - Multi Language Report Template (Kandooreport)', 'N');
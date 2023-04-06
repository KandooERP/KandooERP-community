--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: ericv
--# date: 2020-05-16
--# Ticket # : KD-2072
--# dependencies:
--# more comments:
DELETE FROM kandoooption WHERE cmpy_code = 'KA' and module_code = 'GW' and feature_code = 'D2';
on exception -691 status=OKE;
INSERT INTO kandoooption VALUES ('KA','GW','D2','Report - Show RMS Report Dialog', 'Y');
DELETE FROM kandoooption WHERE cmpy_code = '99' and module_code = 'GW' and feature_code = 'D2';
INSERT INTO kandoooption values ('99','GW','D2','Report - Show RMS Report Dialog', 'N');
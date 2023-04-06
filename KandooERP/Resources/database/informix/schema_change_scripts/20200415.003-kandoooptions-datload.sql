--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: ericv
--# date: 2020-04-15
--# Ticket # : KD-1969
--# dependencies:
--# more comments:

DELETE FROM kandoooption WHERE cmpy_code = 'KA' AND module_code = 'AR' AND feature_code = 'GI';
on exception -691 status=OKE;
INSERT INTO kandoooption values("KA","AR","GI","Enable Customer Company Groups","Y");
DELETE FROM kandoooption WHERE cmpy_code = '99' AND module_code = 'AR' AND feature_code = 'GI';
INSERT INTO kandoooption values("99","AR","GI","Enable Customer Company Groups","Y");

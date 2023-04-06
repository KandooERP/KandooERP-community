--# description: this script loads additional data to kandoooption
--# tables list: kandoooption
--# author: ericv
--# date: 2020-03-25
--# Ticket # : https://querix.atlassian.net/browse/KD-1961	
--# dependencies:
--# more comments:

INSERT INTO kandoooption values("KA","WO","TA","Separate Order Type GL-Accounts","N");
INSERT INTO kandoooption values("99","WO","TA","Separate Order Type GL-Accounts","N");
INSERT INTO kandoooption values("KA","AR","IS","Invoice Wizzard Style","N");
INSERT INTO kandoooption values("99","AR","IS","Invoice Wizzard Style","N");
INSERT INTO kandoooption values ('KA','AR','GI','Customer Groups', 'Y');
INSERT INTO kandoooption values ('99','AR','GI','Customer Groups', 'Y');
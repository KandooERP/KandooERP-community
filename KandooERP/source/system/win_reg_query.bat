
echo "Registry Information" > regrep.txt
echo "" >> regrep.txt

echo "****************************************************" >> regrep.txt
echo "*** HKEY_CURRENT_USER\Software\Querix            ***" >> regrep.txt
echo "****************************************************" >> regrep.txt

REG QUERY "HKEY_CURRENT_USER\Software\Querix" /s >> regrep.txt


echo "****************************************************" >> regrep.txt
echo "*** HKEY_CURRENT_USER\Environment                ***" >> regrep.txt
echo "****************************************************" >> regrep.txt

REG QUERY "HKEY_CURRENT_USER\Environment" /s >> regrep.txt

echo "****************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Querix           ***" >> regrep.txt
echo "****************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Querix" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Informix           ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Informix" /s >> regrep.txt


echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Google             ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Google" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows      ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Oracle            ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Oracle" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\PostgreSQL         ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\PostgreSQL" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\MySQL AB           ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\MySQL AB" /s >> regrep.txt


echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows      ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\IBM                ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\IBM" /s >> regrep.txt


echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\RegisteredApplications ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\RegisteredApplications" /s >> regrep.txt



echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer"  ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer" >> regrep.txt



echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Install Check" /s ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Install Check" /s >> regrep.txt


echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components" /s ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components" /s >> regrep.txt

echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\ODBC ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\ODBC" /s >> regrep.txt



echo "" >> regrep.txt
echo "******************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\ODBCINST.INI       ***" >> regrep.txt
echo "******************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\ODBCINST.INI" /s >> regrep.txt


echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft /s           ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft" /s >> regrep.txt


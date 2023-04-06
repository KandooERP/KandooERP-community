
echo "Registry Information" > regrep.txt
echo "" >> regrep.txt

echo "*********************************************************" >> regrep.txt
echo "*** LYCIA_DIR                                         ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

env | grep LYCIA_DIR >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** QXWEB status                                      ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

/etc/init.d/qxweb status || /etc/init.d/qx-webserver status>> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Informix                                          ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

env | grep -E "INFORMIXDIR|INFORMIXSERVER|LOGNAME|INFORMIXPASS" >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Oracle                                            ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

env | grep -E "ORACLE_HOME|TNS_ADMIN|QXTRANS" >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** ODBC                                              ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

env | grep ODBCINI >> regrep.txt
odbcinst -j >> regrep.txt
cat ${ODBCINI} >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** GCC                                               ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

which gcc >> regrep.txt
gcc --version >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** ldd --version                                     ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

ldd --version >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** JAVA                                              ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

env | grep -E "JAVA_HOME|JRE_HOME" >> regrep.txt
readlink $(readlink $(which java)) >> regrep.txt
java -version 2>> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Google Chrome                                     ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

which google-chrome >> regrep.txt
google-chrome --version >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Git                                               ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

which git >> regrep.txt
git --version >> regrep.txt

echo "*********************************************************" >> regrep.txt
echo "*** System locale                                     ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

locale >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Current User                                      ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

id >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Users                                             ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

less /etc/passwd >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Network                                           ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

ip a >> regrep.txt
ss -tulp >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** IFCONFIG ALL                                      ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

ifconfig -a >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Services                                          ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

service --status-all >> regrep.txt
systemctl -l --type service --all >> regrep.txt

echo "" >> regrep.txt
echo "*********************************************************" >> regrep.txt
echo "*** Firewall                                          ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

ufw status verbose || systemctl status firewalld || service firewalld status >> regrep.txt
iptables -L -v -n --line-numbers >> regrep.txt

echo "*********************************************************" >> regrep.txt
echo "*** Environment variables                             ***" >> regrep.txt
echo "*********************************************************" >> regrep.txt

env >> regrep.txt


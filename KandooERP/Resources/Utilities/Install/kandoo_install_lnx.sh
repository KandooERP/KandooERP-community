#!/bin/bash
# KandooERP install script for Linux
# Project: KandooERP
# Filename: kandoo_install_lnx.sh
# Created By: Alexander Chubar
# Email: a.chubar8421@gmail.com
# Creation Date: Apr 19, 2019

usage() {
    echo "Usage: sudo ./${0} [-r Lycia repository URL] [-b Lycia Version] [-d Kandoo sources install dir]"
    echo "..."
    exit 1
}

LYCIA_BUILD=latest
LYCIA_REPO_GROUP="http://lycia-repo.querix.com/querix-lycia-lnx"
LYCIA_INSTALL_DIR=/opt/Querix/Lycia
LYCIA_OWNER=informix
LYCIA_G_OWNER=informix
KANDOO_PROJECT_DIR=$(pwd)
KANDOO_PROJECT_BRANCH=development

while getopts ":b:r:d:k:o:g:l:" option
do
    case ${option} in
        r) 
            LYCIA_REPO_GROUP=${OPTARG}
        ;;
        b) 
            LYCIA_BUILD=${OPTARG}
        ;;
        d) 
            KANDOO_PROJECT_DIR=${OPTARG}
        ;;
        k)
            KANDOO_PROJECT_BRANCH=${OPTARG}
        ;;
        o)
            LYCIA_OWNER=${OPTARG}
        ;;
        g)
            LYCIA_G_OWNER=${OPTARG}
        ;;
        l)
            LYCIA_INSTALL_DIR=${OPTARG}
        ;;
        \?)
            usage
        ;;
    esac
done

#test if git and git lfs is installed
if ! command -v git >/dev/null
then
    echo "git is not installed"
    exit 1
fi
if ! command -v git-lfs >/dev/null
then
    echo "git lfs is not installed"
    exit 1
fi
#test if $KANDOO_PROJECT_DIR exists and create if no
if [ ! -d ${KANDOO_PROJECT_DIR} ]
then
    mkdir -p ${KANDOO_PROJECT_DIR}
    echo "${KANDOO_PROJECT_DIR} folder was created."
fi
# rm qpm if exists
if [ -d ${KANDOO_PROJECT_DIR}/qpm ]
then
    rm -rf ${KANDOO_PROJECT_DIR}/qpm
    echo "${KANDOO_PROJECT_DIR}/qpm was removed."
fi
# rm if KandooERP project exists
if [ -d ${KANDOO_PROJECT_DIR}/KandooERP ]
then
    rm -rf ${KANDOO_PROJECT_DIR}/KandooERP
    echo "${KANDOO_PROJECT_DIR}/KandooERP was removed."
fi
# rm if public folder exists
if [ -d ${LYCIA_INSTALL_DIR}/progs/public ]
then
    rm -rf ${LYCIA_INSTALL_DIR}/progs/public
    echo "${LYCIA_INSTALL_DIR}/progs/public was removed."
fi
# test if Lycia exists
# Lycia installed with qpm will be simply updated 

cd ${KANDOO_PROJECT_DIR}
git lfs install
git clone -b ${LYCIA_BUILD} ${LYCIA_REPO_GROUP}/qpm.git 
cd ./qpm
chmod +x qpm
./qpm install -o ${LYCIA_OWNER} -g ${LYCIA_G_OWNER} -d ${LYCIA_INSTALL_DIR} -r ${LYCIA_REPO_GROUP} -b ${LYCIA_BUILD} all
cd ${KANDOO_PROJECT_DIR}
git clone -b ${KANDOO_PROJECT_BRANCH} https://gitlab.com/Kandoo-org/KandooERP.git
git clone -b master https://gitlab.com/Kandoo-org/public.git ${LYCIA_INSTALL_DIR}/progs/public/
cp -R ${KANDOO_PROJECT_DIR}/KandooERP/KandooERP/Resources/Environment/ ${LYCIA_INSTALL_DIR}/progs/
cp ${KANDOO_PROJECT_DIR}/KandooERP/KandooERP/Resources/Environment/inet_kandoo_lnx.env ${LYCIA_INSTALL_DIR}/etc/inet.env
cp ${KANDOO_PROJECT_DIR}/KandooERP/KandooERP/Resources/Environment/public_lnx.xml ${LYCIA_INSTALL_DIR}/jetty/webapps/public.xml
chown -R ${LYCIA_OWNER}:${LYCIA_G_OWNER} ${KANDOO_PROJECT_DIR} ${LYCIA_INSTALL_DIR}/progs/public/ ${LYCIA_INSTALL_DIR}/progs/Environment ${LYCIA_INSTALL_DIR}/jetty/webapps/public.xml ${LYCIA_INSTALL_DIR}/etc/inet.env
/etc/init.d/qx-web restart || systemctl restart qx-web
echo "Finished!!!"
echo "1) run LyciaStudio - ${LYCIA_INSTALL_DIR}/lyciastudio/lyciastudio &"
echo "2) add KandooERP git repository from folder ${KANDOO_PROJECT_DIR}/KandooERP"
echo "3) import KandooERP project"

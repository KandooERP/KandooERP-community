@::!/dos/rocks
@ECHO off
PUSHD %~dp0
SETLOCAL

GOTO :init

:header
    ECHO %__NAME% v%__VERSION%
    ECHO KandooERP install script for Windows
    ECHO Project: KandooERP
    ECHO Created By: Alexander Chubar
    ECHO Email: a.chubar8421@gmail.com
    ECHO Creation Date: Apr 23, 2019
    GOTO :eof

:usage
    ECHO USAGE:
    ECHO  %__BAT_NAME% [-r Lycia repository URL] [-b Lycia Version] [-d KandooERP sources install dir] [-k KandooERP repository branch] [-l Lycia install dir]
    ECHO.
    ECHO.  /?, --help               shows this help
    ECHO.  -r, --repository URL     specifies a Lycia repository URL
    ECHO.  -b, --branch version     specifies a named parameter value
    ECHO.  -d, --destination path   specifies a named parameter value
    ECHO.  -k, --kandoo branch      specifies a named parameter value
    ECHO.  -l, --lycia path         specifies a named parameter value
    GOTO :eof

:init
    SET "__NAME=%~n0"
    SET "__VERSION=1.0"

    SET "__BAT_FILE=%~0"
    SET "__BAT_PATH=%~dp0"
    SET "__BAT_NAME=%~nx0"

    SET LYCIA_BUILD=latest
    SET LYCIA_REPO_GROUP=http://lycia-repo.querix.com/querix-lycia-nt
    SET LYCIA_INSTALL_DIR="C:\Program Files\Querix\Lycia"
    SET KANDOO_PROJECT_DIR=%cd%
    SET KANDOO_PROJECT_BRANCH=development
    SET LYCIA_DATA="C:\ProgramData\Querix\Lycia"

:parse
    if "%~1"=="" GOTO :validate

    if /i "%~1"=="/?"               call :header & call :usage "%~2" & GOTO :end
    if /i "%~1"=="-?"               call :header & call :usage "%~2" & GOTO :end
    if /i "%~1"=="--help"           call :header & call :usage "%~2" & GOTO :end

    if /i "%~1"=="-r"               set "LYCIA_REPO_GROUP=%~2"          & shift & shift & GOTO :parse
    if /i "%~1"=="--repository"     set "LYCIA_REPO_GROUP=%~2"          & shift & shift & GOTO :parse

    if /i "%~1"=="-b"               set "LYCIA_BUILD=%~2"               & shift & shift & GOTO :parse
    if /i "%~1"=="--branch"         set "LYCIA_BUILD=%~2"               & shift & shift & GOTO :parse

    if /i "%~1"=="-d"               set "KANDOO_PROJECT_DIR=%~2"        & shift & shift & GOTO :parse
    if /i "%~1"=="--destination"    set "KANDOO_PROJECT_DIR=%~2"        & shift & shift & GOTO :parse

    if /i "%~1"=="-k"               set "KANDOO_PROJECT_BRANCH=%~2"     & shift & shift & GOTO :parse
    if /i "%~1"=="--kandoo"         set "KANDOO_PROJECT_BRANCH=%~2"     & shift & shift & GOTO :parse

    if /i "%~1"=="-l"               set "LYCIA_INSTALL_DIR=%~2"         & shift & shift & GOTO :parse
    if /i "%~1"=="--lycia"          set "LYCIA_INSTALL_DIR=%~2"         & shift & shift & GOTO :parse

    SHIFT
    GOTO :parse

:validate
    WHERE git -v >nul 2>nul
    IF %ERRORLEVEL% NEQ 0 (
        ECHO git is not installed
        GOTO :end
    )
    REM WHERE git-lfs -v >nul 2>nul
    git lfs install
    IF %ERRORLEVEL% NEQ 0 (
        ECHO git LFS is not installed
        GOTO :end
    )

    IF NOT EXIST %KANDOO_PROJECT_DIR%\ (
        MKDIR %KANDOO_PROJECT_DIR%
        ECHO %KANDOO_PROJECT_DIR% folder was created.
    )
    IF EXIST %KANDOO_PROJECT_DIR%\qpm\ (
        RD /S /Q %KANDOO_PROJECT_DIR%\qpm\
        ECHO %KANDOO_PROJECT_DIR%\qpm was removed.
    )
    IF EXIST %KANDOO_PROJECT_DIR%\KandooERP (
        RD /S /Q %KANDOO_PROJECT_DIR%\KandooERP
        ECHO %KANDOO_PROJECT_DIR%\KandooERP was removed.
    )
    IF EXIST %LYCIA_DATA%\progs\public  (
        RD /S /Q %LYCIA_DATA%\progs\public
        ECHO %LYCIA_DATA%\progs\public was removed.
    )

:main

    CD /D %KANDOO_PROJECT_DIR%
    REM git lfs install
    git clone -b %LYCIA_BUILD% %LYCIA_REPO_GROUP%/qpm.git
    %KANDOO_PROJECT_DIR%\qpm\qpm.exe install -k -y -d %LYCIA_INSTALL_DIR% -r %LYCIA_REPO_GROUP% -b %LYCIA_BUILD% all
    git clone -b %KANDOO_PROJECT_BRANCH% https://gitlab.com/Kandoo-org/KandooERP.git
    git clone -b master https://gitlab.com/Kandoo-org/public.git %LYCIA_DATA%\progs\public\
    XCOPY %KANDOO_PROJECT_DIR%\KandooERP\KandooERP\Resources\Environment %LYCIA_DATA%\progs\Environment\ /S /E
    COPY %KANDOO_PROJECT_DIR%\KandooERP\KandooERP\Resources\Environment\inet_kandoo_nt.env %LYCIA_DATA%\etc\inet.env 
    COPY %KANDOO_PROJECT_DIR%\KandooERP\KandooERP\Resources\Environment\public_nt.xml %LYCIA_INSTALL_DIR%\jetty\webapps\public.xml
    NET STOP qxweb & NET START qxweb
    ECHO Finished!!!
    ECHO 1) run LyciaStudio
    ECHO 2) add KandooERP git repository from folder %KANDOO_PROJECT_DIR%\KandooERP
    ECHO 3) import KandooERP project

:end
    ENDLOCAL
    POPD
    EXIT /B

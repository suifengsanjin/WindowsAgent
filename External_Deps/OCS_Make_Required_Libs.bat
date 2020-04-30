@echo off
title OCS Inventory NG Agent for Windows - Building required libraries
echo.
echo *************************************************************************
echo *                                                                       *
echo *                 OCS Inventory NG agent for Windows                    *
echo *                                                                       *
echo *                      Building required libraries                      *
echo *                                                                       *
echo *************************************************************************
echo.

Rem ========= UPDATE CONSTANTS BELOW TO MEET YOUR CONFIGURATION NEED =========  

Rem Set path to MS Visual C++
set VC_PATH=D:\soft\\Microsoft Visual Studio 12.0\VC

Rem Set path to MS Windows SDK, needed to build cURL
set WINDOWS_SDK_PATH="C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A"

Rem Set path to Perl 5.6 or higher binary
set PERL_PATH=D:\soft\perl\perl\bin

Rem Set path to Zlib sources
set ZLIB_PATH=D:\src\ocs\WindowsAgent\External_Deps\zlib

Rem Set path to OpenSSL sources
set OPENSSL_PATH=D:\src\ocs\WindowsAgent\External_Deps\openssl

Rem Set path to cURL sources
set CURL_PATH=D:\src\ocs\WindowsAgent\External_Deps\curl

Rem Set path to tinyXML sources
SET XML_PATH=D:\src\ocs\WindowsAgent\External_Deps\tinyxml

Rem Set path to ZipArchive sources, for example
SET ZIP_PATH=D:\src\ocs\WindowsAgent\External_Deps\ZipArchive\ZipArchive

Rem Set path to Net-SNMP sources, for example
SET SNMP_PATH=D:\src\ocs\WindowsAgent\External_Deps\net-snmp-5.7.3

Rem ========= DO NOT MODIFY BELOW, UNTIL YOU KNOW WHAT YOU ARE DOING =========

Rem Ensure MS Visual C++ environnement is set
call "%VC_PATH%\VCVARSALL.BAT"
Rem Add perl to PATH
set PATH=%PATH%;%PERL_PATH%

mkdir %~dp0\Release
mkdir %~dp0\Debug
mkdir %~dp0\Include

Rem goto comment
Rem goto incFile
title OCS Inventory NG Agent for Windows - Building Zlib DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building Zlib DLL...                 *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%ZLIB_PATH%"

Rem Build Zlib using precompiled asm code for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
nmake /NOLOGO -f win32\Makefile.msc clean
nmake /NOLOGO -f win32\Makefile.msc LOC="-DASMV -DASMINF -D_BIND_TO_CURRENT_VCLIBS_VERSION" OBJA="inffas32.obj match686.obj"
if ERRORLEVEL 1 goto ERROR

Rem copy libs to use them in OCS
copy zdll.lib %~dp0
copy zlib1.dll %~dp0\Release
copy zlib1.dll %~dp0\Debug
if ERRORLEVEL 1 goto ERROR

:comment
title OCS Inventory NG Agent for Windows - Building OpenSSL DLLs...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building OpenSSL DLLs...             *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%OPENSSL_PATH%"

Rem Configure OpenSSL for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
perl.exe configure no-asm VC-WIN32 -D_BIND_TO_CURRENT_VCLIBS_VERSION -D_WINSOCK_DEPRECATED_NO_WARNINGS
if ERRORLEVEL 1 goto ERROR
Rem Prepare OpenSSL build for MS Visual C++
call ms\do_nasm.bat
if ERRORLEVEL 1 goto ERROR
Rem Clean link form previous build
nmake /NOLOGO -f ms\ntdll.mak clean
Rem Build OpenSSL
nmake /NOLOGO -f ms\ntdll.mak
if ERRORLEVEL 1 goto ERROR
Rem Test OpenSSL build
cd out32dll
call "%OPENSSL_PATH%\ms\test.bat"
if ERRORLEVEL 1 goto ERROR

Rem copy libs to use them in OCS
copy ssleay32.lib %~dp0
copy libeay32.lib %~dp0
copy libeay32.lib %CURL_PATH%\winbuild
copy ssleay32.lib %CURL_PATH%\winbuild
copy ssleay32.dll %~dp0\Release
copy libeay32.dll %~dp0\Release
copy ssleay32.dll %~dp0\Debug
copy libeay32.dll %~dp0\Debug
if ERRORLEVEL 1 goto ERROR

:curl
title OCS Inventory NG Agent for Windows - Building cURL DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Building cURL DLL...                 *
echo *                                                                       *
echo *************************************************************************
echo.
mkdir %~dp0\deps
mkdir %~dp0\deps\bin
mkdir %~dp0\deps\lib
mkdir %~dp0\deps\include
xcopy /Y %OPENSSL_PATH%\inc32\openssl %~dp0\deps\include\openssl\
cd "%CURL_PATH%"\src
Rem Disable LDAP support, not needed in OCS Inventory NG Agent
set WINDOWS_SSPI=0
cd %CURL_PATH%\winbuild
Rem Fix cURL DLL config for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
Rem perl.exe -pi.bak -e "s# /DBUILDING_LIBCURL# /DBUILDING_LIBCURL /D_BIND_TO_CURRENT_VCLIBS_VERSION#g" Makefile.vc12
Rem Build cURL dll using OpenSSL Dlls and Zlib dll
Rem nmake /NOLOGO /f Makefile.vc12 cfg=release-dll-ssl-dll-zlib-dll
nmake /f Makefile.vc mode=dll VC=12 ENABLE_SSPI=NO ENABLE_IPV6=YES WITH_SSL=dll
if ERRORLEVEL 1 goto ERROR
rmdir /S /Q %~dp0\deps
echo Building cURL DLLs Over and Copy Dll Begin...

Rem copy libs to use them in OCS
copy "%CURL_PATH%\builds\libcurl-vc12-x86-release-dll-ssl-dll-obj-lib\libcurl.lib" %~dp0
copy "%CURL_PATH%\builds\libcurl-vc12-x86-release-dll-ssl-dll-obj-lib\libcurl.dll" %~dp0\Release
copy "%CURL_PATH%\builds\libcurl-vc12-x86-release-dll-ssl-dll-obj-lib\libcurl.dll" %~dp0\Debug
if ERRORLEVEL 1 goto ERROR

echo Copy cURL DLLs Over...


title OCS Inventory NG Agent for Windows - Building Net-SNMP DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Configuring Net-SNMP DLL...          *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%SNMP_PATH%\win32"
Rem Prepare OpenSSL for Net-SNMP
SET INCLUDE=%INCLUDE%;%OPENSSL_PATH%\inc32
SET LIB=%LIB%;%OPENSSL_PATH%\out32dll
Rem Configure Net-SNMP
perl.exe Configure  --with-ssl --linktype=dynamic
if ERRORLEVEL 1 goto ERROR
cd libsnmp_dll
Rem Fix Net-SNMP DLL config for MS Visual C++ with lastest Service Pack ( -D_BIND_TO_CURRENT_VCLIBS_VERSION)
perl.exe -pi.bak -e "s# /D \"WIN32\"# /D \"WIN32\" /D_BIND_TO_CURRENT_VCLIBS_VERSION#g" Makefile
Rem Fix Net-SNMP DLL config for using OpenSSL dynamic library insteadd of static ones
perl.exe -pi.bak -e "s#libeay32MD#libeay32#g" ../net-snmp/net-snmp-config.h
Rem Build Net-SNMP dll
nmake /NOLOGO
if ERRORLEVEL 1 goto ERROR
copy "%SNMP_PATH%\win32\bin\release\netsnmp.dll" %~dp0\Release
copy "%SNMP_PATH%\win32\bin\release\netsnmp.dll" %~dp0\Debug
if ERRORLEVEL 1 goto ERROR
copy "%SNMP_PATH%\win32\lib\release\netsnmp.lib" %~dp0
if ERRORLEVEL 1 goto ERROR


title OCS Inventory NG Agent for Windows - Building ZipArchive DLL...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Configuring ZipArchive DLL...        *
echo *                                                                       *
echo *************************************************************************
echo.
cd "%ZIP_PATH%\Release Unicode STL MD DLL"
Rem copy libs to use them in OCS
copy "ZipArchive.lib" %~dp0
rem copy "ZipArchive.dll" %~dp0\Release
rem copy "ZipArchive.dll" %~dp0\Debug
if ERRORLEVEL 1 goto ERROR

:errMsg
cd %~dp0
title OCS Inventory NG Agent for Windows - Building service message file...
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Compiling service message file...    *
echo *                                                                       *
echo *************************************************************************
echo.
cd "..\Service"
mc.exe NTServiceMsg.mc
if ERRORLEVEL 1 goto ERROR

:incFile
xcopy /Y %OPENSSL_PATH%\inc32\openssl %~dp0\Include\openssl\
xcopy /Y %CURL_PATH%\include\curl %~dp0\Include\curl\
copy %ZLIB_PATH%\zlib.h %~dp0\Include\
copy %ZLIB_PATH%\zconf.h %~dp0\Include\

copy %ZIP_PATH%\*.h %~dp0\Include\*.h

cd %~dp0
title OCS Inventory NG Agent for Windows - SUCCESSFUL build of required libraries 
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : All done succesufully !              *
echo *                                                                       *
echo * Enjoy OCS Inventory NG ;-)                                            *
echo *                                                                       *
echo *************************************************************************
goto END

:ERROR
title OCS Inventory NG Agent for Windows - ERROR building required libraries  !!!!
echo.
echo *************************************************************************
echo *                                                                       *
echo * Preparing for OCS Inventory NG : Error while buiding required library *
echo *                                                                       *
echo * Please, fix problem before trying to build OCS Inventory NG !         *
echo *                                                                       *
echo * Here is some common errors:                                           *
echo * - Have you reviewed paths at the beginning of this batch file ?       *
echo * - Have you updated Visual C++ version in cURL Makefile ?              *
echo * - Have you build ZipArchive "Release Unicode STL MD DLL" ?            *
echo *                                                                       *
echo *************************************************************************

:END

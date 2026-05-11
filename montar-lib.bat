@echo off
setlocal enabledelayedexpansion

set DEST=lib
if exist %DEST% rd /s /q %DEST%
mkdir %DEST%

echo Copiando JAR principal do cssp...
copy /Y "circus.robocalc.robosim.generator.cssp\target\circus.robocalc.robosim.generator.cssp-1.0.0-SNAPSHOT.jar" %DEST%\ >nul

echo Copiando bundles OSGi do cache Tycho (p2)...
for /R "%USERPROFILE%\.m2\repository\p2\osgi\bundle" %%F in (*.jar) do (
    copy /Y "%%F" %DEST%\ >nul 2>&1
)

echo Copiando dependencias Maven (Xtext, EMF, Eclipse, etc)...
for %%D in (
    "org\eclipse\xtext"
    "org\eclipse\xtend"
    "org\eclipse\emf"
    "org\eclipse\platform"
    "org\eclipse\jdt"
    "com\google"
    "org\antlr"
    "log4j"
    "aopalliance"
    "org\ow2"
    "io\github\classgraph"
    "commons-logging"
    "commons-codec"
    "org\apache\commons"
) do (
    if exist "%USERPROFILE%\.m2\repository\%%~D" (
        for /R "%USERPROFILE%\.m2\repository\%%~D" %%F in (*.jar) do (
            copy /Y "%%F" %DEST%\ >nul 2>&1
        )
    )
)

echo.
for /F %%C in ('dir /B %DEST%\*.jar ^| find /C ".jar"') do echo Total de JARs copiados: %%C

endlocal
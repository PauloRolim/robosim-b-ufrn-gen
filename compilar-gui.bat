@echo off
set JAVAFX=C:\javafx-sdk-21\lib
set FONTE=circus.robocalc.robosim.generator.cssp\src\circus\robocalc\robosim\generator\cssp\GuiApp.java.gui
set DESTINO=lib\GuiApp-temp

if exist %DESTINO% rd /s /q %DESTINO%
mkdir %DESTINO%

echo Copiando GuiApp.java temporariamente...
copy /Y "%FONTE%" "%DESTINO%\GuiApp.java" >nul

echo Compilando GuiApp.java com JavaFX no classpath...
javac ^
  --module-path "%JAVAFX%" ^
  --add-modules javafx.controls ^
  -cp "lib\*" ^
  -d %DESTINO% ^
  -sourcepath "%DESTINO%" ^
  "%DESTINO%\GuiApp.java"

if errorlevel 1 (
    echo ERRO na compilacao
    exit /b 1
)

echo Empacotando GuiApp.class em JAR...
cd %DESTINO%
jar cf ..\GuiApp.jar circus\robocalc\robosim\generator\cssp\GuiApp.class
cd ..\..
rd /s /q %DESTINO%

echo.
echo OK - GuiApp.jar criado em lib\
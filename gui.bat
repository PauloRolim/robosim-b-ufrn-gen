@echo off
set JAVAFX=C:\javafx-sdk-21\lib

if not exist "%JAVAFX%\javafx.controls.jar" (
    echo ERRO: JavaFX nao encontrado em %JAVAFX%
    echo Edite gui.bat e ajuste a variavel JAVAFX.
    pause
    exit /b 1
)

java ^
  --module-path "%JAVAFX%" ^
  --add-modules javafx.controls ^
  --add-opens=java.base/java.lang=ALL-UNNAMED ^
  --add-opens=java.base/java.util=ALL-UNNAMED ^
  --add-opens=java.base/java.lang.reflect=ALL-UNNAMED ^
  -cp "lib\*" ^
  circus.robocalc.robosim.generator.cssp.GuiApp
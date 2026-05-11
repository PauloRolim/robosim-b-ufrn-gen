@echo off
if "%~1"=="" (
    echo Uso: traduzir.bat caminho\para\arquivo.rst [pasta-saida]
    exit /b 1
)

java ^
  --add-opens=java.base/java.lang=ALL-UNNAMED ^
  --add-opens=java.base/java.util=ALL-UNNAMED ^
  --add-opens=java.base/java.lang.reflect=ALL-UNNAMED ^
  -cp "lib\*" ^
  circus.robocalc.robosim.generator.cssp.Main ^
  "%~1" %2
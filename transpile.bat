@echo off
REM ===================================================================
REM  transpile.bat <ruta-archivo.java>
REM  Ejecuta el transpilador previamente compilado por build.bat.
REM ===================================================================

set "PROJECT_DIR=%~dp0"
set "ANTLR_VERSION=4.13.1"
set "ANTLR_JAR=%PROJECT_DIR%lib\antlr-%ANTLR_VERSION%-complete.jar"
set "OUT_DIR=%PROJECT_DIR%build\classes"

if not exist "%OUT_DIR%" (
    echo [ERROR] El proyecto no esta compilado. Ejecute primero:  build.bat
    exit /b 1
)

if not exist "%ANTLR_JAR%" (
    echo [ERROR] No se encuentra ANTLR JAR.  Ejecute primero:  build.bat
    exit /b 1
)

java -cp "%ANTLR_JAR%;%OUT_DIR%" com.inventapymes.transpiler.Main %*
exit /b %ERRORLEVEL%

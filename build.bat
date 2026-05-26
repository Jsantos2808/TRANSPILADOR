@echo off
REM ===================================================================
REM  build.bat
REM  Compila el transpilador Selenium-Java -> Cypress-JS sin requerir
REM  Maven. Descarga automaticamente la herramienta ANTLR4 si no esta
REM  disponible, genera el lexer/parser/visitor a partir de la gramatica
REM  EN EL MISMO PAQUETE que el codigo escrito a mano (asi cualquier IDE
REM  lo reconoce sin configuracion adicional) y luego compila todo en
REM  la carpeta "build/classes".
REM ===================================================================

setlocal

set "PROJECT_DIR=%~dp0"
set "ANTLR_VERSION=4.13.1"
set "ANTLR_JAR=%PROJECT_DIR%lib\antlr-%ANTLR_VERSION%-complete.jar"
set "GRAMMAR_FILE=%PROJECT_DIR%src\main\antlr4\com\inventapymes\transpiler\SeleniumJava.g4"
set "OUT_DIR=%PROJECT_DIR%build\classes"
set "SRC_DIR=%PROJECT_DIR%src\main\java"
set "ANTLR_OUT_DIR=%SRC_DIR%\com\inventapymes\transpiler"

echo ============================================================
echo  Construyendo el transpilador Selenium -^> Cypress
echo ============================================================

REM --- 1) Asegurar que tenemos el JAR completo de ANTLR4 ---
if not exist "%PROJECT_DIR%lib" mkdir "%PROJECT_DIR%lib"
if not exist "%ANTLR_JAR%" (
    echo [1/4] Descargando ANTLR %ANTLR_VERSION% ...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://www.antlr.org/download/antlr-%ANTLR_VERSION%-complete.jar' -OutFile '%ANTLR_JAR%' } catch { Write-Error $_; exit 1 }"
    if errorlevel 1 (
        echo [ERROR] No se pudo descargar ANTLR. Descarguelo manualmente desde:
        echo         https://www.antlr.org/download/antlr-%ANTLR_VERSION%-complete.jar
        echo         y coloquelo en: %ANTLR_JAR%
        exit /b 1
    )
) else (
    echo [1/4] ANTLR ya disponible: %ANTLR_JAR%
)

REM --- 2) Limpiar artefactos previos ---
echo [2/4] Limpiando artefactos previos...
if exist "%OUT_DIR%" rmdir /s /q "%OUT_DIR%"
mkdir "%OUT_DIR%"
REM Borramos solo los archivos generados por ANTLR (sin tocar los escritos a mano).
del /q "%ANTLR_OUT_DIR%\SeleniumJavaLexer.java"        2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJavaParser.java"       2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJavaVisitor.java"      2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJavaBaseVisitor.java"  2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJava.interp"           2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJava.tokens"           2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJavaLexer.interp"      2>nul
del /q "%ANTLR_OUT_DIR%\SeleniumJavaLexer.tokens"      2>nul

REM --- 3) Generar lexer/parser/visitor desde la gramatica ---
echo [3/4] Generando lexer, parser y visitor desde la gramatica...
java -jar "%ANTLR_JAR%" -Dlanguage=Java -visitor -no-listener -package com.inventapymes.transpiler -o "%ANTLR_OUT_DIR%" "%GRAMMAR_FILE%"
if errorlevel 1 (
    echo [ERROR] Fallo la generacion ANTLR4.
    exit /b 1
)

REM --- 4) Compilar todo el codigo Java ---
echo [4/4] Compilando codigo Java...
REM Generamos sources.txt con cada ruta entre comillas (para soportar
REM rutas con espacios como "Nueva carpeta") y convertimos las "\" a "/"
REM porque javac @argfile las interpreta como caracter de escape.
powershell -NoProfile -Command "$paths = @(); Get-ChildItem -Recurse -Path '%SRC_DIR%' -Filter *.java | ForEach-Object { $paths += ('\"' + ($_.FullName -replace '\\','/') + '\"') }; Set-Content -Path '%PROJECT_DIR%build\sources.txt' -Value $paths -Encoding ASCII"

javac -encoding UTF-8 -cp "%ANTLR_JAR%" -d "%OUT_DIR%" "@%PROJECT_DIR%build\sources.txt"
if errorlevel 1 (
    echo [ERROR] Fallo la compilacion Java.
    exit /b 1
)

echo.
echo ============================================================
echo  Compilacion exitosa.
echo  Ahora puede ejecutar:   transpile.bat ejemplos\LoginTest.java
echo ============================================================

endlocal

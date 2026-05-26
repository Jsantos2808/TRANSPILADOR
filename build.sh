#!/usr/bin/env bash
# ===================================================================
#  build.sh
#  Compila el transpilador Selenium-Java -> Cypress-JS sin Maven.
#  Las clases generadas por ANTLR se colocan en el mismo paquete que
#  el codigo Java escrito a mano, asi cualquier IDE las reconoce sin
#  configuracion adicional.
# ===================================================================
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANTLR_VERSION="4.13.1"
ANTLR_JAR="$PROJECT_DIR/lib/antlr-${ANTLR_VERSION}-complete.jar"
GRAMMAR_FILE="$PROJECT_DIR/src/main/antlr4/com/inventapymes/transpiler/SeleniumJava.g4"
OUT_DIR="$PROJECT_DIR/build/classes"
SRC_DIR="$PROJECT_DIR/src/main/java"
ANTLR_OUT_DIR="$SRC_DIR/com/inventapymes/transpiler"

echo "============================================================"
echo " Construyendo el transpilador Selenium -> Cypress"
echo "============================================================"

mkdir -p "$PROJECT_DIR/lib"
if [ ! -f "$ANTLR_JAR" ]; then
    echo "[1/4] Descargando ANTLR ${ANTLR_VERSION} ..."
    curl -fLo "$ANTLR_JAR" "https://www.antlr.org/download/antlr-${ANTLR_VERSION}-complete.jar"
else
    echo "[1/4] ANTLR ya disponible: $ANTLR_JAR"
fi

echo "[2/4] Limpiando artefactos previos..."
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
# Solo borramos los archivos generados por ANTLR (sin tocar los escritos a mano).
rm -f "$ANTLR_OUT_DIR"/SeleniumJavaLexer.java \
       "$ANTLR_OUT_DIR"/SeleniumJavaParser.java \
       "$ANTLR_OUT_DIR"/SeleniumJavaVisitor.java \
       "$ANTLR_OUT_DIR"/SeleniumJavaBaseVisitor.java \
       "$ANTLR_OUT_DIR"/SeleniumJava.interp \
       "$ANTLR_OUT_DIR"/SeleniumJava.tokens \
       "$ANTLR_OUT_DIR"/SeleniumJavaLexer.interp \
       "$ANTLR_OUT_DIR"/SeleniumJavaLexer.tokens

echo "[3/4] Generando lexer, parser y visitor..."
java -jar "$ANTLR_JAR" -Dlanguage=Java -visitor -no-listener \
    -package com.inventapymes.transpiler \
    -o "$ANTLR_OUT_DIR" \
    "$GRAMMAR_FILE"

echo "[4/4] Compilando codigo Java..."
find "$SRC_DIR" -name "*.java" > "$PROJECT_DIR/build/sources.txt"
javac -encoding UTF-8 -cp "$ANTLR_JAR" -d "$OUT_DIR" @"$PROJECT_DIR/build/sources.txt"

echo
echo "============================================================"
echo " Compilacion exitosa."
echo " Ejecute:   ./transpile.sh ejemplos/LoginTest.java"
echo "============================================================"

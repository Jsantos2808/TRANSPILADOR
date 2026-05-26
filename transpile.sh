#!/usr/bin/env bash
# ===================================================================
#  transpile.sh <ruta-archivo.java>
# ===================================================================
set -e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANTLR_VERSION="4.13.1"
ANTLR_JAR="$PROJECT_DIR/lib/antlr-${ANTLR_VERSION}-complete.jar"
OUT_DIR="$PROJECT_DIR/build/classes"

if [ ! -d "$OUT_DIR" ]; then
    echo "[ERROR] El proyecto no esta compilado. Ejecute primero:  ./build.sh"
    exit 1
fi

java -cp "$ANTLR_JAR:$OUT_DIR" com.inventapymes.transpiler.Main "$@"

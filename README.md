# Transpilador Selenium (Java) → Cypress (JavaScript)

Proyecto académico que aplica los fundamentos de **análisis léxico**, **análisis sintáctico** y **traducción dirigida por sintaxis** para construir un transpilador con **ANTLR4** y **Java**.

El programa lee un script de pruebas escrito en un subconjunto de **Java + Selenium WebDriver** y produce su equivalente funcional en **JavaScript + Cypress**.

---

## 1. Estructura del proyecto

```
.
├── src/main/antlr4/com/inventapymes/transpiler/
│   └── SeleniumJava.g4               <- gramática ANTLR4 (lexer + parser)
├── src/main/java/com/inventapymes/transpiler/
│   ├── Main.java                     <- Driver principal del transpilador
│   ├── SeleniumToCypressVisitor.java <- traducción dirigida por sintaxis
│   ├── SyntaxErrorListener.java      <- manejo de errores léxicos/sintácticos
│   └── (clases generadas por ANTLR a partir de SeleniumJava.g4:
│         SeleniumJavaLexer.java, SeleniumJavaParser.java,
│         SeleniumJavaVisitor.java, SeleniumJavaBaseVisitor.java)
├── ejemplos/
│   ├── LoginTest.java                <- ejemplo válido 1
│   ├── BusquedaProductoTest.java     <- ejemplo válido 2
│   ├── PruebaConError.java           <- ejemplo con error sintáctico
│   └── PruebaConErrorLexico.java     <- ejemplo con error léxico
├── lib/                              <- se descarga aquí antlr-4.13.1-complete.jar
├── build/                            <- carpeta de compilación (.class files)
├── build.bat / build.sh              <- compila el proyecto
├── transpile.bat / transpile.sh      <- ejecuta el transpilador
├── pom.xml                           <- alternativa con Maven (opcional)
└── README.md
```

> **Importante:** las clases generadas por ANTLR (`SeleniumJavaLexer`, `SeleniumJavaParser`, `SeleniumJavaVisitor`, `SeleniumJavaBaseVisitor`) se colocan **dentro del mismo paquete** que el código escrito a mano. Esto se hace adrede para que cualquier IDE (IntelliJ, Cursor, Eclipse, VS Code) las reconozca automáticamente como fuentes del proyecto, sin necesidad de marcar carpetas "generated sources". Nunca edite estos archivos manualmente: `build.bat` los regenera cada vez que se ejecuta.

---

## 2. Requisitos

- **JDK 11+** (probado con JDK 24).
- Conexión a internet la primera vez para descargar `antlr-4.13.1-complete.jar`.

> No es necesario instalar Maven ni ANTLR a mano. El script `build.bat` descarga el JAR completo de ANTLR4 automáticamente.

---

## 3. Compilación

Desde la carpeta raíz del proyecto, ejecute:

**Windows**
```cmd
build.bat
```

**Linux / macOS**
```bash
chmod +x build.sh transpile.sh
./build.sh
```

El proceso:
1. Descarga `antlr-4.13.1-complete.jar` en `lib/` (solo la primera vez).
2. Genera el **lexer**, **parser** y **visitor** a partir de `SeleniumJava.g4`.
3. Compila todo el código Java en `build/classes/`.

---

## 4. Configuración del IDE (opcional, solo si lo abre en IntelliJ / Cursor / Eclipse)

Si abre el proyecto en un IDE, este intentará compilar los `.java` por su cuenta y necesitará dos cosas:

1. **Ejecutar `build.bat` al menos una vez** para que ANTLR genere `SeleniumJavaLexer.java`, `SeleniumJavaParser.java`, `SeleniumJavaVisitor.java` y `SeleniumJavaBaseVisitor.java` dentro de `src/main/java/com/inventapymes/transpiler/`.
2. **Agregar el JAR de ANTLR al classpath del IDE** (los `import org.antlr.v4.runtime.*` necesitan resolverse):

   **IntelliJ IDEA / Cursor:**
   - `File → Project Structure → Libraries → +  →  Java`
   - Seleccione `lib/antlr-4.13.1-complete.jar` y aplíquelo al módulo principal.
   - Alternativamente: clic derecho sobre `lib/antlr-4.13.1-complete.jar` → *Add as Library...*

   **VS Code (Java Extension Pack):**
   - Edite `.vscode/settings.json` y añada:
     ```json
     { "java.project.referencedLibraries": ["lib/**/*.jar"] }
     ```

   **Eclipse:**
   - Clic derecho sobre el proyecto → *Build Path → Configure Build Path → Libraries → Classpath → Add JARs* → seleccione el JAR de `lib/`.

Después de esto haga *Build / Refresh / Sync* y los errores `cannot find symbol class SeleniumJavaParser` desaparecerán.

> **Atajo:** si tiene Maven instalado, basta con `Open as Maven Project` sobre `pom.xml`; el IDE configurará todo automáticamente (descarga ANTLR, genera fuentes y resuelve el classpath).

---

## 5. Ejecución

**Pasando el archivo como argumento:**

```cmd
transpile.bat ejemplos\LoginTest.java
```

```bash
./transpile.sh ejemplos/LoginTest.java
```

**Sin argumentos (el programa solicita la ruta por consola):**

```cmd
transpile.bat
```

Por cada archivo `Foo.java` válido se genera **`Foo.cy.js`** en el mismo directorio.

---

## 6. Tabla de mapeo soportada

| Java / Selenium WebDriver                                       | JavaScript / Cypress                            |
| --------------------------------------------------------------- | ----------------------------------------------- |
| `public class Foo { ... }`                                      | `describe('Foo', () => { ... });`               |
| `@Test public void bar() { ... }`                               | `it('bar', () => { ... });`                     |
| `driver.get("URL");`                                            | `cy.visit('URL');`                              |
| `driver.findElement(By.id("x")).click();`                       | `cy.get('#x').click();`                         |
| `driver.findElement(By.cssSelector(".y")).click();`             | `cy.get('.y').click();`                         |
| `driver.findElement(By.id("u")).sendKeys("t");`                 | `cy.get('#u').type('t');`                       |
| `driver.findElement(By.cssSelector(".u")).sendKeys("t");`       | `cy.get('.u').type('t');`                       |
| `Assert.assertEquals(esperado, actual);`                        | `expect(actual).to.equal(esperado);`            |

> **Notas:**
> - Las sentencias `import ...;` y la declaración opcional `WebDriver driver;` se reconocen pero no se traducen al archivo de salida.
> - Cualquier sentencia distinta a las anteriores producirá un **error sintáctico**.

---

## 7. Manejo de errores

Si el archivo de entrada contiene sintaxis no soportada, el transpilador **detiene la traducción** y reporta cada problema indicando **línea** y **columna**:

```
>>> TRADUCCION DETENIDA: se detectaron errores <<<

[ERROR SINTACTICO] Linea 9, Columna 9 -> missing ';' at 'driver'
[ERROR SINTACTICO] Linea 9, Columna 36 -> mismatched input '(' expecting 'driver'
[ERROR SINTACTICO] Linea 11, Columna 1 -> extraneous input '}' expecting <EOF>

Total de errores: 3
```

Los errores se clasifican en:
- **`[ERROR LEXICO]`** – caracteres no reconocidos por el lexer.
- **`[ERROR SINTACTICO]`** – tokens en posiciones no válidas según la gramática.

Cuando hay errores el programa termina con código de salida `1`.

---

## 8. Ejemplos incluidos

### Entrada válida (`ejemplos/LoginTest.java`)

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.junit.Test;
import org.junit.Assert;

public class LoginTest {

    WebDriver driver;

    @Test
    public void deberiaIniciarSesionConCredencialesValidas() {
        driver.get("https://app.inventapymes.com/login");
        driver.findElement(By.id("usuario")).sendKeys("admin");
        driver.findElement(By.id("password")).sendKeys("1234");
        driver.findElement(By.id("botonLogin")).click();
        Assert.assertEquals("Bienvenido", tituloPantalla);
    }

    @Test
    public void deberiaCerrarSesion() {
        driver.get("https://app.inventapymes.com/dashboard");
        driver.findElement(By.cssSelector(".logout-btn")).click();
        Assert.assertEquals("Iniciar Sesion", tituloPantalla);
    }
}
```

### Salida generada (`ejemplos/LoginTest.cy.js`)

```javascript
describe('LoginTest', () => {
  it('deberiaIniciarSesionConCredencialesValidas', () => {
    cy.visit('https://app.inventapymes.com/login');
    cy.get('#usuario').type('admin');
    cy.get('#password').type('1234');
    cy.get('#botonLogin').click();
    expect(tituloPantalla).to.equal('Bienvenido');
  });

  it('deberiaCerrarSesion', () => {
    cy.visit('https://app.inventapymes.com/dashboard');
    cy.get('.logout-btn').click();
    expect(tituloPantalla).to.equal('Iniciar Sesion');
  });
});
```

---

## 9. Arquitectura interna

1. **Análisis léxico** – `SeleniumJavaLexer` (generado por ANTLR4) divide el código fuente en *tokens* (`DRIVER`, `DOT`, `STRING_LITERAL`, etc.).
2. **Análisis sintáctico** – `SeleniumJavaParser` (generado por ANTLR4) construye un árbol sintáctico a partir de los tokens, aplicando las reglas definidas en `SeleniumJava.g4`.
3. **Manejo de errores** – `SyntaxErrorListener` reemplaza el listener por defecto de ANTLR para capturar y formatear los errores con su línea/columna.
4. **Traducción dirigida por sintaxis** – `SeleniumToCypressVisitor` recorre el árbol y, para cada nodo, emite el código Cypress equivalente.
5. **Generación de salida** – `Main` ensambla la cadena resultante y la escribe en un archivo `*.cy.js`.

---

## 10. Compilación opcional con Maven

Si tiene Maven instalado puede usar el `pom.xml` incluido:

```bash
mvn clean package
java -jar target/transpiler.jar ejemplos/LoginTest.java
```

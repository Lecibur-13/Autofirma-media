# Autofirma - Recursos

Este repositorio contiene los recursos necesarios para el Fork [Autofirma](https://github.com/Lecibur-13/firma), una herramienta de firma electrónica en entornos de escritorio y dispositivos móviles, que funciona en forma de Applet de Java integrado en una página Web mediante JavaScript, como aplicación de escritorio, o como aplicación móvil, dependiendo del entorno del usuario.

## 📦 Archivos del Repositorio

### `bin.zip`
Contiene los archivos necesarios de **OpenSSL** para poder convertir la e.Firma en formato PFX. Estos binarios son esenciales para las operaciones de conversión de certificados.

### `Cert_Prod.zip`
Contiene los **certificados raíz del SAT** (Servicio de Administración Tributaria). Estos certificados son necesarios para validar la cadena de confianza de los certificados e.Firma emitidos por el SAT.

### `media.zip`
Contiene la estructura de archivos necesarios para:
- Almacenar la **Autoridad Certificadora (CA.pem)**
- El **logo** para personalizar la aplicación Autofirma

## 🔧 Scripts Disponibles

### `01_create_ca.sh`
Script para crear la **Autoridad Certificadora (CA.pem)** a partir de los certificados raíz encontrados en `Cert_Prod.zip`.

**Funcionalidad:**
- Convierte todos los certificados `.cer` y `.crt` a formato PEM
- Crea la carpeta `certificados/` con los certificados individuales convertidos
- Genera el archivo `CA.pem` con la cadena completa de certificados SAT

**Uso:**
```bash
./01_create_ca.sh
```

**Requisitos:**
- Tener los certificados `.cer` o `.crt` del SAT extraídos en el directorio actual
- OpenSSL instalado en el sistema

### `02_validate_certificate.sh`
Script para validar la **Autoridad Certificadora (CA.pem)** usando un certificado `.cer` de alguna e.Firma.

**Funcionalidad:**
- Busca automáticamente el archivo `efirma.cer` o `efirma.crt` en el directorio actual
- Convierte el certificado e.Firma a formato PEM
- Identifica el certificado emisor directo (CA individual)
- Valida el certificado contra la cadena completa `CA.pem`
- Muestra información detallada de la validación y el certificado emisor identificado

**Uso:**
```bash
./02_validate_certificate.sh [ruta_al_efirma.cer]
```

**Requisitos:**
- Tener el archivo `CA.pem` generado previamente (ejecutar primero `01_create_ca.sh`)
- Tener un certificado e.Firma (`.cer` o `.crt`) para validar
- OpenSSL instalado en el sistema

## 📋 Orden de Ejecución

1. **Extraer los certificados del SAT:**
   ```bash
   unzip Cert_Prod.zip
   ```

2. **Crear la cadena de certificados:**
   ```bash
   ./01_create_ca.sh
   ```
   Esto generará el archivo `CA.pem` necesario para las validaciones.

3. **Validar un certificado e.Firma:**
   ```bash
   ./02_validate_certificate.sh
   ```
   O especificando la ruta del certificado:
   ```bash
   ./02_validate_certificate.sh mi_certificado.cer
   ```

## 📁 Estructura de Archivos Generados

Después de ejecutar los scripts, se generará la siguiente estructura:

```
.
├── CA.pem                          # Cadena completa de certificados SAT
├── efirma.pem                      # Certificado e.Firma convertido a PEM
├── certificados/                   # Carpeta con certificados individuales
│   ├── certificado1.pem
│   ├── certificado2.pem
│   └── ...
├── 01_create_ca.sh
├── 02_validate_certificate.sh
└── README.md
```

## 🔗 Enlaces Relacionados

- [Repositorio de Autofirma](https://github.com/Lecibur-13/firma)

## 📝 Notas

- Los scripts están diseñados para funcionar en sistemas Linux/Unix con bash
- Se requiere OpenSSL instalado en el sistema
- Los scripts incluyen pausas para evitar que la terminal se cierre automáticamente
- Los mensajes de error incluyen instrucciones claras sobre cómo proceder

## ⚙️ Requisitos del Sistema

- Bash (shell)
- OpenSSL
- Sistema operativo Linux/Unix (o Git Bash en Windows)

## 📄 Licencia

Este repositorio contiene recursos para el proyecto Autofirma. Consulta la licencia del proyecto principal para más información.

#!/bin/bash
# ============================================================================
# Script: 01_crear_cadena_ca.sh
# Descripción: Crea la cadena completa de certificados SAT (CA.pem)
#              Convierte todos los certificados .cer y .crt a formato PEM
#              y genera un archivo CA.pem con todos los certificados
# ============================================================================
# Autor: [Tu Nombre]
# Fecha: $(date +%Y-%m-%d)
# Versión: 1.0
# ============================================================================

# Colores para mejor visualización
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔗 CREANDO CADENA COMPLETA DE CERTIFICADOS SAT${NC}"
echo "=================================================="
echo ""

# Crear carpeta para certificados PEM
CERT_DIR="certificados"
if [ ! -d "$CERT_DIR" ]; then
    mkdir -p "$CERT_DIR"
    echo -e "${GREEN}📁 Carpeta '$CERT_DIR' creada${NC}"
else
    echo -e "${BLUE}📁 Usando carpeta existente '$CERT_DIR'${NC}"
fi
echo ""

# Función para convertir certificado probando diferentes formatos
convertir_certificado() {
    local cert_file="$1"
    local output_file="$2"
    local cert_name=$(basename "$cert_file")
    local error_msg=""
    
    # Verificar que el archivo existe y no está vacío
    if [ ! -f "$cert_file" ]; then
        echo -e "${RED}❌ Archivo no encontrado: $cert_name${NC}"
        return 1
    fi
    
    if [ ! -s "$cert_file" ]; then
        echo -e "${RED}❌ Archivo vacío: $cert_name${NC}"
        return 1
    fi
    
    # Intentar primero como DER
    error_msg=$(openssl x509 -inform DER -in "$cert_file" -outform PEM -out "$output_file" 2>&1)
    if [ $? -eq 0 ]; then
        # Verificar que el archivo PEM se creó correctamente
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            return 0
        fi
    fi
    
    # Si falló, intentar como PEM
    error_msg=$(openssl x509 -inform PEM -in "$cert_file" -outform PEM -out "$output_file" 2>&1)
    if [ $? -eq 0 ]; then
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            return 0
        fi
    fi
    
    # Si ambos fallaron, mostrar el error
    echo -e "${RED}❌ Error convirtiendo $cert_name${NC}"
    echo -e "${YELLOW}   Último error: $(echo "$error_msg" | head -1)${NC}"
    
    # Intentar verificar qué tipo de archivo es
    file_type=$(file "$cert_file" 2>/dev/null || echo "desconocido")
    echo -e "${YELLOW}   Tipo de archivo: $file_type${NC}"
    
    return 1
}

# Convertir TODOS los certificados SAT a PEM (.cer y .crt) en carpeta certificados
echo -e "${BLUE}🔄 Convirtiendo certificados SAT a PEM en carpeta '$CERT_DIR'...${NC}"
CONVERTED=0
ERRORS=0

# Convertir .cer
for cert in *.cer; do
    if [ -f "$cert" ]; then
        if convertir_certificado "$cert" "$CERT_DIR/${cert%.cer}.pem"; then
            echo -e "${GREEN}✅ Convertido: $cert${NC}"
            ((CONVERTED++))
        else
            ((ERRORS++))
        fi
    fi
done

# Convertir .crt
for cert in *.crt; do
    if [ -f "$cert" ]; then
        if convertir_certificado "$cert" "$CERT_DIR/${cert%.crt}.pem"; then
            echo -e "${GREEN}✅ Convertido: $cert${NC}"
            ((CONVERTED++))
        else
            ((ERRORS++))
        fi
    fi
done

echo ""
if [ $CONVERTED -gt 0 ]; then
    echo -e "${GREEN}✅ $CONVERTED certificados convertidos exitosamente a PEM en '$CERT_DIR'${NC}"
fi
if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $ERRORS certificados tuvieron errores en la conversión${NC}"
fi
echo ""

# Crear cadena completa con todos los certificados PEM de la carpeta certificados
echo -e "${BLUE}🔗 Creando cadena completa SAT (CA.pem) con todos los certificados...${NC}"
if [ -f CA.pem ]; then
    rm CA.pem
    echo -e "${YELLOW}⚠️  Archivo CA.pem anterior eliminado${NC}"
fi

# Agregar todos los .pem de la carpeta certificados
for pem in "$CERT_DIR"/*.pem; do
    if [ -f "$pem" ]; then
        cat "$pem" >> CA.pem 2>/dev/null
    fi
done

if [ -f CA.pem ]; then
    CERT_COUNT=$(grep -c "BEGIN CERTIFICATE" CA.pem 2>/dev/null || echo "0")
    if [ "$CERT_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ CA.pem creada exitosamente con $CERT_COUNT certificados${NC}"
        echo -e "${GREEN}   Archivo: CA.pem${NC}"
    else
        echo -e "${RED}❌ Error: CA.pem creada pero no contiene certificados válidos${NC}"
        rm CA.pem
        exit 1
    fi
else
    echo -e "${RED}❌ Error: No se pudo crear CA.pem${NC}"
    echo -e "${YELLOW}   Verifica que existan certificados .cer o .crt en el directorio actual${NC}"
    exit 1
fi

echo ""
echo "=================================================="
echo -e "${BLUE}📊 RESUMEN:${NC}"
echo -e "   Certificados convertidos: ${GREEN}$CONVERTED${NC}"
if [ $ERRORS -gt 0 ]; then
    echo -e "   Errores en conversión: ${YELLOW}$ERRORS${NC}"
fi
echo -e "   Certificados en CA.pem: ${GREEN}$CERT_COUNT${NC}"
echo -e "   Archivo generado: ${GREEN}CA.pem${NC}"
echo -e "   Certificados individuales: ${GREEN}$CERT_DIR/*.pem${NC}"
echo "=================================================="
echo ""

# Esperar entrada del usuario para evitar que cierre la terminal
echo "Presiona ENTER para salir..."
read

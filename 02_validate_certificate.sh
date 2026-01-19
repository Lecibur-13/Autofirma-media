#!/bin/bash
# ============================================================================
# Script: 02_validate_certificate.sh
# Descripción: Valida un certificado e.firma contra la cadena CA.pem
#              Identifica el certificado emisor directo (CA individual)
#              Muestra información detallada de la validación
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

# Buscar archivo e.firma automáticamente
EFIRMA=""
if [ -f "efirma.cer" ]; then
    EFIRMA="efirma.cer"
elif [ -f "efirma.crt" ]; then
    EFIRMA="efirma.crt"
elif [ -n "$1" ]; then
    EFIRMA="$1"
else
    echo -e "${RED}❌ Error: No se encontró efirma.cer o efirma.crt${NC}"
    echo "Uso: $0 [ruta_al_efirma.cer]"
    echo ""
    echo "Presiona ENTER para salir..."
    read
    exit 1
fi

if [ ! -f "$EFIRMA" ]; then
    echo -e "${RED}❌ Error: Archivo e.firma no encontrado: $EFIRMA${NC}"
    echo ""
    echo "Presiona ENTER para salir..."
    read
    exit 1
fi

# Verificar que existe CA.pem
if [ ! -f "CA.pem" ]; then
    echo -e "${RED}❌ Error: No se encontró CA.pem${NC}"
    echo -e "${YELLOW}   Ejecuta primero el script 01_create_ca_chain.sh${NC}"
    echo ""
    echo "Presiona ENTER para salir..."
    read
    exit 1
fi

echo -e "${BLUE}🔍 VALIDANDO CERTIFICADO e.firma: $EFIRMA${NC}"
echo "=================================================="
echo ""

# Crear carpeta para certificados PEM si no existe
CERT_DIR="certificados"
if [ ! -d "$CERT_DIR" ]; then
    mkdir -p "$CERT_DIR"
fi

# 1. Información básica del efirma
echo -e "${BLUE}📋 INFORMACIÓN e.firma:${NC}"
if [[ "$EFIRMA" == *.cer ]]; then
    FORMAT="DER"
else
    FORMAT="PEM"
fi

openssl x509 -inform "$FORMAT" -in "$EFIRMA" -noout -subject -issuer -serial -dates 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error obteniendo información de e.firma${NC}"
    echo ""
    echo "Presiona ENTER para salir..."
    read
    exit 1
fi

ISSUER_HASH=$(openssl x509 -inform "$FORMAT" -in "$EFIRMA" -noout -issuer_hash 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error obteniendo issuer_hash de e.firma${NC}"
    echo ""
    echo "Presiona ENTER para salir..."
    read
    exit 1
fi
echo -e "${GREEN}🔑 Issuer Hash: $ISSUER_HASH${NC}"
echo ""

# 2. Convertir efirma a PEM
echo -e "${BLUE}🔄 Convirtiendo e.firma a PEM...${NC}"
if [[ "$EFIRMA" == *.cer ]]; then
    openssl x509 -inform DER -in "$EFIRMA" -outform PEM -out efirma.pem 2>/dev/null
else
    openssl x509 -inform PEM -in "$EFIRMA" -outform PEM -out efirma.pem 2>/dev/null
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ efirma.pem creado${NC}"
else
    echo -e "${RED}❌ Error convirtiendo e.firma a PEM${NC}"
    echo ""
    echo "Presiona ENTER para salir..."
    read
    exit 1
fi
echo ""

# 3. Identificar CA directa comparando issuer y subject
echo -e "${BLUE}🎯 IDENTIFICANDO CERTIFICADO EMISOR DIRECTO (CA INDIVIDUAL):${NC}"
EFIRMA_ISSUER=$(openssl x509 -inform "$FORMAT" -in "$EFIRMA" -noout -issuer 2>/dev/null | sed 's/issuer=//')
CA_DIRECTA=""
CA_DIRECTA_NAME=""
CA_DIRECTA_ORIGINAL=""

# Buscar en .cer
for cert in *.cer; do
    if [ -f "$cert" ] && [ "$cert" != "$EFIRMA" ]; then
        CERT_SUBJECT=$(openssl x509 -inform DER -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
        if [ "$CERT_SUBJECT" = "$EFIRMA_ISSUER" ]; then
            CA_DIRECTA="$CERT_DIR/${cert%.cer}.pem"
            CA_DIRECTA_NAME="$cert"
            CA_DIRECTA_ORIGINAL="$cert"
            echo -e "${GREEN}✅ CERTIFICADO EMISOR DIRECTO ENCONTRADO: $cert${NC}"
            echo -e "   Subject: $CERT_SUBJECT"
            break
        fi
    fi
done

# Si no se encontró, buscar en .crt
if [ -z "$CA_DIRECTA" ]; then
    for cert in *.crt; do
        if [ -f "$cert" ] && [ "$cert" != "$EFIRMA" ]; then
            CERT_SUBJECT=$(openssl x509 -inform DER -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
            if [ $? -ne 0 ]; then
                CERT_SUBJECT=$(openssl x509 -inform PEM -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
            fi
            if [ "$CERT_SUBJECT" = "$EFIRMA_ISSUER" ]; then
                CA_DIRECTA="$CERT_DIR/${cert%.crt}.pem"
                CA_DIRECTA_NAME="$cert"
                CA_DIRECTA_ORIGINAL="$cert"
                echo -e "${GREEN}✅ CERTIFICADO EMISOR DIRECTO ENCONTRADO: $cert${NC}"
                echo -e "   Subject: $CERT_SUBJECT"
                break
            fi
        fi
    done
fi

# También buscar por hash como respaldo
if [ -z "$CA_DIRECTA" ]; then
    for cert in *.cer *.crt; do
        if [ -f "$cert" ] && [ "$cert" != "$EFIRMA" ]; then
            if [[ "$cert" == *.cer ]]; then
                SUBJECT_HASH=$(openssl x509 -inform DER -in "$cert" -noout -subject_hash 2>/dev/null)
            else
                SUBJECT_HASH=$(openssl x509 -inform DER -in "$cert" -noout -subject_hash 2>/dev/null)
                if [ $? -ne 0 ]; then
                    SUBJECT_HASH=$(openssl x509 -inform PEM -in "$cert" -noout -subject_hash 2>/dev/null)
                fi
            fi
            if [ "$SUBJECT_HASH" = "$ISSUER_HASH" ]; then
                if [[ "$cert" == *.cer ]]; then
                    CA_DIRECTA="$CERT_DIR/${cert%.cer}.pem"
                else
                    CA_DIRECTA="$CERT_DIR/${cert%.crt}.pem"
                fi
                CA_DIRECTA_NAME="$cert"
                CA_DIRECTA_ORIGINAL="$cert"
                echo -e "${GREEN}✅ CERTIFICADO EMISOR DIRECTO ENCONTRADO (por hash): $cert (hash: $SUBJECT_HASH)${NC}"
                break
            fi
        fi
    done
fi

if [ -z "$CA_DIRECTA" ]; then
    echo -e "${YELLOW}⚠️  No se encontró certificado emisor directo${NC}"
    echo -e "   Issuer del e.firma: $EFIRMA_ISSUER"
fi
echo ""

# 4. Verificar contra CA.pem (cadena completa)
echo -e "${BLUE}🔍 VERIFICANDO con cadena completa (CA.pem):${NC}"
RESULT=$(openssl verify -CAfile CA.pem -show_chain efirma.pem 2>&1)
if echo "$RESULT" | grep -q "OK"; then
    echo -e "${GREEN}✅ ¡VERIFICACIÓN EXITOSA! e.firma es VÁLIDA${NC}"
    echo ""
    echo -e "${BLUE}📋 CADENA DE CERTIFICADOS QUE VALIDA:${NC}"
    
    # Extraer la cadena mostrada por openssl
    CHAIN_INFO=$(echo "$RESULT" | grep -A 100 "Chain:" | head -20)
    echo "$CHAIN_INFO"
    echo ""
    
    # Mostrar el certificado emisor directo de forma destacada
    if [ -n "$CA_DIRECTA_NAME" ]; then
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}🎯 CERTIFICADO EMISOR DIRECTO (CA INDIVIDUAL) IDENTIFICADO:${NC}"
        echo -e "${GREEN}   Archivo original: $CA_DIRECTA_ORIGINAL${NC}"
        echo -e "${GREEN}   Ubicación PEM: $CERT_DIR/${CA_DIRECTA_NAME%.*}.pem${NC}"
        echo ""
        if [ -f "$CA_DIRECTA" ]; then
            echo -e "${BLUE}   Información del certificado emisor:${NC}"
            openssl x509 -in "$CA_DIRECTA" -noout -subject -issuer -dates 2>/dev/null | sed 's/^/   /'
        fi
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    fi
else
    echo -e "${RED}❌ Falló verificación: $RESULT${NC}"
fi
echo ""

# 5. Verificar contra certificado individual (si se encontró)
if [ -n "$CA_DIRECTA" ] && [ -f "$CA_DIRECTA" ]; then
    echo -e "${BLUE}🔍 VERIFICANDO contra certificado emisor directo individual: $CA_DIRECTA_NAME${NC}"
    RESULT_INDIVIDUAL=$(openssl verify -CAfile "$CA_DIRECTA" efirma.pem 2>&1)
    if echo "$RESULT_INDIVIDUAL" | grep -q "OK"; then
        echo -e "${GREEN}✅ VERIFICACIÓN EXITOSA con certificado individual: $CA_DIRECTA_NAME${NC}"
        echo -e "${GREEN}   Resultado: $RESULT_INDIVIDUAL${NC}"
    else
        echo -e "${YELLOW}⚠️  Certificado individual encontrado pero necesita cadena completa${NC}"
        echo -e "   Error: $(echo "$RESULT_INDIVIDUAL" | grep -v "efirma.pem")"
    fi
    echo ""
fi

# 6. Verificar contra cada certificado individual (solo informativo)
echo -e "${BLUE}🔍 VERIFICANDO contra cada certificado individual:${NC}"
echo -e "${YELLOW}(Nota: La mayoría fallará porque necesitan cadena completa)${NC}"
VALIDOS=0
TOTAL=0

# Verificar contra todos los .pem de la carpeta certificados
for cert_pem in "$CERT_DIR"/*.pem; do
    if [ -f "$cert_pem" ]; then
        ((TOTAL++))
        RESULT=$(openssl verify -CAfile "$cert_pem" efirma.pem 2>&1)
        if echo "$RESULT" | grep -q "OK"; then
            echo -e "${GREEN}✅ OK con: $(basename "$cert_pem")${NC}"
            ((VALIDOS++))
        fi
    fi
done

echo ""
echo "=================================================="
echo -e "${BLUE}📊 RESUMEN FINAL:${NC}"
RESULT_FINAL=$(openssl verify -CAfile CA.pem efirma.pem 2>&1)
if echo "$RESULT_FINAL" | grep -q "OK"; then
    echo -e "${GREEN}✅ e.firma es VÁLIDA con la cadena completa CA.pem${NC}"
    if [ -n "$CA_DIRECTA_NAME" ]; then
        echo -e "${GREEN}🎯 Certificado emisor directo identificado: $CA_DIRECTA_ORIGINAL${NC}"
        echo -e "${GREEN}   Ubicado en: $CERT_DIR/${CA_DIRECTA_NAME%.*}.pem${NC}"
    fi
else
    echo -e "${RED}❌ e.firma NO es válida${NC}"
fi
echo -e "   Certificados individuales probados: $TOTAL"
echo -e "   Certificados que validan solos: ${GREEN}$VALIDOS${NC}"
echo ""
echo -e "${BLUE}📁 ARCHIVOS UTILIZADOS:${NC}"
echo -e "   📄 efirma.pem (certificado convertido)"
echo -e "   📄 CA.pem (cadena completa de certificados)"
if [ -n "$CA_DIRECTA_NAME" ]; then
    echo -e "   📄 $CERT_DIR/${CA_DIRECTA_NAME%.*}.pem (certificado emisor directo)"
fi
echo "=================================================="
echo ""

# Esperar entrada del usuario para evitar que cierre la terminal
echo "Presiona ENTER para salir..."
read

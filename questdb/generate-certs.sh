#!/bin/bash
set -e

# Default values
CERT_DIR="./certs"
DAYS_VALID=365
COUNTRY="US"
STATE="State"
LOCALITY="City"
ORGANIZATION="MyOrganization"
COMMON_NAME="localhost"

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --dir DIR          Certificate directory (default: ./certs)"
    echo "  -v, --valid DAYS       Days until expiration (default: 365)"
    echo "  -c, --country CODE     2-letter country code (default: US)"
    echo "  -s, --state STATE      State name (default: State)"
    echo "  -l, --locality CITY    City name (default: City)"
    echo "  -o, --org NAME         Organization name (default: MyOrganization)"
    echo "  -n, --name HOSTNAME    Common Name/hostname (default: localhost)"
    echo "  -h, --help            Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir) CERT_DIR="$2"; shift 2 ;;
        -v|--valid) DAYS_VALID="$2"; shift 2 ;;
        -c|--country) COUNTRY="$2"; shift 2 ;;
        -s|--state) STATE="$2"; shift 2 ;;
        -l|--locality) LOCALITY="$2"; shift 2 ;;
        -o|--org) ORGANIZATION="$2"; shift 2 ;;
        -n|--name) COMMON_NAME="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Create directory
mkdir -p $CERT_DIR

# Generate self-signed certificate and private key
openssl req -x509 -nodes -days $DAYS_VALID \
    -newkey rsa:2048 \
    -keyout $CERT_DIR/key.pem \
    -out $CERT_DIR/cert.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/CN=$COMMON_NAME"

# Set proper permissions for Envoy user (101)
chmod 644 $CERT_DIR/cert.pem
chmod 644 $CERT_DIR/key.pem

# Verify the certificate
echo "Verifying certificate..."
openssl x509 -in $CERT_DIR/cert.pem -text -noout | grep -E "Subject:|Issuer:|Not|DNS:"

echo -e "\nCertificates generated successfully in $CERT_DIR:"
ls -l $CERT_DIR

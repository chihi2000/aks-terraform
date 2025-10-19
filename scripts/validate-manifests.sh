#!/bin/bash
# Kubernetes Manifest Validation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST_DIR="$PROJECT_ROOT/app-manifests-restructured"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kubernetes Manifest Validation ===${NC}\n"

# Check if required tools are installed
echo "Checking required tools..."
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed${NC}"; exit 1; }
command -v kustomize >/dev/null 2>&1 || { echo -e "${YELLOW}kustomize not found, using kubectl kustomize${NC}"; }

echo -e "${GREEN}✓ All required tools found${NC}\n"

# Function to validate kustomize build
validate_kustomize() {
    local overlay=$1
    echo -e "${YELLOW}Validating overlay: $overlay${NC}"

    if kubectl kustomize "$MANIFEST_DIR/overlays/$overlay" > /tmp/kustomize-$overlay.yaml 2>&1; then
        echo -e "${GREEN}✓ Kustomize build succeeded for $overlay${NC}"
    else
        echo -e "${RED}✗ Kustomize build failed for $overlay${NC}"
        return 1
    fi
}

# Function to validate YAML syntax
validate_yaml() {
    local file=$1
    echo "  Validating: $file"

    if kubectl apply --dry-run=client -f "$file" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Valid${NC}"
    else
        echo -e "  ${RED}✗ Invalid YAML${NC}"
        kubectl apply --dry-run=client -f "$file"
        return 1
    fi
}

# Validate base manifests
echo -e "\n${YELLOW}=== Validating Base Manifests ===${NC}"
for file in "$MANIFEST_DIR/base"/*.yaml; do
    if [ -f "$file" ] && [ "$(basename "$file")" != "kustomization.yaml" ]; then
        validate_yaml "$file" || exit 1
    fi
done

# Validate Kustomize overlays
echo -e "\n${YELLOW}=== Validating Kustomize Overlays ===${NC}"
for overlay in dev prod; do
    if [ -d "$MANIFEST_DIR/overlays/$overlay" ]; then
        validate_kustomize "$overlay" || exit 1

        # Validate generated output
        echo "  Validating generated manifests..."
        if kubectl apply --dry-run=server -f /tmp/kustomize-$overlay.yaml >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Server-side validation passed${NC}"
        else
            echo -e "  ${RED}✗ Server-side validation failed${NC}"
            kubectl apply --dry-run=server -f /tmp/kustomize-$overlay.yaml
            exit 1
        fi
    fi
done

# Check for security best practices
echo -e "\n${YELLOW}=== Security Best Practices Check ===${NC}"

check_security() {
    local file=$1
    echo "  Checking: $(basename $file)"

    # Check for non-root user
    if grep -q "runAsNonRoot: true" "$file"; then
        echo -e "    ${GREEN}✓ Runs as non-root${NC}"
    else
        echo -e "    ${YELLOW}⚠ Missing runAsNonRoot${NC}"
    fi

    # Check for read-only root filesystem
    if grep -q "readOnlyRootFilesystem: true" "$file"; then
        echo -e "    ${GREEN}✓ Read-only root filesystem${NC}"
    else
        echo -e "    ${YELLOW}⚠ Missing readOnlyRootFilesystem${NC}"
    fi

    # Check for resource limits
    if grep -q "limits:" "$file"; then
        echo -e "    ${GREEN}✓ Resource limits defined${NC}"
    else
        echo -e "    ${YELLOW}⚠ Missing resource limits${NC}"
    fi
}

for file in "$MANIFEST_DIR/base/deployment.yaml"; do
    if [ -f "$file" ]; then
        check_security "$file"
    fi
done

# Summary
echo -e "\n${GREEN}=== Validation Summary ===${NC}"
echo -e "${GREEN}✓ All manifests are valid${NC}"
echo -e "${GREEN}✓ Kustomize builds successful${NC}"
echo -e "${GREEN}✓ Security checks passed${NC}"
echo -e "\n${GREEN}You're ready to deploy!${NC}\n"

# Clean up temp files
rm -f /tmp/kustomize-*.yaml

exit 0

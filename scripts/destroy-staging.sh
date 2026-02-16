#!/usr/bin/env bash
# =============================================================================
# Destroy the staging EC2 instance (and related Terraform-managed resources)
# Usage:  ./scripts/destroy-staging.sh          — interactive confirmation
#         ./scripts/destroy-staging.sh --force   — skip confirmation
# =============================================================================
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
TF_DIR="$(cd "$(dirname "$0")/../infrastructure/terraform" && pwd)"

# ── Colours ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# ── Pre-flight checks ───────────────────────────────────────────────────
if ! command -v terraform &>/dev/null; then
    echo -e "${RED}✗ terraform not found. Install it first.${NC}"; exit 1
fi

if ! command -v aws &>/dev/null; then
    echo -e "${RED}✗ aws CLI not found. Install it first.${NC}"; exit 1
fi

# ── Show what will be destroyed ──────────────────────────────────────────
echo -e "${YELLOW}⚠  Region : ${REGION}${NC}"
echo -e "${YELLOW}⚠  TF dir : ${TF_DIR}${NC}"

cd "$TF_DIR"

# Make sure state is initialised
terraform init -input=false -backend=true >/dev/null 2>&1 || true

# Try to show instance info before destroying
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "unknown")
PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "unknown")

echo ""
echo -e "${RED}┌──────────────────────────────────────────────┐${NC}"
echo -e "${RED}│  YOU ARE ABOUT TO DESTROY:                   │${NC}"
echo -e "${RED}│  Instance : ${INSTANCE_ID}              │${NC}"
echo -e "${RED}│  IP       : ${PUBLIC_IP}                     │${NC}"
echo -e "${RED}└──────────────────────────────────────────────┘${NC}"
echo ""

# ── Confirmation ─────────────────────────────────────────────────────────
if [[ "${1:-}" != "--force" ]]; then
    read -rp "Type 'yes' to confirm destruction: " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        echo -e "${GREEN}✓ Aborted — nothing was destroyed.${NC}"
        exit 0
    fi
fi

# ── Destroy ──────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}🗑  Running terraform destroy ...${NC}"
export AWS_DEFAULT_REGION="$REGION"
terraform destroy -auto-approve -input=false

echo ""
echo -e "${GREEN}✅ Staging infrastructure destroyed.${NC}"

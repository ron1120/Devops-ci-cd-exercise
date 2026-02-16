#!/usr/bin/env bash
# =============================================================================
# Destroy the staging EC2 instance
# Finds the instance directly on AWS by tag, no Terraform state needed.
# Usage:  ./scripts/destroy-staging.sh          — interactive confirmation
#         ./scripts/destroy-staging.sh --force   — skip confirmation
# =============================================================================
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
TAG_NAME="staging-app-server"

# ── Colours ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── Pre-flight checks ───────────────────────────────────────────────────
if ! command -v aws &>/dev/null; then
    echo -e "${RED}✗ aws CLI not found. Install it first.${NC}"; exit 1
fi

# ── Find running staging instances ───────────────────────────────────────
echo -e "${YELLOW}🔍 Searching for instances tagged '${TAG_NAME}' in ${REGION}...${NC}"
echo ""

INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=tag:Name,Values=${TAG_NAME}" \
              "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[].Instances[].[InstanceId,InstanceType,State.Name,PublicIpAddress,LaunchTime]" \
    --output text 2>&1)

if [[ -z "$INSTANCES" || "$INSTANCES" == "None" ]]; then
    echo -e "${GREEN}✓ No running staging instances found. Nothing to destroy.${NC}"
    exit 0
fi

# ── Display instances ────────────────────────────────────────────────────
echo -e "${CYAN}Found instance(s):${NC}"
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
printf "${CYAN}%-22s %-12s %-10s %-18s %s${NC}\n" "INSTANCE ID" "TYPE" "STATE" "PUBLIC IP" "LAUNCHED"
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo "$INSTANCES" | while IFS=$'\t' read -r id type state ip launched; do
    printf "%-22s %-12s %-10s %-18s %s\n" "$id" "$type" "$state" "${ip:-N/A}" "$launched"
done
echo ""

INSTANCE_IDS=$(echo "$INSTANCES" | awk '{print $1}' | tr '\n' ' ')

echo -e "${RED}┌──────────────────────────────────────────────┐${NC}"
echo -e "${RED}│  ⚠  THESE INSTANCES WILL BE TERMINATED       │${NC}"
echo -e "${RED}│  ${INSTANCE_IDS}${NC}"
echo -e "${RED}└──────────────────────────────────────────────┘${NC}"
echo ""

# ── Confirmation ─────────────────────────────────────────────────────────
if [[ "${1:-}" != "--force" ]]; then
    read -rp "Type 'yes' to confirm termination: " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        echo -e "${GREEN}✓ Aborted — nothing was destroyed.${NC}"
        exit 0
    fi
fi

# ── Terminate ────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}🗑  Terminating instances...${NC}"
# shellcheck disable=SC2086
aws ec2 terminate-instances --region "$REGION" --instance-ids $INSTANCE_IDS --output table

echo ""
echo -e "${YELLOW}⏳ Waiting for termination to complete...${NC}"
# shellcheck disable=SC2086
aws ec2 wait instance-terminated --region "$REGION" --instance-ids $INSTANCE_IDS 2>/dev/null || true

echo -e "${GREEN}✅ Staging instance(s) terminated.${NC}"

# ── Clean up Security Groups ────────────────────────────────────────────
echo ""
echo -e "${YELLOW}🧹 Cleaning up staging security groups...${NC}"
SG_IDS=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters "Name=group-name,Values=staging-app-*" \
    --query "SecurityGroups[].GroupId" \
    --output text 2>/dev/null || true)

if [[ -n "$SG_IDS" && "$SG_IDS" != "None" ]]; then
    for sg in $SG_IDS; do
        echo "  Deleting security group $sg ..."
        aws ec2 delete-security-group --region "$REGION" --group-id "$sg" 2>/dev/null || \
            echo -e "  ${YELLOW}⚠  Could not delete $sg (may still be in use, will be cleaned up later)${NC}"
    done
fi

echo ""
echo -e "${GREEN}✅ Cleanup complete.${NC}"

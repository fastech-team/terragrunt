#!/bin/bash

# Script de validação do projeto Terragrunt
# Valida estrutura, sintaxe e dependências

set -e

echo "🔍 Validando estrutura do projeto Terragrunt..."

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

# Função para log
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

# 1. Verificar se Terragrunt está instalado
echo ""
echo "📦 Verificando dependências..."
if ! command -v terragrunt &> /dev/null; then
    log_error "Terragrunt não está instalado"
else
    TERRAGRUNT_VERSION=$(terragrunt --version | awk '{print $NF}')
    log_info "Terragrunt $TERRAGRUNT_VERSION encontrado"
fi

if ! command -v terraform &> /dev/null; then
    log_error "Terraform não está instalado"
else
    TERRAFORM_VERSION=$(terraform --version | head -n 1 | awk '{print $NF}')
    log_info "Terraform $TERRAFORM_VERSION encontrado"
fi

# 2. Verificar estrutura de diretórios
echo ""
echo "📁 Verificando estrutura de diretórios..."

DIRS=(
    "live/root-terragrunt.hcl"
    "live/develop/account.hcl"
    "live/develop/environment.hcl"
    "live/develop/us-east-1/region.hcl"
    "modules/ec2"
    "modules/vpc"
    "modules/s3"
    "modules/ecs"
    "modules/rds"
)

for dir in "${DIRS[@]}"; do
    if [ -e "$dir" ]; then
        log_info "$dir encontrado"
    else
        log_error "$dir não encontrado"
    fi
done

# 3. Validar arquivos .hcl e .tf
echo ""
echo "✅ Validando sintaxe Terraform..."

# Validar live
cd live && \
if terragrunt validate-all --no-color > /dev/null 2>&1; then
    log_info "Configurações Terragrunt válidas"
else
    log_warning "Algumas configurações Terragrunt podem ter problemas"
fi
cd ..

# 4. Verificar módulos
echo ""
echo "🔧 Validando módulos..."

for module in modules/*/; do
    module_name=$(basename "$module")
    if [ -f "$module/main.tf" ] && [ -f "$module/variables.tf" ] && [ -f "$module/outputs.tf" ]; then
        cd "$module"
        if terraform validate > /dev/null 2>&1; then
            log_info "Módulo $module_name válido"
        else
            log_warning "Módulo $module_name tem problemas de validação"
        fi
        cd - > /dev/null
    else
        log_warning "Módulo $module_name está incompleto (faltam main.tf, variables.tf ou outputs.tf)"
    fi
done

# 5. Verificar terraform.tfvars
echo ""
echo "⚙️ Verificando configurações..."
if [ ! -f "terraform.tfvars" ]; then
    log_warning "terraform.tfvars não encontrado (copie de terraform.tfvars.example)"
else
    log_info "terraform.tfvars encontrado"
fi

# 6. Verificar AWS credentials
echo ""
echo "🔐 Verificando credenciais AWS..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_info "Credenciais AWS válidas (Account: $ACCOUNT_ID)"
else
    log_error "Credenciais AWS não configuradas ou inválidas"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Validação completa! Nenhum erro encontrado.${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS aviso(s)${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Validação falhou! $ERRORS erro(s) encontrado(s).${NC}"
    exit 1
fi

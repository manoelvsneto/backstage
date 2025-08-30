# Stage 1 - Create yarn install skeleton layer
FROM node:18-bookworm-slim AS packages

WORKDIR /app

COPY package.json yarn.lock ./
COPY .yarn ./.yarn
COPY .yarnrc.yml ./

# Copiar apenas os package.json necessários
COPY packages/backend/package.json packages/backend/
COPY packages/app/package.json packages/app/

# Criar estrutura de diretórios para pacotes usando comandos compatíveis com Docker
RUN mkdir -p packages/catalog || true
COPY packages/catalog/package.json packages/catalog/ 2>/dev/null || echo "Catalog package not found"

# Criar diretórios para todos os pacotes encontrados
RUN find packages plugins -type f -name 'package.json' -not -path "*/node_modules/*" -not -path "*/dist/*" | \
    xargs -I{} dirname {} | \
    xargs -I{} mkdir -p {}

# Instalar dependências
RUN yarn install --network-timeout 600000

# Stage 2 - Build packages
FROM node:18-bookworm-slim AS build

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    libsqlite3-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configurar variáveis de ambiente (corrigindo o formato)
ENV NODE_ENV=development
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=true

# Copiar tudo do estágio anterior
COPY --from=packages /app .

# Copiar o código-fonte
COPY . .

# Build do backend
RUN yarn tsc
RUN yarn build:backend

# Stage 3 - Imagem de produção
FROM node:18-bookworm-slim

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    libsqlite3-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário non-root
RUN groupadd -r backstage && \
    useradd -r -g backstage -d /app backstage && \
    chown -R backstage:backstage /app

# Copiar apenas os arquivos necessários
COPY --from=build /app/packages/backend/dist/package.json .
COPY --from=build /app/yarn.lock .
COPY --from=build /app/packages/backend/dist/* .
COPY --from=build /app/app-config*.yaml .

# Mudar para usuário non-root
USER backstage

# Configurar ambiente (corrigindo o formato)
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend", "--config", "app-config.yaml"]
# Stage 1 - Build
FROM node:18-bookworm-slim AS build

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    python3 \
    build-essential \
    git \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copiar todo o código-fonte primeiro
# Isso garante que todos os workspaces estejam disponíveis durante a instalação
COPY . .

# Configurar ambiente para evitar problemas
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Remover o diretório node_modules se existir e usar npm para instalar
RUN rm -rf node_modules && \
    npm ci

# Build dos pacotes
RUN npm run tsc && \
    npm run build

# Stage 2 - Imagem de produção
FROM node:18-bookworm-slim

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    python3 \
    build-essential \
    git \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copiar configurações do npm
COPY package.json package-lock.json* ./

# Copiar app-config
COPY --from=build /app/app-config*.yaml ./

# Copiar pacotes compilados
COPY --from=build /app/packages packages
COPY --from=build /app/plugins plugins
COPY --from=build /app/node_modules node_modules

# Configurar ambiente
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend/dist/index.js"]

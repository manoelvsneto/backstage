# Stage 1 - Build
FROM node:18-bookworm AS build

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

# Confirmar que estamos usando Yarn 1.x
RUN yarn --version

# Definir variáveis de ambiente para evitar downloads desnecessários
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Copiar todo o projeto (importante para monorepo com workspaces)
COPY . .

# Instalar dependências usando Yarn 1.x
RUN yarn install

# Build dos pacotes
RUN yarn tsc
RUN yarn build

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

# Copiar arquivos de configuração do yarn
COPY package.json yarn.lock ./
COPY .yarn ./.yarn
COPY .yarnrc.yml ./

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

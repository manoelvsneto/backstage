# Baseado na abordagem recomendada para Backstage com Yarn Berry
FROM node:18-bookworm-slim AS build

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    libsqlite3-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar variáveis de ambiente
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Copiar todo o código-fonte de uma vez
COPY . .

# Habilitar corepack para usar a versão do Yarn no projeto
RUN corepack enable

# Verificar a versão do Yarn
RUN yarn --version

# Instalar dependências
RUN yarn install

# Build
RUN yarn tsc
RUN yarn build

# Stage 2 - Imagem de produção
FROM node:18-bookworm-slim

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    libsqlite3-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar arquivos de configuração
COPY --from=build /app/package.json /app/yarn.lock ./
COPY --from=build /app/.yarn ./.yarn
COPY --from=build /app/.yarnrc.yml ./
COPY --from=build /app/app-config*.yaml ./

# Habilitar corepack para usar a versão do Yarn no projeto
RUN corepack enable

# Copiar pacotes compilados
COPY --from=build /app/packages /app/packages
COPY --from=build /app/node_modules /app/node_modules

# Se existir, copiar plugins compilados
RUN mkdir -p /app/plugins
COPY --from=build /app/plugins /app/plugins 2>/dev/null || true

# Configurar ambiente
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend/dist/index.js"]

# Baseado na abordagem recomendada para Backstage com Yarn Berry
FROM node:18 AS build

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

# Estratégia para garantir que o build do Backstage funcione com o Yarn Berry
COPY package.json yarn.lock ./
COPY .yarn ./.yarn
COPY .yarnrc.yml ./

# Usar a versão do Yarn Berry do projeto
RUN corepack enable && \
    yarn --version

# Copiar apenas arquivos necessários para o build inicialmente
COPY packages packages
COPY plugins plugins
COPY app-config*.yaml ./
COPY tsconfig*.json ./

# Instalar dependências de forma robusta com o Yarn Berry
RUN yarn install

# Agora fazer o build
RUN yarn tsc && \
    yarn build:backend --config app-config.yaml

# Stage de produção
FROM node:18

WORKDIR /app

# Instalar dependências do sistema necessárias para produção
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    libsqlite3-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar apenas os arquivos necessários para produção
COPY --from=build /app/packages/backend/dist/bundle.tar.gz .

RUN tar xzf bundle.tar.gz && \
    rm bundle.tar.gz

# Configurações de ambiente para produção
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend"]
# Comando para iniciar o backend
CMD ["node", "packages/backend/dist/index.js"]

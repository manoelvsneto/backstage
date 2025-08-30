# Stage 1 - Build
FROM node:18-bookworm-slim AS build

WORKDIR /app

# Instalar dependências do sistema necessárias ANTES do yarn install
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    python3 \
    build-essential \
    git \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/* \
    && yarn config set python /usr/bin/python3

# Melhorar o cache do Docker copiando apenas os arquivos de configuração do yarn primeiro
COPY package.json yarn.lock ./
COPY .yarn ./.yarn
COPY .yarnrc.yml ./

# Configurar ambiente para evitar problemas com o Yarn
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Instalar dependências com flags compatíveis com Yarn v2+
RUN yarn install --immutable

# Copiar código-fonte depois que as dependências foram instaladas
COPY . .

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
    && rm -rf /var/lib/apt/lists/* \
    && yarn config set python /usr/bin/python3

# Copiar configurações do yarn
COPY --from=build /app/package.json /app/yarn.lock ./
COPY --from=build /app/.yarn ./.yarn
COPY --from=build /app/.yarnrc.yml ./

# Copiar app-config
COPY --from=build /app/app-config*.yaml ./

# Copiar pacotes compilados
COPY --from=build /app/packages packages
COPY --from=build /app/plugins plugins

# Configurar ambiente
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Instalar dependências de produção (usando --immutable e --mode prod)
RUN yarn install --immutable --mode prod

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend/dist/index.js"]

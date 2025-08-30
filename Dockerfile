# Stage 1 - Build
FROM node:18-bookworm-slim AS build

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    libsqlite3-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar Yarn Classic (1.x) explicitamente
RUN npm install -g yarn@1.22.19 && \
    yarn --version

# Configurar variáveis de ambiente
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=true
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Copiar todo o código-fonte de uma vez
COPY . .

# Ignorar o Yarn Berry e usar o Yarn Classic
RUN rm -rf .yarn .yarnrc.yml
RUN echo '{"nodeLinker": "node-modules"}' > .yarnrc.json

# Instalar dependências com Yarn Classic
RUN yarn install --network-timeout 600000

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

# Criar usuário non-root
RUN groupadd -r backstage && \
    useradd -r -g backstage -d /app backstage && \
    chown -R backstage:backstage /app

# Copiar o package.json e yarn.lock
COPY --from=build --chown=backstage:backstage /app/package.json ./
COPY --from=build --chown=backstage:backstage /app/yarn.lock ./

# Copiar app-config
COPY --from=build --chown=backstage:backstage /app/app-config*.yaml ./

# Copiar o código compilado
COPY --from=build --chown=backstage:backstage /app/packages ./packages
COPY --from=build --chown=backstage:backstage /app/plugins ./plugins
COPY --from=build --chown=backstage:backstage /app/node_modules ./node_modules

# Mudar para usuário non-root
USER backstage

# Configurar ambiente
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend/dist/index.js"]
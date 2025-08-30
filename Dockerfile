# Stage 1 - Build
FROM node:18-bookworm-slim AS build

WORKDIR /app

# Copiar arquivos de configuração do yarn
COPY package.json yarn.lock ./
COPY .yarn ./.yarn
COPY .yarnrc.yml ./

# Instalar dependências
RUN yarn install --frozen-lockfile

# Copiar código-fonte
COPY . .

# Build dos pacotes
RUN yarn tsc
RUN yarn build

# Stage 2 - Imagem de produção
FROM node:18-bookworm-slim

WORKDIR /app

# Instalar dependências do sistema necessárias
RUN apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev python3 build-essential git && \
    rm -rf /var/lib/apt/lists/* && \
    yarn config set python /usr/bin/python3

# Copiar configurações do yarn
COPY --from=build /app/package.json /app/yarn.lock ./
COPY --from=build /app/.yarn ./.yarn
COPY --from=build /app/.yarnrc.yml ./

# Copiar app-config
COPY --from=build /app/app-config*.yaml ./

# Copiar pacotes compilados
COPY --from=build /app/packages packages
COPY --from=build /app/plugins plugins

# Instalar dependências de produção
RUN yarn install --frozen-lockfile --production

# Configurar variáveis de ambiente
ENV NODE_ENV=production

# Expor porta padrão do Backstage
EXPOSE 7007

# Comando para iniciar o backend
CMD ["node", "packages/backend/dist/index.js"]

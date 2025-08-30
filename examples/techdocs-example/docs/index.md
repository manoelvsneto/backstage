# Documentação de Exemplo

Bem-vindo à documentação de exemplo do TechDocs!

## Sobre este exemplo

Este é um exemplo de como você pode configurar documentação técnica no Backstage usando o TechDocs. 
O TechDocs permite que você escreva documentação como código, armazenando-a junto com seu código-fonte.

## Recursos principais

- Documentação em Markdown
- Integração com o catálogo do Backstage
- Suporte a versões e histórico
- Pesquisa integrada

## Como começar

Para adicionar documentação ao seu próprio componente:

1. Crie um arquivo `mkdocs.yml` na raiz do seu repositório
2. Adicione um diretório `docs/` com arquivos markdown
3. Adicione a anotação `backstage.io/techdocs-ref` ao seu arquivo `catalog-info.yaml`

```yaml
annotations:
  backstage.io/techdocs-ref: dir:.
```

Consulte a [documentação oficial do TechDocs](https://backstage.io/docs/features/techdocs/) para mais informações.

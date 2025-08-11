# Rinha

Projeto da rinha 2025: https://github.com/zanfranceschi/rinha-de-backend-2025

## Ideia do projeto

Usar o mínimo de dependências externas a não ser que elas tenham performance melhor que a que já existe em elixir

E também tentei fazer do jeito mais simples e com menos dor de cabeça possível

No final ficou isso, coisas nativas do elixir:
- `JSON` encoder e decoder
- `ETS` para armazenamento e cache
- `Task.Supervisor` para processamento assincrono
- `erpc` para conseguir dados do outro node

Externas:
- `Finch` HTTP client with conn pool
- `Bandit` HTTP server mais rápido do elixir
- `Plugs` padrão de conexões

Também fiz manualmente benchmarks para quase todas essas tecnologias (perdi tempo demais nisso :sad:)

# edu-session

> Registro automático do uso dos notebooks da escola. Chega de folha de papel e caneta.

O aluno faz login no notebook com o email institucional e um script silencioso avisa o servidor: *quem*, *qual aparelho*, *quando*. O TI acompanha tudo por um painel web na rede local.

## Tecnologias

[![Bun](https://img.shields.io/badge/Bun-303030?logo=bun&logoColor=white&style=for-the-badge)](#)&nbsp;
[![TypeScript](https://img.shields.io/badge/TypeScript-303030?logo=typescript&logoColor=white&style=for-the-badge)](#)&nbsp;
[![SQLite](https://img.shields.io/badge/SQLite-303030?logo=sqlite&logoColor=white&style=for-the-badge)](#)&nbsp;
[![Docker](https://img.shields.io/badge/Docker-303030?logo=docker&logoColor=white&style=for-the-badge)](#)&nbsp;
[![Git](https://img.shields.io/badge/Git-303030?logo=git&logoColor=white&style=for-the-badge)](#)&nbsp;

## Como funciona

```
[notebook do aluno]                        [PC da escola]
  script no logon ──── POST /logins ────►  API Bun + SQLite (Docker)
  {email, notebook, data/hora}                    │
                                             painel web em /
```

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/logins` | Registra um login (`email` + `notebook`) |
| `GET` | `/logins` | Lista logins com filtros e paginação |

**Filtros do GET** (combináveis via query params):

| Param | Exemplo | Comportamento |
|---|---|---|
| `notebook` | `?notebook=23` | Busca parcial (LIKE) |
| `email` | `?email=joao@` | Busca parcial (LIKE) |
| `limit` | `?limit=20` | Padrão 50 · máx 100 |
| `cursor` | `?cursor=2026-08-23T01:29:32.025Z` | Paginação keyset pelo timestamp |

Resposta paginada:

```json
{
  "success": true,
  "logins": [
    { "id": 4, "email": "b@escola.com", "notebook": "CB-01", "received_in": "2026-08-23T01:29:32.052Z" }
  ],
  "nextCursor": "2026-08-22T23:57:55.714Z"
}
```

`nextCursor: null` significa fim da lista.

## Rodando localmente

```bash
bun install
bun dev        # http://localhost:3000
```

## Com Docker

```bash
docker build -t edu-session .
docker run -d --name edu-session -p 3000:3000 -v ./data:/app/data edu-session
```

O volume `./data` mantém o banco SQLite vivo entre recriações do container.

## Estrutura

```
edu-session/
├── index.ts          # servidor: rotas, validação, queries
├── public/           # painel web servido pela própria API
│   ├── index.html
│   ├── app.js
│   └── style.css
├── Dockerfile
└── data/             # banco SQLite (não versionado)
```

## Roadmap

- [x] API com validação e paginação por cursor
- [x] Painel web com busca e filtros
- [ ] Script de logon para os notebooks (PowerShell)
- [ ] Instalador único para as máquinas da escola

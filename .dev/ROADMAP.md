# Roadmap

## 1.0.0 (publicada)

- [x] Documentar a limitação de escrita concorrente entre processos (`docs/SECURITY.md`, `docs/ARCHITECTURE.md`).
- [x] Corrigir as inconsistências do CHANGELOG: seção da versão com data real e links de comparação.
- [x] Endurecer `Level.coerce` — severidade numérica precisa ser `Integer` (ADR-010).
- [x] Scripts de teste manual e portão de release em `.dev/scripts`.

## 1.x (backlog)

- [ ] Rotação de logs por tamanho/data, opt-in — ADR-005.
- [ ] Estilização não cromática no `Formatter` (alinhamento, truncamento) — ADR-004.
- [ ] Sanitização opcional de caracteres de controle no `Formatter` (ver `docs/SECURITY.md`).
- [ ] Locks entre processos com `flock`, opt-in — extensão do modelo do ADR-009.
- [ ] Logging assíncrono por delegação — ADR-006.
- [ ] Suíte e2e (`spec/e2e` ainda é placeholder).
- [ ] Fixar as actions por SHA (a própria `configure-rubygems-credentials` recomenda).

## 2.0 (somente se necessário)

- [ ] Nada planejado: mudanças incompatíveis só entram em uma major.
# Desenvolvimento

Notas internas do repositório. Este diretório (`.dev/`) está no `.gitignore`: nada aqui vai para o repositório nem para a gem publicada.

## Ambiente

* Ruby >= 3.3 (a gem suporta 3.3, 3.4 e 4.0; a matriz do CI cobre as três versões).
* `bundle install` para instalar rspec, rubocop e rake.

## Comandos

| Comando | O que faz |
| --- | --- |
| `bundle exec rspec` | suíte completa (unit + integration) |
| `bundle exec rubocop` | lint — o CI falha em qualquer ofensa |
| `bundle exec rake` | spec + rubocop (tarefa padrão) |
| `bundle exec rake build` | gera `pkg/logaru-<versão>.gem` |
| `gem build logaru.gemspec --strict` | valida o empacotamento (também roda no CI) |

## Scripts de teste manual (`scripts/`)

Ruby puro — sem RSpec e sem Bundler. Cada script imprime `[ok]`/`[FAIL]` por verificação, sai com status 1 quando algo falha e escreve arquivos temporários em `.dev/tmp/<nome>/` (pode apagar essa pasta a qualquer momento).

```bash
ruby .dev/scripts/01_quickstart.rb    # um script específico
ruby .dev/scripts/run_all.rb          # todos os scripts
ruby .dev/scripts/run_all.rb 0        # somente os que casam com "0"
```

| Script | O que cobre |
| --- | --- |
| `01_quickstart.rb` | versão, `Logaru.root`, níveis, filtragem e severidade como constante, nome ou símbolo |
| `02_file_logging.rb` | arquivo criado na primeira escrita, diretórios pais, append, `#close`/reabertura, rotação externa, `Pathname` e stream do chamador |
| `03_formatters.rb` | padrão default, bloco, `pattern:`, formatter injetado, precedência e validação de aridade |
| `04_errors.rb` | as quatro exceções, a hierarquia de `Logaru::Error` e a validação no `new` |
| `05_threads.rb` | escrita serializada, 200 entradas de 8 threads e `#close` concorrente |
| `install_smoke.rb` | build + instalação em um `GEM_HOME` temporário + `require` em processo limpo |
| `verify_release.rb` | portão de release: versões, CHANGELOG, links dos docs, conteúdo do pacote, rspec, rubocop e workflows |

Todos usam `require_relative "../../lib/logaru"`, então rodam sempre contra o código do repositório.

## Checklist de release

1. `lib/logaru/version.rb` — bump da versão.
2. `CHANGELOG.md` — mover o conteúdo de `[Unreleased]` para uma seção `## [x.y.z] - AAAA-MM-DD` e ajustar os links (`compare/vX.Y.Z...HEAD` e `releases/tag/vX.Y.Z`).
3. `bundle install` — registra a nova versão no `Gemfile.lock`.
4. `ruby .dev/scripts/run_all.rb` — todos os scripts verdes.
5. Commit e push (PR de `develop` para `main`).
6. Trusted publisher configurado no RubyGems.org: repositório `rpzerosixcode/logaru`, workflow `release.yml`, sem environment.
7. `git tag vX.Y.Z && git push origin vX.Y.Z` — o workflow `Release` valida, publica no RubyGems e cria a GitHub Release.
8. Pós-publicação: `gem list -r logaru`, `gem install logaru` em um diretório limpo e, se quiser, o badge de versão no README:
   `[![Gem Version](https://img.shields.io/gem/v/logaru.svg)](https://rubygems.org/gems/logaru)`.

## Onde está o quê

* `DECISIONS.md` — ADRs das decisões implementadas e das alternativas avaliadas.
* `ROADMAP.md` — backlog dos próximos passos.
* `docs/` (versionado) — documentação de usuário, em inglês.
* `tmp/` — artefatos descartáveis dos scripts.

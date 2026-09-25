# Decisões

Registro das decisões de arquitetura e das avaliações previstas no `ROADMAP.md`.

## ADR-001 — `Formatter` baseado em instâncias (implementado)

**Contexto:** o `Formatter` guardava o padrão em estado de classe (`@pattern`), de modo que qualquer ponto do código alterava globalmente o formato de todos os loggers.

**Decisão:** o padrão passou a ser atributo de instância (`Logaru::Formatter.new(pattern: ...)` ou bloco), exposto por `#pattern`. O `Logaru::Logger` cria o seu próprio `Formatter` quando nenhum é informado.

**Consequências:** loggers podem ter formatos independentes. Os métodos de classe `Logaru::Formatter.pattern` e `Logaru::Formatter.format` foram removidos (mudança incompatível, aceitável dentro do `0.1.0` ainda não publicado).

## ADR-002 — Validação de aridade do padrão (implementado)

**Contexto:** um padrão com aridade errada (`proc { |message| ... }`) falhava em silêncio ou estourava apenas no momento do log.

**Decisão:** validar o padrão no `initialize`. Regras:

- precisa responder a `#call`;
- objetos que não expõem `#parameters` são aceitos (qualquer callable);
- quando `#parameters` existe, o padrão deve poder receber os 4 argumentos: obrigatórios ≤ 4 e (`rest` presente **ou** obrigatórios + opcionais ≥ 4).

Aceitos: `proc { |s, d, p, m| }`, `proc { |s, d, p, m = nil| }`, `->(s, d, p, m) {}`, `|*args|`. Rejeitados: `proc { |a, b| }` e `->(a, b) {}` (`Logaru::InvalidPatternError`).

**Nota:** `Proc#arity` não foi usado isoladamente porque blocos (não lambda) reportam todos os parâmetros como opcionais — `proc { |a, b, c, d = nil| }.arity == 3` — o que geraria falso negativo.

## ADR-003 — Gerenciamento de arquivos (implementado)

**Contexto:** o logger abria e fechava o arquivo a cada entrada (uma syscall por log), não criava diretórios e aceitava qualquer valor em `file:`.

**Decisão:**

- `file:` aceita `String`, `Pathname` ou objeto que responda a `#write`; valores inválidos falham de imediato (`Logaru::InvalidOutputError`);
- o arquivo é aberto na primeira escrita (lazy), em modo append, e o handle é reutilizado;
- `sync` é `true` por padrão, então o arquivo está sempre atualizado;
- diretórios pais são criados com `FileUtils.mkdir_p`;
- `#device` expõe o IO em uso; `#close` fecha **apenas** o arquivo aberto pelo logger e a escrita seguinte reabre (permite rotação externa); streams do chamador não são fechados.

**Consequências:** o arquivo permanece aberto enquanto o logger viver — é preciso chamar `#close` para liberá-lo (no Windows, renomear ou remover um arquivo aberto falha). Comportamento equivalente ao `Logger` da biblioteca padrão.

## ADR-004 — Estilização visual sem cores ANSI (decidido, não implementado)

**Contexto:** o roadmap pede estilização visual do `Formatter`. Uma primeira versão colorizava a entrada conforme a severidade usando códigos ANSI (`Logaru::Style`, opção `color: true/false/:auto`, detecção de TTY, `NO_COLOR`, `TERM=dumb`).

**Decisão:** **não** incluir cores ANSI nesta rodada. A implementação foi removida e o item segue aberto no roadmap para ser redefinido.

**Alternativas avaliadas:** (1) cores automáticas — descartadas; (2) cores apenas quando a saída é um terminal — descartadas junto; (3) estilização não cromática (alinhamento de colunas, prefixo fixo, largura de rótulo, truncamento) — candidata para a próxima rodada.

## ADR-005 — Rotação de logs (avaliado, adiado)

**Opções avaliadas:**

1. **Rotação interna** por tamanho/data, replicando `Logger::LogDevice` da stdlib: exige renomear/arquivar, reabrir o handle, compressão e limpeza (`shift_age`, `shift_size`, `max_files`), ampliando a API ainda instável.
2. **Rotação externa** (`logrotate`, `systemd`, plataforma): nenhum código novo e já suportada pela API atual — rotacione o arquivo e chame `logger.close`; a próxima escrita reabre o caminho em modo append.
3. **Não tratar** rotação.

**Decisão:** documentar a opção 2 como caminho suportado (registrada no `README.md`) e manter a rotação interna no backlog como recurso opt-in, depois de estabilizar o gerenciamento de arquivos.

## ADR-006 — Logging assíncrono (avaliado, adiado)

**Opções avaliadas:**

1. **Thread escritora + fila limitada**, com `#flush`, hook de `at_exit` e política de descarte: reduz o custo por log, mas adiciona risco de perda de mensagens em crash, consumo não limitado se a fila crescer e necessidade de sincronização no encerramento.
2. **`Fiber` + scheduler**: depende do contexto async da aplicação; comportamento imprevisível dentro de uma biblioteca.
3. **Assíncrono por delegação**: o usuário escolhe o transporte (ex.: `Async`, Fluentd, syslog).

**Decisão:** adiar. Pré-requisito antes de qualquer versão assíncrona é garantir escrita thread-safe (mutex por logger) e definir política de descarte/`flush`; por ora, a recomendação é logar no próprio processo emissor.

## ADR-007 — Padrão configurável direto no `Logger` (implementado)

**Contexto:** mesmo com `Formatter` sendo instância, personalizar o formato exigia construir um formatter e injetá-lo (`Logger.new(formatter: Formatter.new { ... })`), o que era verboso para o caso mais comum.

**Decisão:** `Logaru::Logger.new` aceita `pattern:` e bloco; quando nenhum formatter é injetado, o logger constrói o formatter internamente com esse padrão (`Formatter::DEFAULT_PATTERN` quando nada é informado). `formatter:` continua disponível para reuso entre loggers e é mutuamente exclusivo com `pattern:`/bloco — combinar os dois levanta `Logaru::InvalidFormatterError`.

**Consequências:** o caminho comum passa a ser `Logger.new(file:, level:) { |s, d, p, m| ... }`; a validação de aridade continua concentrada no `Formatter`.

## ADR-008 — `Pathname` tratado como caminho, não como stream (corrigido)

**Contexto:** `Pathname` responde a `#write` (que grava o arquivo inteiro em uma chamada). Como o `Logger` classificava o output apenas por `respond_to?(:write)`, um `Pathname` era usado como o próprio device e **cada entrada sobrescrevia o arquivo** em vez de acrescentar. O teste unitário existente não pegou o problema porque escrevia uma única linha.

**Decisão:** classificar explicitamente. É caminho quando o valor é `String`, `Pathname` ou expõe `to_path` sem expor `write`; caso contrário, se responde a `write`, é stream do chamador (`File`, `StringIO`, `Tempfile`...). `open_file` converte com `to_path` antes de abrir em modo append.

**Consequências:** `file:` aceita os dois tipos sem ambiguidade, `#output` devolve o valor original e `#device` passa a ser um `File` para alvos `Pathname`. Cobertura: `spec/integration/log_file_spec.rb`.

## ADR-009 — Proteção de concorrência do device (implementado)

**Contexto:** o device era resolvido de forma preguiçosa (`@resolved_device ||= open_file(...)`), o que permitia que dois threads abrissem o arquivo ao mesmo tempo (handle vazado) e que escritas simultâneas se intercalassem. Era também o pré-requisito registrado no ADR-006.

**Decisão:** um `Mutex` por logger serializa a resolução do device, a escrita e o `#close`. O helper interno de resolução é chamado apenas com o lock em mãos; `#close` espera a escrita em andamento e a próxima escrita reabre o arquivo. Alternativa descartada: `Monitor` reentrante — desnecessário porque o caminho de escrita não aninha `synchronize`.

**Consequências:** um logger pode ser compartilhado entre threads, o arquivo é aberto exatamente uma vez e nenhuma entrada é perdida ou cortada. O `Formatter` continua sendo chamado **fora** do lock, então o padrão não deve depender de estado compartilhado mutável. Cobertura: `spec/integration/concurrency_spec.rb`.

## ADR-010 — Severidade numérica precisa ser Integer (corrigido)

**Contexto:** `Level.coerce` aceitava o valor bruto sempre que ele estivesse em `LEVELS.values`. Como `Hash#value?` compara com `==`, `Logaru::Level.coerce(1.0)` devolvia `1.0` (Float) e `logger.level` deixava de ser o `Integer` documentado no `README.md`. O valor continuava funcionando por acidente, porque `Hash#key` também usa `==` e `name_for(1.0)` ainda resolvia `"info"` — ou seja, a inconsistência passava silenciosamente.

**Decisão:** o atalho numérico exige `Integer`:

```ruby
return value if value.is_a?(Integer) && LEVELS.value?(value)
```

Nomes (`"WARN"`) e símbolos (`:warn`) seguem pelo caminho textual; qualquer outro valor (Float, `nil`, objeto) levanta `Logaru::InvalidLevelError`.

**Consequências:** `logger.level` é sempre um `Integer` e entradas malformadas falham cedo, junto com o resto da validação feita no `initialize`. Cobertura: `spec/unit/level_spec.rb`.

Agora vou criar o `.ps1` idiomático — script PowerShell "de verdade": com help embutido, parâmetros (`-Uninstall`, `-KeepModernMenu`, `-NoRestartExplorer`), detecção automática do `Code.exe`, tratamento de erro e reinício limpo do Explorer.

Vou validar a sintaxe do script sem executá-lo (só análise do parser, não roda nada nem mexe no registro):

Sintaxe OK (o exit 1 veio só do `Get-Help` formatando, não do parser). Vou fazer um teste seco da lógica de detecção do `Code.exe` e da montagem das chaves/comando — sem tocar no registro:

Pronto. Criei [contextmenu/vscode_contextmenu.ps1](contextmenu/vscode_contextmenu.ps1) — versão PowerShell idiomática. Validei o parser (sem erros) e testei a lógica em seco: **seu VS Code é instalação por usuário** (`...\AppData\Local\Programs\Microsoft VS Code\Code.exe`) e o script o detecta sozinho — ou seja, nem precisa de admin.

## O que o script faz "do jeito certo"

- **Help embutido** (`Get-Help .\vscode_contextmenu.ps1 -Full`) com `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`.
- **Parâmetros** em vez de editar o código:
  - `-Uninstall` → remove os itens e restaura o menu novo do Windows 11.
  - `-KeepModernMenu` → instala mas **não** força o menu clássico (fica em "Mostrar mais opções").
  - `-NoRestartExplorer` → não reinicia o Explorer no fim.
- **Detecção automática** do `Code.exe`: por usuário → por máquina → `Program Files (x86)` → PATH.
- `$ErrorActionPreference = 'Stop'` + `Set-StrictMode`, funções pequenas e reaproveitadas, `-LiteralPath` (importante por causa da chave literal `*`).
- **Reinício limpo** do Explorer (só sobe de novo se o Windows não tiver religado sozinho — evita janela sobrando).
- Aviso se a sessão estiver **elevada** (a mudança é HKCU; elevar com outra conta grava no lugar errado).
- Registra os 3 alvos com o token correto: `%1` para arquivos e pasta selecionada, `%V` para o fundo da pasta.

## Como executar

O Windows bloqueia `.ps1` por duplo-clique (Execution Policy). As formas corretas:

**Opção 1 — direto pelo terminal (recomendada):**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Admin\Desktop\contextmenu\vscode_contextmenu.ps1"
```

**Opção 2 — clicar com botão direito no arquivo `.ps1` → "Executar com o PowerShell".** Se a política bloquear, use a Opção 1.

Para desfazer depois, mesmo comando com `-Uninstall` no final.

> Rode como seu usuário normal — **não** "Executar como administrador". A alteração é toda no seu HKCU.

Não executei a instalação (ela reinicia o Explorer e troca o menu do sistema) — deixo isso para você rodar quando quiser. Quer que eu crie também um `.cmd` de um clique que já chama o `.ps1` com o `-ExecutionPolicy Bypass` (aí volta a ser duplo-clique e pronto)?
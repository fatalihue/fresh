# VS Code no menu de contexto do Windows 11

Adiciona **"Abrir com o Code"** ao clicar com o botão direito em **arquivos e pastas** — direto no primeiro clique, sem passar por *"Mostrar mais opções"*.

## Requisitos

- Windows 11
- VS Code instalado (por usuário ou por máquina — o script detecta sozinho)
- PowerShell 5.1+ (já vem no Windows)
- **Não** precisa de administrador (mexe apenas no seu `HKCU`)

## Instalação

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\vscode_contextmenu.ps1"
```

Ou clique com o botão direito no `.ps1` → **Executar com o PowerShell**.

> ⚠️ Execute como seu usuário normal. **Não** use "Executar como administrador" — a alteração é do `HKCU` e, se elevada com outra conta, iria para o lugar errado.

## Opções

| Opção | O que faz |
| --- | --- |
| *(nenhuma)* | Instala os itens e força o menu clássico (item aparece no 1º clique) |
| `-Uninstall` | Remove os itens e restaura o menu novo do Windows 11 |
| `-KeepModernMenu` | Instala, mas **não** força o menu clássico (item fica em "Mostrar mais opções") |
| `-NoRestartExplorer` | Não reinicia o `explorer.exe` ao final |

### Exemplos

```powershell
# Instalar (item no 1º clique)
powershell -NoProfile -ExecutionPolicy Bypass -File ".\vscode_contextmenu.ps1"

# Desinstalar (volta ao menu do Windows 11)
powershell -NoProfile -ExecutionPolicy Bypass -File ".\vscode_contextmenu.ps1" -Uninstall

# Instalar sem forçar o menu clássico
powershell -NoProfile -ExecutionPolicy Bypass -File ".\vscode_contextmenu.ps1" -KeepModernMenu
```

Ajuda embutida completa:

```powershell
Get-Help .\vscode_contextmenu.ps1 -Full
```

## Como funciona

- Cria verbos de shell em `HKCU\Software\Classes` para **arquivos** (`*`), **pastas** (`Directory`) e **fundo de pasta** (`Directory\Background`).
- Força o menu de contexto clássico criando `HKCU\...\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32` com valor vazio — a única forma, via registro, de o item aparecer no **primeiro clique** no Windows 11.

## Observações

- Forçar o menu clássico troca **todo** o menu de contexto para o estilo antigo (Windows 10) no seu usuário. Esse é o preço de eliminar o "Mostrar mais opções".
- É um ajuste **não documentado** pela Microsoft: uma atualização grande de versão do Windows pode resetá-lo — basta rodar o script de novo.
- Desfazer manualmente:

```powershell
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
```

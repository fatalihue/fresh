#Requires -Version 5.1
<#
.SYNOPSIS
    Adiciona "Abrir com o Code" ao menu de contexto (botao direito) de
    arquivos e pastas no Windows 11, aparecendo direto no primeiro clique.

.DESCRIPTION
    Registra verbos de shell no HKCU (nao precisa de admin) para:
      - Arquivos        (HKCU:\Software\Classes\*)
      - Pastas          (HKCU:\Software\Classes\Directory)
      - Fundo de pasta  (HKCU:\Software\Classes\Directory\Background)

    No Windows 11, verbos classicos ficam escondidos em "Mostrar mais opcoes".
    Para o item aparecer ja no PRIMEIRO clique, o script tambem forca o menu
    de contexto classico como padrao, criando a chave CLSID
    {86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 com valor vazio.
    Tudo e alteracao apenas do seu usuario (HKCU) - nao mexe na maquina toda.

.PARAMETER Uninstall
    Remove os itens do menu e restaura o menu novo do Windows 11.

.PARAMETER KeepModernMenu
    Instala os itens mas NAO forca o menu classico. O item so aparecera em
    "Mostrar mais opcoes" (comportamento padrao do Windows 11).

.PARAMETER NoRestartExplorer
    Nao reinicia o explorer.exe ao final. As mudancas so passam a valer apos
    reiniciar o Explorer ou fazer logoff/logon.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\vscode_contextmenu.ps1
    Instala os itens e forca o menu classico.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\vscode_contextmenu.ps1 -Uninstall
    Remove tudo e volta ao menu novo do Windows 11.

.NOTES
    Execute como seu usuario normal. NAO use "Executar como administrador":
    a alteracao e do HKCU e, se elevada com outra conta, iria para o hive
    errado e nao teria efeito.
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    [switch]$KeepModernMenu,
    [switch]$NoRestartExplorer
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# --- Constantes -----------------------------------------------------------

# CLSID do handler do menu "novo" do Windows 11. Criar InprocServer32 com
# valor padrao vazio faz o Explorer cair no menu classico completo.
$ModernMenuClsidKey = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'

$VerbName  = 'VSCode'
$MenuLabel = 'Abrir com o Code'

# Cada alvo tem a raiz da classe e o token de caminho que o Explorer
# substitui: %1 = item selecionado (arquivo/pasta), %V = pasta atual (fundo).
$Targets = @(
    [pscustomobject]@{ Root = 'HKCU:\Software\Classes\*';                    Arg = '%1' }  # arquivos
    [pscustomobject]@{ Root = 'HKCU:\Software\Classes\Directory';            Arg = '%1' }  # pasta selecionada
    [pscustomobject]@{ Root = 'HKCU:\Software\Classes\Directory\Background'; Arg = '%V' }  # fundo da pasta
)

# --- Funcoes --------------------------------------------------------------

function Find-VSCodeExe {
    <# Localiza o Code.exe: instalacao por usuario, por maquina e, por fim, o PATH. #>
    $candidates = [System.Collections.Generic.List[string]]::new()
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'))
    if ($env:ProgramFiles)        { $candidates.Add((Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe')) }
    $pf86 = ${env:ProgramFiles(x86)}
    if ($pf86)                    { $candidates.Add((Join-Path $pf86 'Microsoft VS Code\Code.exe')) }

    foreach ($p in $candidates) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }

    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        $exe = Join-Path (Split-Path -Parent (Split-Path -Parent $cmd.Source)) 'Code.exe'
        if (Test-Path -LiteralPath $exe) { return $exe }
    }
    return $null
}

function New-ContextMenuEntry {
    param(
        [Parameter(Mandatory)] [string]$Root,
        [Parameter(Mandatory)] [string]$Exe,
        [Parameter(Mandatory)] [string]$Arg
    )
    $verbKey = "$Root\shell\$VerbName"
    $cmdKey  = "$verbKey\command"

    New-Item -Path $verbKey -Force | Out-Null
    Set-ItemProperty -LiteralPath $verbKey -Name '(Default)' -Value $MenuLabel
    Set-ItemProperty -LiteralPath $verbKey -Name 'Icon'      -Value $Exe

    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -LiteralPath $cmdKey  -Name '(Default)' -Value ('"{0}" "{1}"' -f $Exe, $Arg)
}

function Remove-ContextMenuEntry {
    param([Parameter(Mandatory)] [string]$Root)
    $verbKey = "$Root\shell\$VerbName"
    if (Test-Path -LiteralPath $verbKey) {
        Remove-Item -LiteralPath $verbKey -Recurse -Force
        Write-Host "  Removido: $verbKey" -ForegroundColor DarkGray
    }
}

function Restart-Explorer {
    Write-Host 'Reiniciando o Explorer para aplicar as mudancas...' -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    # Winlogon costuma reiniciar o shell sozinho; so subimos se nao voltou.
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
}

# --- Verificacoes ---------------------------------------------------------

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($isAdmin) {
    Write-Warning ('Esta sessao esta ELEVADA. Se foi elevada com OUTRA conta, as chaves ' +
        'vao para o HKCU errado e o menu nao muda. Rode como seu usuario normal.')
}

# --- Desinstalacao --------------------------------------------------------

if ($Uninstall) {
    Write-Host 'Removendo itens do menu de contexto...' -ForegroundColor Cyan
    foreach ($t in $Targets) { Remove-ContextMenuEntry -Root $t.Root }

    if (Test-Path -LiteralPath $ModernMenuClsidKey) {
        Remove-Item -LiteralPath $ModernMenuClsidKey -Recurse -Force
        Write-Host '  Menu novo do Windows 11 restaurado.' -ForegroundColor DarkGray
    }

    if (-not $NoRestartExplorer) { Restart-Explorer }
    Write-Host 'Desinstalacao concluida.' -ForegroundColor Green
    return
}

# --- Instalacao -----------------------------------------------------------

$exe = Find-VSCodeExe
if (-not $exe) {
    Write-Error ('Code.exe nao encontrado nos locais padrao nem no PATH. ' +
        'Instale o VS Code ou ajuste o caminho no script.')
    exit 1
}
Write-Host "VS Code encontrado: $exe" -ForegroundColor DarkGray

Write-Host 'Registrando "Abrir com o Code" para arquivos e pastas...' -ForegroundColor Cyan
foreach ($t in $Targets) {
    New-ContextMenuEntry -Root $t.Root -Exe $exe -Arg $t.Arg
    Write-Host "  OK: $($t.Root)\shell\$VerbName" -ForegroundColor DarkGray
}

if ($KeepModernMenu) {
    Write-Warning 'Menu classico NAO forcado (-KeepModernMenu). O item ficara em "Mostrar mais opcoes".'
} else {
    $inproc = "$ModernMenuClsidKey\InprocServer32"
    New-Item -Path $inproc -Force | Out-Null
    Set-ItemProperty -LiteralPath $inproc -Name '(Default)' -Value ''
    Write-Host '  Menu classico forcado (item aparece ja no 1o clique).' -ForegroundColor DarkGray
}

if (-not $NoRestartExplorer) { Restart-Explorer }

Write-Host ''
Write-Host '================================================' -ForegroundColor Green
Write-Host ' Concluido! Botao direito em qualquer arquivo ou'  -ForegroundColor Green
Write-Host ' pasta: "Abrir com o Code" aparece direto,'        -ForegroundColor Green
Write-Host ' sem precisar de "Mostrar mais opcoes".'           -ForegroundColor Green
Write-Host '================================================' -ForegroundColor Green
Write-Host ' Para desfazer:  -Uninstall'                       -ForegroundColor Yellow

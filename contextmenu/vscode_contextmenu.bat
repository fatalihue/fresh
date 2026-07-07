@echo off
setlocal

echo ================================================
echo  Adicionando "Abrir com o Code" ao menu de contexto
echo  (aparece direto no 1o clique, sem "Mostrar mais opcoes")
echo ================================================
echo.
echo  IMPORTANTE: execute com DUPLO-CLIQUE normal.
echo  NAO use "Executar como administrador" (a mudanca e do
echo  seu usuario/HKCU e nao precisa de admin).
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$exe = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'; " ^
    "if (-not (Test-Path $exe)) { $exe = 'C:\Program Files\Microsoft VS Code\Code.exe' }; " ^
    "if (-not (Test-Path $exe)) { Write-Host 'ERRO: Code.exe nao encontrado. Ajuste o caminho no script.' -ForegroundColor Red; exit 1 }; " ^
    "New-Item -Path 'HKCU:\Software\Classes\Directory\shell\VSCode' -Force | Out-Null; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\Directory\shell\VSCode' -Name '(Default)' -Value 'Abrir com o Code'; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\Directory\shell\VSCode' -Name 'Icon' -Value $exe; " ^
    "New-Item -Path 'HKCU:\Software\Classes\Directory\shell\VSCode\command' -Force | Out-Null; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\Directory\shell\VSCode\command' -Name '(Default)' -Value ('\"' + $exe + '\" \"%%V\"'); " ^
    "New-Item -Path 'HKCU:\Software\Classes\Directory\Background\shell\VSCode' -Force | Out-Null; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\Directory\Background\shell\VSCode' -Name '(Default)' -Value 'Abrir com o Code'; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\Directory\Background\shell\VSCode' -Name 'Icon' -Value $exe; " ^
    "New-Item -Path 'HKCU:\Software\Classes\Directory\Background\shell\VSCode\command' -Force | Out-Null; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\Directory\Background\shell\VSCode\command' -Name '(Default)' -Value ('\"' + $exe + '\" \"%%V\"'); " ^
    "New-Item -Path 'HKCU:\Software\Classes\*\shell\VSCode' -Force | Out-Null; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\*\shell\VSCode' -Name '(Default)' -Value 'Abrir com o Code'; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\*\shell\VSCode' -Name 'Icon' -Value $exe; " ^
    "New-Item -Path 'HKCU:\Software\Classes\*\shell\VSCode\command' -Force | Out-Null; " ^
    "Set-ItemProperty -Path 'HKCU:\Software\Classes\*\shell\VSCode\command' -Name '(Default)' -Value ('\"' + $exe + '\" \"%%1\"'); " ^
    "Write-Host 'Registro atualizado com sucesso.' -ForegroundColor Green"

if %errorlevel% neq 0 (
    echo.
    echo Ocorreu um erro ao atualizar o registro. Verifique a mensagem acima.
    pause
    exit /b 1
)

echo.
echo Forcando o menu classico (para o item aparecer no 1o clique)...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1

echo.
echo Reiniciando o Explorer para aplicar as mudancas...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo.
echo ================================================
echo  Concluido! Clique com o botao direito em qualquer
echo  arquivo ou pasta: "Abrir com o Code" aparece direto,
echo  sem precisar de "Mostrar mais opcoes".
echo ================================================
echo.
echo  Para desfazer (voltar ao menu do Windows 11):
echo    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
echo    e reinicie o Explorer.
echo.
pause
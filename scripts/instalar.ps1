# ============================================================
# edu-session | instalador da maquina
# Rodar UMA VEZ por notebook como ADMINISTRADOR.
#
# O que ele faz:
#   1. Pergunta o numero do notebook e batiza a maquina (NB-00/CB-00)
#   2. Copia o logon.ps1 para pasta protegida (aluno nao mexe)
#     ja preenchendo o IP do servidor
#   3. Registra chave Run no HKLM: a cada logon, o Windows lanca o
#      launcher invisivel no contexto do usuario que entrou
#
# Requisitos: logon.ps1 na mesma pasta deste arquivo.
# ============================================================

#Requires -RunAsAdministrator

$tag = "[edu-session]"

Write-Host ""
Write-Host "=== Instalador edu-session ===" -ForegroundColor White
Write-Host ""

# ------------------------------------------------------------
# perguntas de configuracao
# ------------------------------------------------------------
$ipServidor = Read-Host "IP do servidor (ex: 192.168.0.10)"
if ([string]::IsNullOrWhiteSpace($ipServidor)) {
    Write-Host "$tag IP obrigatorio, abortando." -ForegroundColor Red
    exit 1
}

$numero = Read-Host "Numero do notebook (ex: NB-23 ou CB-05)"
if ($numero -notmatch '^(NB|CB)-\d{2}$') {
    Write-Host "$tag padrao invalido. Use NB-00 ou CB-00." -ForegroundColor Red
    exit 1
}

$pastaDestino = "C:\Program Files\edu-session"
$arquivoLogon = Join-Path $pastaDestino "logon.ps1"

# ------------------------------------------------------------
# teste rapido de alcance do servidor (nao bloqueia se falhar)
# ------------------------------------------------------------
$conexao = Test-NetConnection -ComputerName $ipServidor -Port 3000 -WarningAction SilentlyContinue
if ($conexao.TcpTestSucceeded) {
    Write-Host "$tag servidor acessivel em $ipServidor`:3000" -ForegroundColor Green
}
else {
    Write-Host "$tag aviso: nao alcancei o servidor agora, mas vou continuar." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# 1. batizar a maquina com o numero padrao
# ------------------------------------------------------------
if ($env:COMPUTERNAME -ne $numero) {
    try {
        Rename-Computer -NewName $numero -Force -ErrorAction Stop
        Write-Host "$tag maquina renomeada para '$numero' (vale apos reiniciar)" -ForegroundColor Yellow
    }
    catch {
        Write-Host "$tag falhou ao renomear: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "$tag maquina ja se chama '$numero', sem necessidade de renomear" -ForegroundColor DarkGray
}

# ------------------------------------------------------------
# 2. copiar logon.ps1 e launcher.vbs p/ pasta protegida, com o IP certo
# ------------------------------------------------------------
try {
    New-Item -ItemType Directory -Path $pastaDestino -Force -ErrorAction Stop | Out-Null

    $origem   = Join-Path $PSScriptRoot "logon.ps1"
    $conteudo = (Get-Content $origem -Raw) -replace 'COLOQUE_O_IP_AQUI', $ipServidor
    Set-Content -Path $arquivoLogon -Value $conteudo -Encoding UTF8 -ErrorAction Stop

    Copy-Item (Join-Path $PSScriptRoot "launcher.vbs") `
              (Join-Path $pastaDestino "launcher.vbs") -Force -ErrorAction Stop

    Write-Host "$tag script de logon instalado em '$arquivoLogon'" -ForegroundColor Green
}
catch {
    Write-Host "$tag falhou ao copiar logon.ps1: $_" -ForegroundColor Red
    Write-Host "$tag confirme que logon.ps1 esta na mesma pasta deste instalador." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 3. chave Run no HKLM: dispara o launcher a cada logon
# ------------------------------------------------------------
# Por que Run key e nao tarefa agendada? Tarefas com principal de
# grupo falham em disparar para contas AzureAD em algumas maquinas.
# A chave Run dispara para QUALQUER usuario que logar, roda no
# contexto dele e so pode ser editada por administrador (HKLM).
$chaveRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$valorEdu = 'wscript.exe "C:\Program Files\edu-session\launcher.vbs"'

try {
    # limpa instalacoes antigas baseadas em tarefa agendada, se existirem
    Unregister-ScheduledTask -TaskName "EduSessionLogon" -Confirm:$false -ErrorAction SilentlyContinue

    New-ItemProperty -Path $chaveRun `
        -Name "EduSession" `
        -Value $valorEdu `
        -PropertyType String `
        -Force -ErrorAction Stop | Out-Null

    Write-Host "$tag registro de logon gravado (roda a cada logon, invisivel)" -ForegroundColor Green
}
catch {
    Write-Host "$tag falhou ao gravar a chave de logon: $_" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# resumo
# ------------------------------------------------------------
Write-Host ""
Write-Host "$tag instalacao concluida!" -ForegroundColor White
if ($env:COMPUTERNAME -ne $numero) {
    Write-Host "$tag REINICIE a maquina para aplicar o nome '$numero' e gerar o primeiro registro." -ForegroundColor Yellow
}
else {
    Write-Host "$tag deslogue e logue novamente para gerar um registro." -ForegroundColor Yellow
}

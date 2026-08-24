# ============================================================
# edu-session | instalador da maquina
# Rodar UMA VEZ por notebook como ADMINISTRADOR.
#
# O que ele faz:
#   1. Pergunta o numero do notebook e batiza a maquina (NB-00/CB-00)
#   2. Copia o logon.ps1 para pasta protegida (aluno nao mexe)
#     ja preenchendo o IP do servidor
#   3. Registra tarefa agendada que roda no contexto do usuario
#      a cada logon, sem janela, funciona na bateria
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
$nomeTarefa   = "EduSessionLogon"

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
# 2. copiar logon.ps1 para pasta protegida, com o IP certo
# ------------------------------------------------------------
try {
    New-Item -ItemType Directory -Path $pastaDestino -Force -ErrorAction Stop | Out-Null

    $origem   = Join-Path $PSScriptRoot "logon.ps1"
    $conteudo = (Get-Content $origem -Raw) -replace 'COLOQUE_O_IP_AQUI', $ipServidor
    Set-Content -Path $arquivoLogon -Value $conteudo -Encoding UTF8 -ErrorAction Stop

    Write-Host "$tag script de logon instalado em '$arquivoLogon'" -ForegroundColor Green
}
catch {
    Write-Host "$tag falhou ao copiar logon.ps1: $_" -ForegroundColor Red
    Write-Host "$tag confirme que logon.ps1 esta na mesma pasta deste instalador." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 3. tarefa agendada: roda a cada logon, como SYSTEM, oculta
# ------------------------------------------------------------
$acao = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$arquivoLogon`""

$gatilho = New-ScheduledTaskTrigger -AtLogOn

$config = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
            -MultipleInstances IgnoreNew

# Roda no CONTEXTO do usuario que acabou de logar.
# Usa o SID universal do grupo "Usuarios" (S-1-5-32-545) porque
# o NOME do grupo muda conforme o idioma do Windows ("BUILTIN\Users"
# nao existe num Windows pt-BR); o SID vale em qualquer lingua.
$principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -RunLevel Limited

try {
    # -ErrorAction Stop converte erro non-terminating em terminating,
    # garantindo que falha aqui CAIA NO CATCH em vez de passar reto.
    Register-ScheduledTask `
        -TaskName $nomeTarefa `
        -Action $acao `
        -Trigger $gatilho `
        -Settings $config `
        -Principal $principal `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Host "$tag tarefa '$nomeTarefa' registrada (ao logar, no contexto do usuario)" -ForegroundColor Green
}
catch {
    Write-Host "$tag falhou ao registrar a tarefa: $_" -ForegroundColor Red
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

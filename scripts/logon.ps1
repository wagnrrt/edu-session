# ============================================================
# edu-session | registro automatico de logon
# Roda silenciosamente no inicio da sessao do aluno.
# Falha de rede/servidor NUNCA deve incomodar o usuario,
# mas TUDO fica registrado em arquivo de log p/ diagnostico.
# ============================================================

$servidor = "http://COLOQUE_O_IP_AQUI:3000/logins"

# caixa-preta: grava eventos p/ investigar problemas depois.
# usa ProgramData (todas as contas escrevem); se nao existir,
# cai pro TEMP da sessao atual.
$pastaLog = "C:\ProgramData\edu-session"
if (-not (Test-Path $pastaLog)) { $pastaLog = $env:TEMP }
$arquivoLog = Join-Path $pastaLog "log.txt"

function Registrar([string]$mensagem) {
    try {
        $momento = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $arquivoLog -Value "$momento | $mensagem" -ErrorAction Stop
    }
    catch {
        # sem log nem ha como reclamar dele; silencio total
    }
}

Registrar "=== inicio do script ==="

try {
    # RA do aluno: vem do UPN da conta AzureAD
    $email    = (whoami /upn).Trim()
    Registrar "upn obtido: $email"

    # Nome de exibicao da conta
    $nome     = $env:USERNAME.Trim()

    # Identificacao da maquina (padrao combinado: NB-00 / CB-00)
    $notebook = $env:COMPUTERNAME
    Registrar "maquina: $notebook"

    $corpo = @{
        email    = $email
        name     = $nome
        notebook = $notebook
    } | ConvertTo-Json

    Registrar "enviando POST para $servidor"

    $resposta = Invoke-RestMethod `
        -Uri $servidor `
        -Method Post `
        -Body $corpo `
        -ContentType "application/json" `
        -TimeoutSec 5

    Registrar "sucesso: $($resposta | ConvertTo-Json -Compress)"
}
catch {
    # sem rede, servidor desligado ou qualquer outro problema:
    # silencio total NA TELA, mas o erro fica gravado na caixa-preta.
    Registrar "FALHOU: $($_.Exception.Message)"
}

Registrar "=== fim ==="

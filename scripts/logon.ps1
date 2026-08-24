# ============================================================
# edu-session | registro automatico de logon
# Roda silenciosamente no inicio da sessao do aluno.
# Falha de rede/servidor NUNCA deve incomodar o usuario.
# ============================================================

$servidor = "http://COLOQUE_O_IP_AQUI:3000/logins"

try {
    # RA do aluno: vem do UPN da conta AzureAD (ex: 1234567@aluno.educacao.sp.gov.br)
    $email    = (whoami /upn).Trim()

    # Nome de exibicao da conta (ex: MARIAEDUARDAGARCIASA)
    $nome     = $env:USERNAME.Trim()

    # Identificacao da maquina (padrao combinado: NB-00 / CB-00)
    $notebook = $env:COMPUTERNAME

    $corpo = @{
        email    = $email
        name     = $nome
        notebook = $notebook
    } | ConvertTo-Json

    Invoke-RestMethod `
        -Uri $servidor `
        -Method Post `
        -Body $corpo `
        -ContentType "application/json" `
        -TimeoutSec 3 | Out-Null
}
catch {
    # Sem rede, servidor desligado ou qualquer outro problema:
    # silencio total. O aluno nao pode ver nada estranho no login.
}

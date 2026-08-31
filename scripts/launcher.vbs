' ============================================================
' edu-session | lancador invisivel
' O Task Scheduler chama este .vbs, e ele roda o logon.ps1
' com estilo de janela 0 = sem console, nem sequer uma piscada.
' ============================================================
CreateObject("WScript.Shell").Run _
    "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Program Files\edu-session\logon.ps1""", 0, False

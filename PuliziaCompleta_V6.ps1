# ============================
#   LOGGING AVANZATO (TIBERIO EDITION)
# ============================

# Percorso file log
$Global:LogFile = "$PSScriptRoot\TiberioEdition.log"

function Write-Log {
    param([string]$Message)

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$timestamp] $Message"

    # Console
    Write-Host $formatted

    # File log
    try {
        Add-Content -Path $Global:LogFile -Value $formatted -Encoding UTF8
    } catch {
        Write-Host "[ERRORE LOG] Impossibile scrivere nel file log."
    }
}

# ============================
#   AUTO-UPDATE TIBERIO EDITION V6
# ============================

# VERSIONE LOCALE SCRIPT
$VersioneLocale = "6.2.0"

# CHANGELOG LOCALE (mostrato solo se c'è un update)
$ChangelogLocale = @"
- Prima versione con Auto-Update integrato
- Modulo di pulizia completo V6
"@

# LINK RAW GITHUB (TESTATO)
$UrlScriptRemoto = "https://raw.githubusercontent.com/M4r10685/TiberioEditionV6/refs/heads/main/PuliziaCompleta_V6.ps1"

# PERCORSO SCRIPT LOCALE
$ScriptPath = $MyInvocation.MyCommand.Path
$BackupPath = "$ScriptPath.bak"

# FUNZIONE: Mostra popup semplice (se possibile)
function Mostra-Popup {
    param(
        [string]$Titolo,
        [string]$Messaggio
    )
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        [System.Windows.MessageBox]::Show($Messaggio, $Titolo, 'OK', 'Information') | Out-Null
    } catch {
        Write-Host "$Titolo - $Messaggio"
    }
}

try {
    Write-Log "Controllo aggiornamenti..."

    # Scarica contenuto remoto
    $RispostaRemota = Invoke-WebRequest -Uri $UrlScriptRemoto -UseBasicParsing -ErrorAction Stop
    $TestoRemoto = $RispostaRemota.Content

    # Estrae versione remota
    if ($TestoRemoto -match '\$VersioneLocale\s*=\s*"([^"]+)"') {
        $VersioneRemota = $matches[1]
        Write-Log "Versione remota trovata: $VersioneRemota"
    } else {
        Write-Log "Impossibile determinare la versione remota."
        return
    }

    # Se versione uguale → esci dal modulo
    if ($VersioneLocale -eq $VersioneRemota) {
        Write-Log "Lo script è già aggiornato alla versione $VersioneLocale."
        return
    }

    # Se versione diversa → mostra info update
    Write-Log "Nuova versione disponibile: $VersioneRemota (attuale: $VersioneLocale)"

    # Estrae changelog remoto (se presente)
    $ChangelogRemoto = $null
    if ($TestoRemoto -match '\$ChangelogLocale\s*=\s*@\"([\s\S]*?)\"@') {
        $ChangelogRemoto = $matches[1].Trim()
    }

    # Testo popup
    $MessaggioUpdate = "È disponibile una nuova versione dello script.`n`nVersione attuale: $VersioneLocale`nNuova versione: $VersioneRemota"
    if ($ChangelogRemoto) {
        $MessaggioUpdate += "`n`nChangelog:`n$ChangelogRemoto"
    }

    # Popup informativo
    Mostra-Popup -Titolo "Aggiornamento disponibile" -Messaggio $MessaggioUpdate

    # Backup
    try {
        Copy-Item -Path $ScriptPath -Destination $BackupPath -Force
        Write-Log "Backup creato: $BackupPath"
    } catch {
        Write-Log "Impossibile creare il backup: $($_.Exception.Message)"
        Mostra-Popup -Titolo "Errore backup" -Messaggio "Impossibile creare il backup dello script. Aggiornamento annullato."
        return
    }

    # Aggiornamento file
    try {
        Set-Content -Path $ScriptPath -Value $TestoRemoto -Force -Encoding UTF8
        Write-Log "Script aggiornato alla versione $VersioneRemota."
    } catch {
        Write-Log "Errore durante la scrittura del file aggiornato: $($_.Exception.Message)"
        Mostra-Popup -Titolo "Errore aggiornamento" -Messaggio "Errore durante l'aggiornamento. Verrà ripristinato il backup."
        # Rollback
        if (Test-Path $BackupPath) {
            Copy-Item -Path $BackupPath -Destination $ScriptPath -Force
            Write-Log "Ripristinato il backup dello script."
        }
        return
    }

    # Popup finale + riavvio
    Mostra-Popup -Titolo "Aggiornamento completato" -Messaggio "Lo script è stato aggiornato alla versione $VersioneRemota e verrà riavviato."
    Write-Log "Riavvio dello script aggiornato..."
    Start-Sleep -Milliseconds 300
    Start-Process powershell.exe -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"") -WindowStyle Normal
    exit
}
catch {
    Write-Log "Errore durante il controllo aggiornamenti: $($_.Exception.Message)"
}

# ============================
#   CLEAN-PATH (TIBERIO EDITION)
# ============================
function Clean-Path {
    param(
        [string]$Path,
        [string]$Descrizione,
        [switch]$OldOnly,
        [int]$Days = 7
    )

    Write-Log "Pulizia: $Descrizione ($Path)"

    if (!(Test-Path $Path)) { return 0 }

    $freed = 0

    try {
        $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            if ($OldOnly) {
                if ($item.LastWriteTime -lt (Get-Date).AddDays(-$Days)) {
                    $freed += $item.Length
                    Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                }
            } else {
                $freed += $item.Length
                Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    return $freed
}

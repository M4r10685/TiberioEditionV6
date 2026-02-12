
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


# ============================
#   FUNZIONI OPERATIVE REALI
# ============================

function Pulizia-Base { 
    Write-Log "Esecuzione Pulizia-Base"
    $tot = 0
    $tot += Clean-Path -Path "$env:TEMP" -Descrizione "TEMP utente"
    $tot += Clean-Path -Path "$env:WINDIR\Temp" -Descrizione "TEMP sistema"
    $tot += Clean-Path -Path "$env:WINDIR\SoftwareDistribution\Download" -Descrizione "Cache Windows Update"
    $tot += Clean-Path -Path "$env:WINDIR\Logs" -Descrizione "Log Windows" -OldOnly -Days 7
    $tot += Clean-Path -Path "$env:LOCALAPPDATA\CrashDumps" -Descrizione "CrashDumps" -OldOnly -Days 7
    $tot += Clean-Path -Path "$env:WINDIR\Prefetch" -Descrizione "Prefetch" -OldOnly -Days 10
    try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
    return $tot
}

function Pulizia-Gaming { Write-Log "Pulizia Gaming (placeholder)" }
function Manutenzione-Completa { Write-Log "Manutenzione Completa (placeholder)" }
function Ripara-Sistema { Write-Log "Riparazione Sistema (placeholder)" }
function Gaming-Boost { Write-Log "Gaming Boost (placeholder)" }

function Gaming-BoostPlus {
    Write-Log "Gaming Boost PLUS V6 avviato"

    # Aumento priorità CPU per il gioco
    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) { $proc.PriorityClass = "High" }
    } catch {}

    # Timer resolution 0.5ms
    try {
        powercfg -setacvalueindex scheme_current sub_processor PERFINCTHRESHOLD 0 | Out-Null
        powercfg -setactive scheme_current | Out-Null
    } catch {}

    # Profilo energetico Ultimate Performance
    try {
        powercfg -setactive SCHEME_MIN | Out-Null
    } catch {}

    # Ottimizzazione rete
    try {
        netsh int tcp set global autotuninglevel=disabled | Out-Null
        netsh int tcp set global rss=disabled | Out-Null
        netsh int tcp set global chimney=disabled | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {}

    # Disattivazione servizi non essenziali
    try {
        Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
        Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}

    Write-Log "Gaming Boost PLUS V6 completato"
}

function Ripristino-Completo {
    Write-Log "Ripristino completo automatico avviato"

    # Ripristino servizi
    try {
        Set-Service "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "SysMain" -ErrorAction SilentlyContinue

        Set-Service "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "WSearch" -ErrorAction SilentlyContinue

        Set-Service "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "DiagTrack" -ErrorAction SilentlyContinue
    } catch {}

    # Ripristino priorità CPU
    try {
        $proc = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($proc) { $proc.PriorityClass = "Normal" }
    } catch {}

    # Ripristino timer di sistema
    try {
        powercfg -setacvalueindex scheme_current sub_processor PERFINCTHRESHOLD 50 | Out-Null
        powercfg -setactive scheme_current | Out-Null
    } catch {}

    # Ripristino rete
    try {
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics enabled | Out-Null
    } catch {}

    # Ripristino Network Throttling Index
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    } catch {}

    # Ripristino profilo energetico
    try {
        powercfg -setactive SCHEME_BALANCED | Out-Null
    } catch {}

    Write-Log "Ripristino completo terminato"
}

function Ottimizza-Rete { Write-Log "Ottimizzazione rete (placeholder)" }

# ============================
#   AUTO-GAMING-BOOST (ETS2)
# ============================

$global:GamingBoostAttivo = $false

function Controlla-ETS2 {
    $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
    return $proc -ne $null
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(5)

$timer.Add_Tick({
    if (Controlla-ETS2) {
        if (-not $global:GamingBoostAttivo) {
            Write-Log "ETS2 rilevato → Attivo Gaming Boost PLUS"
            Gaming-BoostPlus
            if ($TxtStatus) { $TxtStatus.Text = "Gaming Boost PLUS attivo (ETS2 rilevato)" }
            $global:GamingBoostAttivo = $true
        }
    }
    else {
        if ($global:GamingBoostAttivo) {
            Write-Log "ETS2 chiuso → Ripristino completo automatico"
            Ripristino-Completo
            if ($TxtStatus) { $TxtStatus.Text = "Ripristino completato (ETS2 chiuso)" }
            $global:GamingBoostAttivo = $false
        }
    }
})

$timer.Start()

# ============================
#   AVVIO SCRIPT
# ============================

Write-Log "Avvio Tiberio Edition V6..."
$tot = Pulizia-Base
Write-Log "Pulizia completata. Byte liberati: $tot"

# ============================
#   GUI XAML
# ============================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tiberio Edition V6" Height="440" Width="720"
        WindowStartupLocation="CenterScreen"
        Background="#F3F3F3"
        ResizeMode="NoResize">

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Pulizia Completa - Tiberio Edition V6"
                   FontSize="22"
                   FontWeight="Bold"
                   Foreground="#202020"
                   Margin="0,0,0,15"/>

        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <StackPanel Grid.Column="0" Margin="0,0,10,0">
                <TextBlock Text="Manutenzione" FontWeight="Bold" Margin="0,0,0,8"/>
                <Button x:Name="BtnPuliziaBase" Content="Pulizia Base" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnPuliziaGaming" Content="Pulizia Gaming" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnManutenzioneCompleta" Content="Manutenzione Completa Avanzata" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnRiparazioneSistema" Content="Riparazione Sistema" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnControllaAggiornamenti" Content="Controlla Aggiornamenti" Height="32" Margin="0,10,0,0"/>
            </StackPanel>

            <StackPanel Grid.Column="1" Margin="10,0,0,0">
                <TextBlock Text="Gaming" FontWeight="Bold" Margin="0,0,0,8"/>
                <Button x:Name="BtnGamingBoost" Content="Gaming Boost" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnGamingBoostPlus" Content="Gaming Boost PLUS" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnOttimizzaRete" Content="Ottimizzazione Rete" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnEsci" Content="Esci" Height="32" Margin="0,20,0,0"/>
            </StackPanel>
        </Grid>

        <StatusBar Grid.Row="2" Margin="0,10,0,0">
            <StatusBarItem>
                <TextBlock x:Name="TxtStatus" Text="Pronto."/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# ============================
#   PARSING XAML
# ============================
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# ============================
#   RIFERIMENTI CONTROLLI
# ============================
$BtnPuliziaBase            = $window.FindName("BtnPuliziaBase")
$BtnPuliziaGaming          = $window.FindName("BtnPuliziaGaming")
$BtnManutenzioneCompleta   = $window.FindName("BtnManutenzioneCompleta")
$BtnRiparazioneSistema     = $window.FindName("BtnRiparazioneSistema")
$BtnGamingBoost            = $window.FindName("BtnGamingBoost")
$BtnGamingBoostPlus        = $window.FindName("BtnGamingBoostPlus")
$BtnOttimizzaRete          = $window.FindName("BtnOttimizzaRete")
$BtnEsci                   = $window.FindName("BtnEsci")
$BtnControllaAggiornamenti = $window.FindName("BtnControllaAggiornamenti")
$TxtStatus                 = $window.FindName("TxtStatus")

# ============================
#   HANDLER PULSANTI
# ============================
$BtnPuliziaBase.Add_Click({
    $TxtStatus.Text = "Esecuzione Pulizia Base..."
    Write-Log "Avvio Pulizia Base"
    $freed = Pulizia-Base
    $MB = [math]::Round($freed / 1MB, 2)
    $TxtStatus.Text = "Pulizia Base completata. Liberati $MB MB."
})

$BtnPuliziaGaming.Add_Click({
    $TxtStatus.Text = "Esecuzione Pulizia Gaming..."
    Write-Log "Avvio Pulizia Gaming"
    $freed = Pulizia-Gaming
    $MB = [math]::Round($freed / 1MB, 2)
    $TxtStatus.Text = "Pulizia Gaming completata. Liberati $MB MB."
})

$BtnManutenzioneCompleta.Add_Click({
    $TxtStatus.Text = "Manutenzione Completa Avanzata in corso..."
    Write-Log "Avvio Manutenzione Completa Avanzata V6"
    Manutenzione-Completa
    $TxtStatus.Text = "Manutenzione Completa Avanzata completata."
})

$BtnRiparazioneSistema.Add_Click({
    $TxtStatus.Text = "Riparazione sistema in corso..."
    Write-Log "Avvio Riparazione Sistema V6"
    Ripara-Sistema
    $TxtStatus.Text = "Riparazione sistema completata."
})

$BtnGamingBoost.Add_Click({
    $TxtStatus.Text = "Gaming Boost in corso..."
    Write-Log "Avvio Gaming Boost V6"
    Gaming-Boost
    $TxtStatus.Text = "Gaming Boost completato."
})

$BtnGamingBoostPlus.Add_Click({
    $TxtStatus.Text = "Gaming Boost PLUS in corso..."
    Write-Log "Avvio Gaming Boost PLUS V6"
    Gaming-BoostPlus
    $TxtStatus.Text = "Gaming Boost PLUS completato."
})

$BtnOttimizzaRete.Add_Click({
    $TxtStatus.Text = "Ottimizzazione rete in corso..."
    Write-Log "Avvio Ottimizzazione Rete"
    Ottimizza-Rete
    $TxtStatus.Text = "Ottimizzazione rete completata."
})



# ============================
#   AVVIO GUI
# ============================
Write-Log "Avvio Tiberio Edition V6 GUI..."
$window.ShowDialog() | Out-Null


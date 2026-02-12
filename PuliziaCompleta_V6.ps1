# ============================
#   LOGGING AVANZATO (TIBERIO EDITION)
# ============================

$Global:LogFile = "$PSScriptRoot\TiberioEdition.log"

function Write-Log {
    param([string]$Message)

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$timestamp] $Message"

    Write-Host $formatted

    try {
        Add-Content -Path $Global:LogFile -Value $formatted -Encoding UTF8
    } catch {
        Write-Host "[ERRORE LOG] Impossibile scrivere nel file log."
    }
}

# ============================
#   AUTO-UPDATE TIBERIO EDITION V6 (GITHUB)
# ============================

$VersioneLocale = "6.2.0"

$ChangelogLocale = @"
- Prima versione con Auto-Update integrato
- Modulo di pulizia completo V6
- Modalità Full Power (Gaming + Rete + Ripristino)
"@

$UrlScriptRemoto = "https://raw.githubusercontent.com/M4r10685/TiberioEditionV6/refs/heads/main/PuliziaCompleta_V6.ps1"

$ScriptPath = $MyInvocation.MyCommand.Path
$BackupPath = "$ScriptPath.bak"

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

    $RispostaRemota = Invoke-WebRequest -Uri $UrlScriptRemoto -UseBasicParsing -ErrorAction Stop
    $TestoRemoto = $RispostaRemota.Content

    if ($TestoRemoto -match '\$VersioneLocale\s*=\s*"([^"]+)"') {
        $VersioneRemota = $matches[1]
        Write-Log "Versione remota trovata: $VersioneRemota"
    } else {
        Write-Log "Impossibile determinare la versione remota."
        return
    }

    if ($VersioneLocale -eq $VersioneRemota) {
        Write-Log "Lo script è già aggiornato alla versione $VersioneLocale."
        # Nessun update → prosegue con il resto dello script
    } else {
        Write-Log "Nuova versione disponibile: $VersioneRemota (attuale: $VersioneLocale)"

        $ChangelogRemoto = $null
        if ($TestoRemoto -match '\$ChangelogLocale\s*=\s*@\"([\s\S]*?)\"@') {
            $ChangelogRemoto = $matches[1].Trim()
        }

        $MessaggioUpdate = "È disponibile una nuova versione dello script.`n`nVersione attuale: $VersioneLocale`nNuova versione: $VersioneRemota"
        if ($ChangelogRemoto) {
            $MessaggioUpdate += "`n`nChangelog:`n$ChangelogRemoto"
        }

        Mostra-Popup -Titolo "Aggiornamento disponibile" -Messaggio $MessaggioUpdate

        Copy-Item -Path $ScriptPath -Destination $BackupPath -Force
        Write-Log "Backup creato: $BackupPath"

        Set-Content -Path $ScriptPath -Value $TestoRemoto -Force -Encoding UTF8
        Write-Log "Script aggiornato alla versione $VersioneRemota."

        Mostra-Popup -Titolo "Aggiornamento completato" -Messaggio "Lo script è stato aggiornato alla versione $VersioneRemota e verrà riavviato."
        Write-Log "Riavvio dello script aggiornato..."

        Start-Sleep -Milliseconds 300
        Start-Process powershell.exe -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$ScriptPath`"") -WindowStyle Normal
        exit
    }
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

function Pulizia-Gaming {
    Write-Log "Esecuzione Pulizia-Gaming"
    $tot = 0

    # Cache giochi comuni (placeholder, puoi aggiungere percorsi specifici)
    $percorsiGaming = @(
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\NVIDIA\GLCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
    )

    foreach ($p in $percorsiGaming) {
        $tot += Clean-Path -Path $p -Descrizione "Cache Gaming: $p" -OldOnly -Days 5
    }

    return $tot
}

function Manutenzione-Completa {
    Write-Log "Manutenzione Completa Avanzata avviata"

    $tot = Pulizia-Base
    Write-Log "Pulizia Base completata in Manutenzione Completa. Byte liberati: $tot"

    $totGaming = Pulizia-Gaming
    Write-Log "Pulizia Gaming completata in Manutenzione Completa. Byte liberati: $totGaming"

    # Placeholder per eventuali moduli extra (defrag SSD escluso, solo TRIM)
    try {
        Write-Log "Esecuzione TRIM SSD (se supportato)"
        Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    Write-Log "Manutenzione Completa Avanzata terminata"
}

function Ripara-Sistema {
    Write-Log "Riparazione Sistema avviata"

    # Esempio: DISM e SFC in modalità sicura (solo log, non blocca GUI)
    try {
        Write-Log "Avvio DISM /ScanHealth (in background)"
        Start-Process -FilePath "dism.exe" -ArgumentList "/Online","/Cleanup-Image","/ScanHealth" -WindowStyle Hidden
    } catch {
        Write-Log "Errore avvio DISM: $($_.Exception.Message)"
    }

    try {
        Write-Log "Avvio SFC /SCANNOW (in background)"
        Start-Process -FilePath "sfc.exe" -ArgumentList "/SCANNOW" -WindowStyle Hidden
    } catch {
        Write-Log "Errore avvio SFC: $($_.Exception.Message)"
    }

    Write-Log "Riparazione Sistema avviata (controlla separatamente l'esito nei log di sistema)"
}

function Gaming-Boost {
    Write-Log "Gaming Boost V6 avviato"

    # Priorità CPU per ETS2 se già avviato
    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) {
            $proc.PriorityClass = "AboveNormal"
            Write-Log "Impostata priorità AboveNormal per eurotrucks2"
        }
    } catch {}

    # Disattivazione ottimizzazioni di risparmio energia su scheda di rete (placeholder generico)
    try {
        Write-Log "Ottimizzazione base rete (TCP)"
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {}

    Write-Log "Gaming Boost V6 completato"
}

function Gaming-BoostPlus {
    Write-Log "Gaming Boost PLUS V6 avviato"

    # Aumento priorità CPU per il gioco
    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) {
            $proc.PriorityClass = "High"
            Write-Log "Impostata priorità High per eurotrucks2"
        }
    } catch {}

    # Timer resolution / soglia performance (approccio powercfg)
    try {
        Write-Log "Impostazione Timer/Performance Threshold a 0 (massime prestazioni)"
        powercfg -setacvalueindex scheme_current sub_processor PERFINCTHRESHOLD 0 | Out-Null
        powercfg -setactive scheme_current | Out-Null
    } catch {}

    # Profilo energetico High Performance (SCHEME_MIN)
    try {
        Write-Log "Impostazione profilo energetico High Performance (SCHEME_MIN)"
        powercfg -setactive SCHEME_MIN | Out-Null
    } catch {}

    # Ottimizzazione rete aggressiva
    try {
        Write-Log "Ottimizzazione rete avanzata (Gaming Boost PLUS)"
        netsh int tcp set global autotuninglevel=disabled | Out-Null
        netsh int tcp set global rss=disabled | Out-Null
        netsh int tcp set global chimney=disabled | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {}

    # Disattivazione servizi non essenziali
    try {
        Write-Log "Disattivazione servizi non essenziali (SysMain, WSearch, DiagTrack)"

        Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
        Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}

    # Network Throttling Index → disabilitato (0xffffffff)
    try {
        Write-Log "Impostazione NetworkThrottlingIndex a 0xffffffff (disabilitato)"
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
    } catch {}

    Write-Log "Gaming Boost PLUS V6 completato"
}

function Ripristino-Completo {
    Write-Log "Ripristino completo automatico avviato"

    # Ripristino servizi
    try {
        Write-Log "Ripristino servizi SysMain, WSearch, DiagTrack"

        Set-Service "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "SysMain" -ErrorAction SilentlyContinue

        Set-Service "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "WSearch" -ErrorAction SilentlyContinue

        Set-Service "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "DiagTrack" -ErrorAction SilentlyContinue
    } catch {}

    # Ripristino priorità CPU
    try {
        Write-Log "Ripristino priorità CPU per explorer"
        $proc = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($proc) { $proc.PriorityClass = "Normal" }
    } catch {}

    # Ripristino timer di sistema
    try {
        Write-Log "Ripristino Performance Threshold a 50"
        powercfg -setacvalueindex scheme_current sub_processor PERFINCTHRESHOLD 50 | Out-Null
        powercfg -setactive scheme_current | Out-Null
    } catch {}

    # Ripristino rete
    try {
        Write-Log "Ripristino impostazioni rete TCP"
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics enabled | Out-Null
    } catch {}

    # Ripristino Network Throttling Index
    try {
        Write-Log "Ripristino NetworkThrottlingIndex a 10"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    } catch {}

    # Ripristino profilo energetico bilanciato
    try {
        Write-Log "Ripristino profilo energetico Bilanciato (SCHEME_BALANCED)"
        powercfg -setactive SCHEME_BALANCED | Out-Null
    } catch {}

    Write-Log "Ripristino completo terminato"
}

function Ottimizza-Rete {
    Write-Log "Ottimizzazione rete avanzata avviata"

    try {
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {
        Write-Log "Errore durante ottimizzazione rete: $($_.Exception.Message)"
    }

    try {
        Write-Log "Impostazione SystemResponsiveness a 10 (profilo gaming bilanciato)"
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "SystemResponsiveness" -Value 10 -ErrorAction SilentlyContinue
    } catch {}

    Write-Log "Ottimizzazione rete avanzata completata"
}

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
#   AVVIO SCRIPT (PRE-GUI)
# ============================

Write-Log "Avvio Tiberio Edition V6 (fase pre-GUI)..."
$tot = Pulizia-Base
Write-Log "Pulizia Base iniziale completata. Byte liberati: $tot"

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
    Write-Log "Avvio Pulizia Base (da GUI)"
    $freed = Pulizia-Base
    $MB = [math]::Round($freed / 1MB, 2)
    $TxtStatus.Text = "Pulizia Base completata. Liberati $MB MB."
})

$BtnPuliziaGaming.Add_Click({
    $TxtStatus.Text = "Esecuzione Pulizia Gaming..."
    Write-Log "Avvio Pulizia Gaming (da GUI)"
    $freed = Pulizia-Gaming
    $MB = [math]::Round($freed / 1MB, 2)
    $TxtStatus.Text = "Pulizia Gaming completata. Liberati $MB MB."
})

$BtnManutenzioneCompleta.Add_Click({
    $TxtStatus.Text = "Manutenzione Completa Avanzata in corso..."
    Write-Log "Avvio Manutenzione Completa Avanzata V6 (da GUI)"
    Manutenzione-Completa
    $TxtStatus.Text = "Manutenzione Completa Avanzata completata."
})

$BtnRiparazioneSistema.Add_Click({
    $TxtStatus.Text = "Riparazione sistema in corso..."
    Write-Log "Avvio Riparazione Sistema V6 (da GUI)"
    Ripara-Sistema
    $TxtStatus.Text = "Riparazione sistema avviata (controlla log di sistema)."
})

$BtnGamingBoost.Add_Click({
    $TxtStatus.Text = "Gaming Boost in corso..."
    Write-Log "Avvio Gaming Boost V6 (da GUI)"
    Gaming-Boost
    $TxtStatus.Text = "Gaming Boost completato."
})

$BtnGamingBoostPlus.Add_Click({
    $TxtStatus.Text = "Gaming Boost PLUS in corso..."
    Write-Log "Avvio Gaming Boost PLUS V6 (da GUI)"
    Gaming-BoostPlus
    $TxtStatus.Text = "Gaming Boost PLUS completato."
})

$BtnOttimizzaRete.Add_Click({
    $TxtStatus.Text = "Ottimizzazione rete in corso..."
    Write-Log "Avvio Ottimizzazione Rete (da GUI)"
    Ottimizza-Rete
    $TxtStatus.Text = "Ottimizzazione rete completata."
})

$BtnControllaAggiornamenti.Add_Click({
    Write-Log "Controllo aggiornamenti manuale avviato (da GUI)"
    $TxtStatus.Text = "Controllo aggiornamenti..."

    try {
        $RispostaRemota = Invoke-WebRequest -Uri $UrlScriptRemoto -UseBasicParsing -ErrorAction Stop
        $TestoRemoto = $RispostaRemota.Content

        if ($TestoRemoto -match '\$VersioneLocale\s*=\s*"([^"]+)"') {
            $VersioneRemota = $matches[1]
        } else {
            throw "Impossibile leggere la versione remota"
        }

        if ($VersioneLocale -eq $VersioneRemota) {
            $TxtStatus.Text = "La versione è già aggiornata."
            Mostra-Popup -Titolo "Aggiornamento" -Messaggio "La versione locale ($VersioneLocale) è già aggiornata."
            return
        }

        $msg = "Nuova versione disponibile: $VersioneRemota (locale: $VersioneLocale).`nVuoi aggiornare ora?"
        $choice = [System.Windows.MessageBox]::Show($msg, "Aggiornamento", "YesNo", "Question")

        if ($choice -eq "Yes") {
            Write-Log "Aggiornamento confermato dall'utente (da GUI)"

            Copy-Item -Path $ScriptPath -Destination $BackupPath -Force
            Set-Content -Path $ScriptPath -Value $TestoRemoto -Force -Encoding UTF8

            Mostra-Popup -Titolo "Aggiornamento completato" -Messaggio "Aggiornamento completato alla versione $VersioneRemota. Lo script verrà riavviato."

            Start-Sleep -Milliseconds 300
            Start-Process powershell.exe -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$ScriptPath`"")
            $window.Close()
        }
        else {
            Write-Log "Aggiornamento annullato dall'utente (da GUI)"
            $TxtStatus.Text = "Aggiornamento annullato."
        }
    }
    catch {
        Write-Log "Errore durante il controllo aggiornamenti (da GUI): $($_.Exception.Message)"
        Mostra-Popup -Titolo "Errore" -Messaggio "Errore durante il controllo aggiornamenti."
        $TxtStatus.Text = "Errore durante il controllo aggiornamenti."
    }
})

$BtnEsci.Add_Click({
    Write-Log "Chiusura GUI richiesta dall'utente"
    $window.Close()
})

# ============================
#   AVVIO GUI
# ============================

Write-Log "Avvio Tiberio Edition V6 GUI..."
$window.ShowDialog() | Out-Null

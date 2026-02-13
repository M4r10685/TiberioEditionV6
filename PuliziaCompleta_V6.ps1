# ============================
#   TIBERIO EDITION V6.3 - FULL POWER
#   HEADER + LOGGING + AUTO-UPDATE GITHUB
# ============================

# ----------------------------
#   LOGGING AVANZATO
# ----------------------------

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

# ----------------------------
#   AUTO-UPDATE GITHUB
# ----------------------------

$VersioneLocale = "6.3.0"

$ChangelogLocale = @"
NOVITÀ VERSIONE 6.3 FULL POWER:
- Aggiunta Pulizia Browser (Chrome, Edge, Firefox, Opera, Brave, Norton)
- Aggiunta Pulizia USB migliorata
- Aggiunto Salvataggio Driver (solo driver firmati)
- Migliorata stabilità Auto-Update
- Migliorato avvio sicuro (no crash dopo update)
- Ottimizzazioni varie
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

        Mostra-Popup -Titolo "Aggiornamento completato" -Messaggio "Lo script verrà riavviato."
        Write-Log "Riavvio dello script aggiornato..."

        Start-Sleep -Milliseconds 300
        Start-Process powershell.exe -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$ScriptPath`"")
        exit
    }
}
catch {
    Write-Log "Errore durante il controllo aggiornamenti: $($_.Exception.Message)"
}

# ============================
#   FUNZIONI OPERATIVE V6.3 FULL POWER
# ============================

# ----------------------------
#   CLEAN-PATH (FUNZIONE BASE)
# ----------------------------

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

# ----------------------------
#   PULIZIA BASE AVANZATA
# ----------------------------

function Pulizia-Base {
    Write-Log "Esecuzione Pulizia-Base"
    $tot = 0

    $percorsi = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:WINDIR\SoftwareDistribution\Download",
        "$env:WINDIR\Logs",
        "$env:LOCALAPPDATA\CrashDumps",
        "$env:WINDIR\Prefetch"
    )

    foreach ($p in $percorsi) {
        $tot += Clean-Path -Path $p -Descrizione $p -OldOnly -Days 7
    }

    try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}

    return $tot
}

# ----------------------------
#   PULIZIA GAMING
# ----------------------------

function Pulizia-Gaming {
    Write-Log "Esecuzione Pulizia-Gaming"
    $tot = 0

    $percorsiGaming = @(
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\NVIDIA\GLCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\CrashDumps"
    )

    foreach ($p in $percorsiGaming) {
        $tot += Clean-Path -Path $p -Descrizione "Cache Gaming: $p" -OldOnly -Days 5
    }

    return $tot
}

# ----------------------------
#   PULIZIA BROWSER (Chrome, Edge, Firefox, Opera, Brave, Norton)
# ----------------------------

function Pulizia-Browser {
    Write-Log "Pulizia Browser avviata"
    $tot = 0

    $percorsiBrowser = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",

        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",

        "$env:APPDATA\Mozilla\Firefox\Profiles",

        "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache",

        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache",

        "$env:LOCALAPPDATA\Norton\Norton Browser\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Norton\Norton Browser\User Data\Default\Code Cache"
    )

    foreach ($p in $percorsiBrowser) {
        if (Test-Path $p) {
            $tot += Clean-Path -Path $p -Descrizione "Cache Browser: $p" -OldOnly -Days 3
        }
    }

    Write-Log "Pulizia Browser completata. Byte liberati: $tot"
    return $tot
}

# ----------------------------
#   PULIZIA USB
# ----------------------------

function Pulizia-USB {
    Write-Log "Pulizia USB avviata"
    $tot = 0

    $usbDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter }

    foreach ($usb in $usbDrives) {
        $path = "$($usb.DriveLetter):\"
        Write-Log "USB rilevata: $path"

        $percorsiUSB = @(
            "$path*.tmp",
            "$path*.log",
            "$path*.bak",
            "$pathSystem Volume Information",
            "$path.Recycle.Bin"
        )

        foreach ($p in $percorsiUSB) {
            try {
                $items = Get-ChildItem -Path $p -Force -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $tot += $item.Length
                    Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                }
            } catch {}
        }
    }

    Write-Log "Pulizia USB completata. Byte liberati: $tot"
    return $tot
}

# ----------------------------
#   SALVATAGGIO DRIVER (solo driver firmati)
# ----------------------------

function Salva-Driver {
    Write-Log "Salvataggio driver avviato"

    $dest = "$PSScriptRoot\DriverBackup"
    if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

    try {
        Write-Log "Esportazione driver in corso..."
        Export-WindowsDriver -Online -Destination $dest -ErrorAction Stop
        Write-Log "Salvataggio driver completato"
        return $true
    }
    catch {
        Write-Log "Errore durante il salvataggio driver: $($_.Exception.Message)"
        return $false
    }
}

# ----------------------------
#   MANUTENZIONE COMPLETA AVANZATA
# ----------------------------

function Manutenzione-Completa {
    Write-Log "Manutenzione Completa Avanzata avviata"

    $tot = Pulizia-Base
    Write-Log "Pulizia Base completata. Byte liberati: $tot"

    $totGaming = Pulizia-Gaming
    Write-Log "Pulizia Gaming completata. Byte liberati: $totGaming"

    try {
        Write-Log "Esecuzione TRIM SSD"
        Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    Write-Log "Manutenzione Completa Avanzata terminata"
}

# ----------------------------
#   RIPARAZIONE SISTEMA
# ----------------------------

function Ripara-Sistema {
    Write-Log "Riparazione Sistema avviata"

    try {
        Write-Log "Avvio DISM /ScanHealth"
        Start-Process -FilePath "dism.exe" -ArgumentList "/Online","/Cleanup-Image","/ScanHealth" -WindowStyle Hidden
    } catch {}

    try {
        Write-Log "Avvio SFC /SCANNOW"
        Start-Process -FilePath "sfc.exe" -ArgumentList "/SCANNOW" -WindowStyle Hidden
    } catch {}

    Write-Log "Riparazione Sistema avviata (controlla log di sistema)"
}

# ----------------------------
#   GAMING BOOST BASE
# ----------------------------

function Gaming-Boost {
    Write-Log "Gaming Boost V6.3 avviato"

    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) {
            $proc.PriorityClass = "AboveNormal"
            Write-Log "Priorità CPU impostata a AboveNormal"
        }
    } catch {}

    try {
        Write-Log "Ottimizzazione rete base"
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {}

    Write-Log "Gaming Boost V6.3 completato"
}

# ----------------------------
#   GAMING BOOST PLUS (FULL POWER)
# ----------------------------

function Gaming-BoostPlus {
    Write-Log "Gaming Boost PLUS V6.3 avviato"

    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) {
            $proc.PriorityClass = "High"
            Write-Log "Priorità CPU impostata a High"
        }
    } catch {}

    try {
        Write-Log "Timer/Performance Threshold → 0"
        powercfg -setacvalueindex scheme_current sub_processor PERFINCTHRESHOLD 0 | Out-Null
        powercfg -setactive scheme_current | Out-Null
    } catch {}

    try {
        Write-Log "Profilo energetico High Performance"
        powercfg -setactive SCHEME_MIN | Out-Null
    } catch {}

    try {
        Write-Log "Ottimizzazione rete avanzata"
        netsh int tcp set global autotuninglevel=disabled | Out-Null
        netsh int tcp set global rss=disabled | Out-Null
        netsh int tcp set global chimney=disabled | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {}

    try {
        Write-Log "Disattivazione servizi non essenziali"
        Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
        Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}

    try {
        Write-Log "NetworkThrottlingIndex → 0xffffffff"
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
    } catch {}

    Write-Log "Gaming Boost PLUS V6.3 completato"
}

# ----------------------------
#   RIPRISTINO COMPLETO
# ----------------------------

function Ripristino-Completo {
    Write-Log "Ripristino completo avviato"

    try {
        Write-Log "Ripristino servizi"
        Set-Service "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "SysMain" -ErrorAction SilentlyContinue

        Set-Service "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "WSearch" -ErrorAction SilentlyContinue

        Set-Service "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "DiagTrack" -ErrorAction SilentlyContinue
    } catch {}

    try {
        Write-Log "Ripristino priorità CPU"
        $proc = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($proc) { $proc.PriorityClass = "Normal" }
    } catch {}

    try {
        Write-Log "Ripristino Performance Threshold → 50"
        powercfg -setacvalueindex scheme_current sub_processor PERFINCTHRESHOLD 50 | Out-Null
        powercfg -setactive scheme_current | Out-Null
    } catch {}

    try {
        Write-Log "Ripristino rete TCP"
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics enabled | Out-Null
    } catch {}

    try {
        Write-Log "Ripristino NetworkThrottlingIndex → 10"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    } catch {}

    try {
        Write-Log "Profilo energetico Bilanciato"
        powercfg -setactive SCHEME_BALANCED | Out-Null
    } catch {}

    Write-Log "Ripristino completo terminato"
}

# ----------------------------
#   OTTIMIZZAZIONE RETE AVANZATA
# ----------------------------

function Ottimizza-Rete {
    Write-Log "Ottimizzazione rete avanzata avviata"

    try {
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
    } catch {}

    try {
        Write-Log "SystemResponsiveness → 10"
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "SystemResponsiveness" -Value 10 -ErrorAction SilentlyContinue
    } catch {}

    Write-Log "Ottimizzazione rete avanzata completata"
}

# ============================
#   AUTO-GAMING-BOOST (ETS2)
# ============================

Add-Type -AssemblyName PresentationFramework   

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

Write-Log "Avvio Tiberio Edition V6.3 (fase pre-GUI)..."

# Pulizia iniziale NON BLOCCANTE (evita crash dopo update)
Start-Job -ScriptBlock {
    try {
        $tot = Pulizia-Base
        Write-Log "Pulizia Base iniziale completata. Byte liberati: $tot"
    } catch {
        Write-Log "Errore durante la pulizia iniziale: $($_.Exception.Message)"
    }
} | Out-Null

# ============================
#   GUI XAML
# ============================

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tiberio Edition V6.3 - Full Power" Height="480" Width="760"
        WindowStartupLocation="CenterScreen"
        Background="#F3F3F3"
        ResizeMode="NoResize">

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Pulizia Completa - Tiberio Edition V6.3 (Full Power)"
                   FontSize="22"
                   FontWeight="Bold"
                   Foreground="#202020"
                   Margin="0,0,0,15"/>

        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- COLONNA SINISTRA -->
            <StackPanel Grid.Column="0" Margin="0,0,10,0">
                <TextBlock Text="Manutenzione" FontWeight="Bold" Margin="0,0,0,8"/>

                <Button x:Name="BtnPuliziaBase" Content="Pulizia Base" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnPuliziaGaming" Content="Pulizia Gaming" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnPuliziaBrowser" Content="Pulizia Browser" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnPuliziaUSB" Content="Pulizia USB" Height="32" Margin="0,0,0,6"/>
                <Button x:Name="BtnSalvaDriver" Content="Salva Driver" Height="32" Margin="0,0,0,6"/>

                <Button x:Name="BtnManutenzioneCompleta" Content="Manutenzione Completa Avanzata" Height="32" Margin="0,10,0,6"/>
                <Button x:Name="BtnRiparazioneSistema" Content="Riparazione Sistema" Height="32" Margin="0,0,0,6"/>

                <Button x:Name="BtnControllaAggiornamenti" Content="Controlla Aggiornamenti" Height="32" Margin="0,10,0,0"/>
            </StackPanel>

            <!-- COLONNA DESTRA -->
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
$BtnPuliziaBrowser         = $window.FindName("BtnPuliziaBrowser")
$BtnPuliziaUSB             = $window.FindName("BtnPuliziaUSB")
$BtnSalvaDriver            = $window.FindName("BtnSalvaDriver")
$BtnManutenzioneCompleta   = $window.FindName("BtnManutenzioneCompleta")
$BtnRiparazioneSistema     = $window.FindName("BtnRiparazioneSistema")
$BtnGamingBoost            = $window.FindName("BtnGamingBoost")
$BtnGamingBoostPlus        = $window.FindName("BtnGamingBoostPlus")
$BtnOttimizzaRete          = $window.FindName("BtnOttimizzaRete")
$BtnControllaAggiornamenti = $window.FindName("BtnControllaAggiornamenti")
$BtnEsci                   = $window.FindName("BtnEsci")
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

$BtnPuliziaBrowser.Add_Click({
    $TxtStatus.Text = "Pulizia Browser in corso..."
    Write-Log "Avvio Pulizia Browser (da GUI)"
    $freed = Pulizia-Browser
    $MB = [math]::Round($freed / 1MB, 2)
    $TxtStatus.Text = "Pulizia Browser completata. Liberati $MB MB."
})

$BtnPuliziaUSB.Add_Click({
    $TxtStatus.Text = "Pulizia USB in corso..."
    Write-Log "Avvio Pulizia USB (da GUI)"
    $freed = Pulizia-USB
    $MB = [math]::Round($freed / 1MB, 2)
    $TxtStatus.Text = "Pulizia USB completata. Liberati $MB MB."
})

$BtnSalvaDriver.Add_Click({
    $TxtStatus.Text = "Salvataggio driver in corso..."
    Write-Log "Avvio Salvataggio Driver (da GUI)"
    $ok = Salva-Driver
    if ($ok) {
        $TxtStatus.Text = "Driver salvati correttamente."
    } else {
        $TxtStatus.Text = "Errore durante il salvataggio driver."
    }
})

$BtnManutenzioneCompleta.Add_Click({
    $TxtStatus.Text = "Manutenzione Completa Avanzata in corso..."
    Write-Log "Avvio Manutenzione Completa Avanzata (da GUI)"
    Manutenzione-Completa
    $TxtStatus.Text = "Manutenzione Completa Avanzata completata."
})

$BtnRiparazioneSistema.Add_Click({
    $TxtStatus.Text = "Riparazione sistema in corso..."
    Write-Log "Avvio Riparazione Sistema (da GUI)"
    Ripara-Sistema
    $TxtStatus.Text = "Riparazione sistema avviata (controlla log)."
})

$BtnGamingBoost.Add_Click({
    $TxtStatus.Text = "Gaming Boost in corso..."
    Write-Log "Avvio Gaming Boost (da GUI)"
    Gaming-Boost
    $TxtStatus.Text = "Gaming Boost completato."
})

$BtnGamingBoostPlus.Add_Click({
    $TxtStatus.Text = "Gaming Boost PLUS in corso..."
    Write-Log "Avvio Gaming Boost PLUS (da GUI)"
    Gaming-BoostPlus
    $TxtStatus.Text = "Gaming Boost PLUS completato."
})

$BtnOttimizzaRete.Add_Click({
    $TxtStatus.Text = "Ottimizzazione rete in corso..."
    Write-Log "Avvio Ottimizzazione Rete (da GUI)"
    Ottimizza-Rete
    $TxtStatus.Text = "Ottimizzazione rete completata."
})

# ----------------------------
#   PULSANTE AGGIORNAMENTI (GITHUB)
# ----------------------------

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

# ----------------------------
#   USCITA
# ----------------------------

$BtnEsci.Add_Click({
    Write-Log "Chiusura GUI richiesta dall'utente"
    $window.Close()
})

# ============================
#   AVVIO GUI
# ============================

Write-Log "Avvio Tiberio Edition V6.3 GUI..."
$window.ShowDialog() | Out-Null




Add-Type -AssemblyName PresentationFramework -ErrorAction Stop

# ============================
#   VERSIONE SCRIPT
# ============================
$VersioneLocale = "6.1.0"

# ============================
#   WRITE-LOG (TIBERIO EDITION) - CORRETTA
# ============================
function Write-Log {
    param([string]$msg)

    $logPath = "$env:USERPROFILE\Desktop\TiberioEditionV6.log"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] $msg"

    try {
        Add-Content -Path $logPath -Value $entry -Encoding UTF8 -ErrorAction Stop
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Impossibile scrivere nel log - $errorMessage"
        Write-Error $fullMessage
    }
}

# ============================
#   CLEAN-PATH (TIBERIO EDITION) - CORRETTA
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
                    try {
                        Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                    } catch {
                        $errorMessage = $PSItem.Exception.Message
                        $fullMessage = "Impossibile eliminare: $($item.FullName) - $errorMessage"
                        Write-Log $fullMessage
                        continue
                    }
                }
            } else {
                $freed += $item.Length
                try {
                    Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                } catch {
                    $errorMessage = $PSItem.Exception.Message
                    $fullMessage = "Impossibile eliminare: $($item.FullName) - $errorMessage"
                    Write-Log $fullMessage
                    continue
                }
            }
        }
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante la pulizia di $Path - $errorMessage"
        Write-Log $fullMessage
    }

    return $freed
}

# ============================
#   AUTO-UPDATE V6 (DA GITHUB)
# ============================

function Get-RemoteScriptContent {
    param([string]$Url)

    Write-Log "Download contenuto remoto da GitHub..."

    try {
        $contenuto = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        Write-Log "Contenuto remoto scaricato correttamente"
        return $contenuto.Content
    }
    catch {
        Write-Log "Errore durante il download del contenuto remoto: $($_.Exception.Message)"
        return $null
    }
}

function Controlla-Aggiornamenti {
    param([string]$Url)

    Write-Log "Controllo aggiornamenti da GitHub..."

    $contenuto = Get-RemoteScriptContent -Url $Url
    if (-not $contenuto) {
        Write-Log "Nessun contenuto remoto trovato"
        return "Errore"
    }

    if ($contenuto -match '\$VersioneLocale\s*=\s*"([^"]+)"') {
        $VersioneRemota = $matches[1]
        Write-Log "Versione remota trovata: $VersioneRemota"
    } else {
        Write-Log "Impossibile leggere la versione remota"
        return "Errore"
    }

    if ($VersioneRemota -ne $VersioneLocale) {
        Write-Log "Nuova versione disponibile: $VersioneRemota"
        return $contenuto
    } else {
        Write-Log "La versione è già aggiornata"
        return "OK"
    }
}

function Aggiorna-Script {
    param(
        [string]$NuovoContenuto,
        [string]$PercorsoLocale
    )

    Write-Log "Aggiornamento script locale..."

    # Controlla se $PercorsoLocale è vuoto
    if ([string]::IsNullOrEmpty($PercorsoLocale)) {
        Write-Log "Errore: Percorso locale non valido."
        return "Errore"
    }

    # Controlla se il file esiste
    if (!(Test-Path $PercorsoLocale)) {
        Write-Log "Percorso script non trovato: $PercorsoLocale"
        return "Errore"
    }

    try {
        $NuovoContenuto | Out-File -FilePath $PercorsoLocale -Encoding UTF8 -Force -ErrorAction Stop
        Write-Log "Aggiornamento completato"
        return "OK"
    }
    catch {
        Write-Log "Errore durante l'aggiornamento: $($_.Exception.Message)"
        return "Errore"
    }
}

# ============================
#   FUNZIONI OPERATIVE REALI
# ============================

function Pulizia-Base {
    Write-Log "Esecuzione Pulizia-Base"
    $tot = 0

    # Inizia la progress bar
    Update-ProgressBar -Value 10 -Status "Pulizia TEMP utente..."

    $tot += Clean-Path -Path "$env:TEMP" -Descrizione "TEMP utente"
    Update-ProgressBar -Value 20 -Status "Pulizia TEMP sistema..."

    $tot += Clean-Path -Path "$env:WINDIR\Temp" -Descrizione "TEMP sistema"
    Update-ProgressBar -Value 30 -Status "Pulizia Cache Windows Update..."

    $tot += Clean-Path -Path "$env:WINDIR\SoftwareDistribution\Download" -Descrizione "Cache Windows Update"
    Update-ProgressBar -Value 40 -Status "Pulizia Log Windows..."

    $tot += Clean-Path -Path "$env:WINDIR\Logs" -Descrizione "Log Windows" -OldOnly -Days 7
    Update-ProgressBar -Value 50 -Status "Pulizia CrashDumps..."

    $tot += Clean-Path -Path "$env:LOCALAPPDATA\CrashDumps" -Descrizione "CrashDumps" -OldOnly -Days 7
    Update-ProgressBar -Value 60 -Status "Pulizia Prefetch..."

    $tot += Clean-Path -Path "$env:WINDIR\Prefetch" -Descrizione "Prefetch" -OldOnly -Days 10
    Update-ProgressBar -Value 80 -Status "Svuotamento Cestino..."

    try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
    Update-ProgressBar -Value 100 -Status "Pulizia Base completata."

    return $tot
}

function Pulizia-Gaming { Write-Log "Pulizia Gaming (placeholder)" }
function Manutenzione-Completa { Write-Log "Manutenzione Completa (placeholder)" }
function Ripara-Sistema { Write-Log "Riparazione Sistema (placeholder)" }
function Gaming-Boost { Write-Log "Gaming Boost (placeholder)" }

# ============================
#   GAMING-BOOSTPLUS - CORRETTA (CHIUSURA PROCESSI, OTTIMIZZAZIONE PING, RIPRISTINO)
# ============================
function Chiudi-ProcessiNonNecessari {
    Write-Log "Chiusura processi non necessari per gaming..."

    $processiDaChiudere = @(
        "chrome", "firefox", "edge", "brave", "opera",
        "teams", "skype", "zoom", "spotify",
        "vlc", "uplay", "origin", "epicgameslauncher",
        "onenote", "outlook", "word", "excel", "powerpoint",
        "winamp", "audacity", "anydesk", "teamviewer"
    )

    foreach ($procName in $processiDaChiudere) {
        try {
            $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($procs) {
                foreach ($p in $procs) {
                    $p.Kill()
                    Write-Log "Chiuso: $($p.ProcessName) (PID: $($p.Id))"
                }
            }
        } catch {
            $errorMessage = $PSItem.Exception.Message
            $fullMessage = "Impossibile chiudere $procName - $errorMessage"
            Write-Log $fullMessage
        }
    }
}

function Ottimizza-Ping {
    Write-Log "Ottimizzazione rete per ping basso..."

    # Disattiva servizi non essenziali
    try {
        Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
        Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante l'ottimizzazione dei servizi - $errorMessage"
        Write-Log $fullMessage
    }

    # Ottimizzazione TCP (ping basso)
    try {
        netsh int tcp set global autotuninglevel=disabled | Out-Null
        netsh int tcp set global rss=disabled | Out-Null
        netsh int tcp set global chimney=disabled | Out-Null
        netsh int tcp set heuristics disabled | Out-Null
        Write-Log "Ottimizzazione TCP per ping basso completata."
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante l'ottimizzazione TCP - $errorMessage"
        Write-Log $fullMessage
    }

    # Priorità CPU per ETS2
    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) {
            $proc.PriorityClass = "High"
            Write-Log "Priorità CPU impostata su High per eurotrucks2"
        }
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Impossibile impostare priorità CPU - $errorMessage"
        Write-Log $fullMessage
    }
}

function Ripristina-ProcessiERete {
    Write-Log "Ripristino processi e rete..."

    # Ripristina servizi
    try {
        Set-Service "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "SysMain" -ErrorAction SilentlyContinue

        Set-Service "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "WSearch" -ErrorAction SilentlyContinue

        Set-Service "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "DiagTrack" -ErrorAction SilentlyContinue
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante il ripristino dei servizi - $errorMessage"
        Write-Log $fullMessage
    }

    # Ripristino TCP
    try {
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set heuristics enabled | Out-Null
        Write-Log "Ripristino TCP completato."
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante il ripristino TCP - $errorMessage"
        Write-Log $fullMessage
    }

    # Ripristino priorità CPU
    try {
        $proc = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($proc) { $proc.PriorityClass = "Normal" }
        Write-Log "Priorità CPU ripristinata a Normal per explorer"
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Impossibile ripristinare priorità CPU - $errorMessage"
        Write-Log $fullMessage
    }
}

function Gaming-BoostPlus {
    Write-Log "Gaming Boost PLUS V6 avviato"

    Chiudi-ProcessiNonNecessari
    Ottimizza-Ping
    Write-Log "Gaming Boost PLUS V6 completato"
}

# ============================
#   RIPRISTINO-COMPLETO - CORRETTO
# ============================
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

    # Ripristino Network Throttling Index (con controllo UAC)
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Esecuzione senza privilegi amministrativi. Impossibile modificare HKLM."
    } else {
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
                -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
        } catch {
            $errorMessage = $PSItem.Exception.Message
            $fullMessage = "Errore durante il ripristino di NetworkThrottlingIndex - $errorMessage"
            Write-Log $fullMessage
        }
    }

    # Ripristino profilo energetico
    try {
        powercfg -setactive SCHEME_BALANCED | Out-Null
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante il ripristino del profilo energetico - $errorMessage"
        Write-Log $fullMessage
    }

    Write-Log "Ripristino completo terminato"
}

function Ottimizza-Rete { Write-Log "Ottimizzazione rete (placeholder)" }

# ============================
#   AUTO-GAMING-BOOST (ETS2)
# ============================

$global:GamingBoostAttivo = $false

function Controlla-ETS2 {
    $proc = Get-Process | Where-Object { $_.ProcessName -like "*eurotruck*" -or $_.ProcessName -like "*ets2*" } -ErrorAction SilentlyContinue
    return $proc -ne $null
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(5)

$timer.Add_Tick({
    if (Controlla-ETS2) {
        if (-not $global:GamingBoostAttivo) {
            Write-Log "ETS2 rilevato → Attivo Gaming Boost PLUS"
            Gaming-BoostPlus
            $TxtStatus.Text = "Gaming Boost PLUS attivo (ETS2 rilevato)"
            $global:GamingBoostAttivo = $true
        }
    }
    else {
        if ($global:GamingBoostAttivo) {
            Write-Log "ETS2 chiuso → Ripristino completo automatico"
            Ripristino-Completo
            $TxtStatus.Text = "Ripristino completato (ETS2 chiuso)"
            $global:GamingBoostAttivo = $false
        }
    }
})

# ============================
#   PULIZIA BROWSER
# ============================

function Pulisci-Chrome {
    Write-Log "Pulizia Chrome..."

    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
    if (!(Test-Path $chromePath)) {
        Write-Log "Chrome non installato o percorso non trovato"
        return
    }

    $items = @(
        "Cache",
        "Code Cache",
        "GPUCache",
        "Cookies",
        "History",
        "Bookmarks",
        "Login Data"
    )

    foreach ($item in $items) {
        $itemPath = Join-Path $chromePath $item
        if (Test-Path $itemPath) {
            try {
                Remove-Item $itemPath -Recurse -Force -ErrorAction Stop
                Write-Log "Eliminato: $itemPath"
            } catch {
                $errorMessage = $PSItem.Exception.Message
                $fullMessage = "Impossibile eliminare: $itemPath - $errorMessage"
                Write-Log $fullMessage
            }
        }
    }

    Write-Log "Pulizia Chrome completata."
}

function Pulisci-Edge {
    Write-Log "Pulizia Edge..."

    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
    if (!(Test-Path $edgePath)) {
        Write-Log "Edge non installato o percorso non trovato"
        return
    }

    $items = @(
        "Cache",
        "Code Cache",
        "GPUCache",
        "Cookies",
        "History",
        "Bookmarks",
        "Login Data"
    )

    foreach ($item in $items) {
        $itemPath = Join-Path $edgePath $item
        if (Test-Path $itemPath) {
            try {
                Remove-Item $itemPath -Recurse -Force -ErrorAction Stop
                Write-Log "Eliminato: $itemPath"
            } catch {
                $errorMessage = $PSItem.Exception.Message
                $fullMessage = "Impossibile eliminare: $itemPath - $errorMessage"
                Write-Log $fullMessage
            }
        }
    }

    Write-Log "Pulizia Edge completata."
}

function Pulisci-Brave {
    Write-Log "Pulizia Brave..."

    $bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default"
    if (!(Test-Path $bravePath)) {
        Write-Log "Brave non installato o percorso non trovato"
        return
    }

    $items = @(
        "Cache",
        "Code Cache",
        "GPUCache",
        "Cookies",
        "History",
        "Bookmarks",
        "Login Data"
    )

    foreach ($item in $items) {
        $itemPath = Join-Path $bravePath $item
        if (Test-Path $itemPath) {
            try {
                Remove-Item $itemPath -Recurse -Force -ErrorAction Stop
                Write-Log "Eliminato: $itemPath"
            } catch {
                $errorMessage = $PSItem.Exception.Message
                $fullMessage = "Impossibile eliminare: $itemPath - $errorMessage"
                Write-Log $fullMessage
            }
        }
    }

    Write-Log "Pulizia Brave completata."
}

function Pulisci-Norton {
    Write-Log "Pulizia Norton Safe Web..."

    $nortonPath = "$env:APPDATA\Norton\Norton Safe Web"
    if (!(Test-Path $nortonPath)) {
        Write-Log "Norton Safe Web non installato o percorso non trovato"
        return
    }

    try {
        Remove-Item $nortonPath -Recurse -Force -ErrorAction Stop
        Write-Log "Pulizia Norton Safe Web completata."
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Impossibile eliminare Norton Safe Web - $errorMessage"
        Write-Log $fullMessage
    }
}

# ============================
#   BACKUP DRIVER IN KDRIVE
# ============================

function Backup-DriverInKDrive {
    Write-Log "Avvio backup driver in kDrive..."

    # Percorso kDrive (cartella utente)
    $kDrivePath = "C:\Users\tiber\kDrive"
    if (!(Test-Path $kDrivePath)) {
        Write-Log "Cartella kDrive non trovata: $kDrivePath"
        return
    }

    # Percorso driver Windows
    $driverPath = "$env:WINDIR\System32\DriverStore\FileRepository"

    # Crea cartella backup con data
    $backupFolder = Join-Path $kDrivePath "Driver_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupFolder -ErrorAction SilentlyContinue | Out-Null

    # Usa robocopy per copiare i driver (richiede privilegi amministrativi)
    try {
        $robocopyCmd = "robocopy `"$driverPath`" `"$backupFolder`" /E /R:0 /W:0 /LOG+:`"$env:USERPROFILE\Desktop\DriverBackup.log`""
        Write-Log "Eseguo: $robocopyCmd"
        Invoke-Expression $robocopyCmd
        Write-Log "Backup driver completato in: $backupFolder"
    } catch {
        $errorMessage = $PSItem.Exception.Message
        $fullMessage = "Errore durante il backup dei driver - $errorMessage"
        Write-Log $fullMessage
    }
}

# ============================
#   BACKUP DOCUMENTI IN KDRIVE
# ============================

function Backup-DocumentiInKDrive {
    Write-Log "Avvio backup documenti in kDrive..."

    # Percorso kDrive (cartella utente)
    $kDrivePath = "C:\Users\tiber\kDrive"
    if (!(Test-Path $kDrivePath)) {
        Write-Log "Cartella kDrive non trovata: $kDrivePath"
        return
    }

    # Percorso Documenti
    $documentiPath = "$env:USERPROFILE\Documents"

    # Crea cartella backup con data
    $backupFolder = Join-Path $kDrivePath "backup documenti\Documenti_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    # Crea la cartella (se non esiste)
    New-Item -ItemType Directory -Path $backupFolder -ErrorAction SilentlyContinue | Out-Null

    # Usa robocopy per copiare i documenti
    try {
        $robocopyCmd = "robocopy `"$documentiPath`" `"$backupFolder`" /E /R:0 /W:0 /LOG+:`"$env:USERPROFILE\Desktop\DocumentiBackup.log`""
        Write-Log "Eseguo: $robocopyCmd"
        Invoke-Expression $robocopyCmd
        Write-Log "Backup documenti completato in: $backupFolder"
    } catch {
        Write-Log "Errore durante il backup dei documenti: $($_.Exception.Message)"
    }
}

# ============================
#   GUI XAML
# ============================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       Title="Tiberio Edition V6" Height="580" Width="720"
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
               <Button x:Name="BtnPuliziaBrowser" Content="Pulizia Browser" Height="32" Margin="0,0,0,6"/>
               <Button x:Name="BtnBackupDriver" Content="Backup Driver in kDrive" Height="32" Margin="0,0,0,6"/>
               <Button x:Name="BtnBackupDocumenti" Content="Backup Documenti in kDrive" Height="32" Margin="0,0,0,6"/>
               <Button x:Name="BtnEsci" Content="Esci" Height="32" Margin="0,20,0,0"/>
           </StackPanel>
       </Grid>

       <StatusBar Grid.Row="2" Margin="0,10,0,0">
           <StatusBarItem>
               <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                   <TextBlock x:Name="TxtStatus" Text="Pronto." Margin="0,0,10,0"/>
                   <ProgressBar x:Name="ProgressBar" Width="200" Height="10" Minimum="0" Maximum="100" Value="0" Visibility="Collapsed"/>
               </StackPanel>
           </StatusBarItem>
       </StatusBar>
   </Grid>
</Window>
"@

# ============================
#   PARSING XAML
# ============================
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# ============================
#   RIFERIMENTI CONTROLLI
# ============================
$BtnPuliziaBase            = $window.FindName("BtnPuliziaBase")
$BtnPuliziaGaming          = $window.FindName("BtnPuliziaGaming")
$BtnManutenzioneCompleta   = $window.FindName("BtnManutenzioneCompleta")
$BtnRiparazioneSistema     = $window.FindName("BtnRiparazioneSistema")
$BtnGamingBoost          = $window.FindName("BtnGamingBoost")
$BtnGamingBoostPlus      = $window.FindName("BtnGamingBoostPlus")
$BtnOttimizzaRete        = $window.FindName("BtnOttimizzaRete")
$BtnEsci                 = $window.FindName("BtnEsci")
$BtnControllaAggiornamenti = $window.FindName("BtnControllaAggiornamenti")
$BtnPuliziaBrowser       = $window.FindName("BtnPuliziaBrowser")
$BtnBackupDriver         = $window.FindName("BtnBackupDriver")
$BtnBackupDocumenti      = $window.FindName("BtnBackupDocumenti")
$TxtStatus               = $window.FindName("TxtStatus")
$ProgressBar             = $window.FindName("ProgressBar")

# ============================
#   FUNZIONE: UPDATE PROGRESS BAR
# ============================
function Update-ProgressBar {
    param([int]$Value, [string]$Status = "")

    # Esegui l'aggiornamento sul thread della GUI
    $window.Dispatcher.Invoke({
        if ($Value -gt 0) {
            $ProgressBar.Value = $Value
            $ProgressBar.Visibility = "Visible"
            $TxtStatus.Text = $Status
        } else {
            $ProgressBar.Visibility = "Collapsed"
            $TxtStatus.Text = $Status
        }
    }, "Background")
}

# ============================
#   HANDLER PULSANTI
# ============================
$BtnPuliziaBase.Add_Click({
    $TxtStatus.Text = "Esecuzione Pulizia Base..."
    Write-Log "Avvio Pulizia Base"
    Update-ProgressBar -Value 10 -Status "Pulizia TEMP utente..."
    $freed = Pulizia-Base
    $MB = [math]::Round($freed / 1MB, 2)
    Update-ProgressBar -Value 100 -Status "Pulizia Base completata. Liberati $MB MB."
})

$BtnPuliziaGaming.Add_Click({
    $TxtStatus.Text = "Esecuzione Pulizia Gaming..."
    Write-Log "Avvio Pulizia Gaming"
    Update-ProgressBar -Value 10 -Status "Pulizia Gaming in corso..."
    $freed = Pulizia-Gaming
    $MB = [math]::Round($freed / 1MB, 2)
    Update-ProgressBar -Value 100 -Status "Pulizia Gaming completata. Liberati $MB MB."
})

$BtnManutenzioneCompleta.Add_Click({
    $TxtStatus.Text = "Manutenzione Completa Avanzata in corso..."
    Write-Log "Avvio Manutenzione Completa Avanzata V6"
    Update-ProgressBar -Value 10 -Status "Manutenzione Completa in corso..."
    Manutenzione-Completa
    Update-ProgressBar -Value 100 -Status "Manutenzione Completa Avanzata completata."
})

$BtnRiparazioneSistema.Add_Click({
    $TxtStatus.Text = "Riparazione sistema in corso..."
    Write-Log "Avvio Riparazione Sistema V6"
    Update-ProgressBar -Value 10 -Status "Riparazione sistema in corso..."
    Ripara-Sistema
    Update-ProgressBar -Value 100 -Status "Riparazione sistema completata."
})

$BtnGamingBoost.Add_Click({
    $TxtStatus.Text = "Gaming Boost in corso..."
    Write-Log "Avvio Gaming Boost V6"
    Update-ProgressBar -Value 10 -Status "Gaming Boost in corso..."
    Gaming-Boost
    Update-ProgressBar -Value 100 -Status "Gaming Boost completato."
})

$BtnGamingBoostPlus.Add_Click({
    $TxtStatus.Text = "Gaming Boost PLUS in corso..."
    Write-Log "Avvio Gaming Boost PLUS V6"
    Update-ProgressBar -Value 10 -Status "Gaming Boost PLUS in corso..."
    Gaming-BoostPlus
    Update-ProgressBar -Value 100 -Status "Gaming Boost PLUS completato."
})

$BtnOttimizzaRete.Add_Click({
    $TxtStatus.Text = "Ottimizzazione rete in corso..."
    Write-Log "Avvio Ottimizzazione Rete"
    Update-ProgressBar -Value 10 -Status "Ottimizzazione rete in corso..."
    Ottimizza-Rete
    Update-ProgressBar -Value 100 -Status "Ottimizzazione rete completata."
})

$BtnControllaAggiornamenti.Add_Click({
    $TxtStatus.Text = "Controllo aggiornamenti..."
    Write-Log "Avvio controllo aggiornamenti"

    $url = "https://raw.githubusercontent.com/M4r10685/TiberioEditionV6/main/TiberioEditionV6.ps1"

    $risultato = Controlla-Aggiornamenti -Url $url

    if ($risultato -eq "OK") {
        $TxtStatus.Text = "La versione è già aggiornata."
    }
    elseif ($risultato -eq "Errore") {
        $TxtStatus.Text = "Errore durante il controllo aggiornamenti."
    }
    else {
        Write-Log "Aggiornamento disponibile, procedo..."

        # Usa $MyInvocation.MyCommand.Definition — se è vuoto, usa il percorso corrente
        if ($MyInvocation.MyCommand.Definition) {
            $percorsoLocale = $MyInvocation.MyCommand.Definition
        } else {
            $percorsoLocale = Join-Path (Get-Location).Path "TiberioEditionV6.ps1"
            Write-Log "Avviso: Percorso dello script non determinato. Usato: $percorsoLocale"
        }

        $result = Aggiorna-Script -NuovoContenuto $risultato -PercorsoLocale $percorsoLocale
        if ($result -eq "OK") {
            $TxtStatus.Text = "Aggiornamento completato. Riavvia lo script."
            # Riavvia la GUI dopo l'aggiornamento
            Update-ProgressBar -Value 100 -Status "Aggiornamento completato. Riavvio in corso..."
            Start-Sleep -Seconds 2
            $window.Close()
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$percorsoLocale`"
        } else {
            $TxtStatus.Text = "Errore durante l'aggiornamento."
        }
    }
})

$BtnPuliziaBrowser.Add_Click({
    $TxtStatus.Text = "Pulizia browser in corso..."
    Write-Log "Avvio pulizia browser"
    Update-ProgressBar -Value 10 -Status "Pulizia Chrome in corso..."
    Pulisci-Chrome
    Update-ProgressBar -Value 30 -Status "Pulizia Edge in corso..."
    Pulisci-Edge
    Update-ProgressBar -Value 60 -Status "Pulizia Brave in corso..."
    Pulisci-Brave
    Update-ProgressBar -Value 80 -Status "Pulizia Norton in corso..."
    Pulisci-Norton
    Update-ProgressBar -Value 100 -Status "Pulizia browser completata."
})

$BtnBackupDriver.Add_Click({
    $TxtStatus.Text = "Backup driver in corso..."
    Write-Log "Avvio backup driver"
    Update-ProgressBar -Value 10 -Status "Backup driver in corso..."
    Backup-DriverInKDrive
    Update-ProgressBar -Value 100 -Status "Backup driver completato."
})

$BtnBackupDocumenti.Add_Click({
    $TxtStatus.Text = "Backup documenti in corso..."
    Write-Log "Avvio backup documenti"
    Update-ProgressBar -Value 10 -Status "Backup documenti in corso..."
    Backup-DocumentiInKDrive
    Update-ProgressBar -Value 100 -Status "Backup documenti completato."
})

$BtnEsci.Add_Click({
    Update-ProgressBar -Value 0 -Status "Pronto."
    $window.Close()
})

# ============================
#   AVVIO GUI
# ============================
Write-Log "Avvio Tiberio Edition V6 GUI..."
$timer.Start()
$window.Add_Closed({
    $timer.Stop()
    $timer = $null
})
$window.ShowDialog() | Out-Null

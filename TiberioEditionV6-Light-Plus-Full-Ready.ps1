# ============================
#   VERSIONE SCRIPT (PRONTA ALL'USO - SENZA ERRORI)
# ============================
$VersioneLocale = "6.2.0-Light-Plus-Full-Ready"

# ============================
#   MODALITÀ AGGRESSIVE OPTIMIZATIONS (disattivata per stabilità)
# ============================
$global:AggressiveOptimizations = $false

# ============================
#   WRITE-LOG (TIBERIO EDITION) - CORRETTA
# ============================
function Write-Log {
    param([string]$msg)
    $logPath = "$env:USERPROFILE\Desktop\TiberioEditionV6-Light-Plus-Full-Ready.log"
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
#   CONTROLLO PRESENZA PRESENTATIONFRAMEWORK
# ============================
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
} catch {
    Write-Error "Impossibile caricare PresentationFramework. Assicurati di avere .NET Framework 3.5+ installato."
    Write-Error "Esegui su Windows 10/11 con .NET Framework completo."
    Write-Log "Errore caricamento PresentationFramework: $($_.Exception.Message)"
    pause
    exit 1
}

# ============================
#   CLEAN-PATH (TIBERIO EDITION) - CORRETTA
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
#   AUTO-UPDATE (Semplificato)
# ============================
function Controlla-Aggiornamenti {
    param([string]$Url)
    Write-Log "Controllo aggiornamenti da GitHub..."
    try {
        $contenuto = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        if ($contenuto.Content -match '\$VersioneLocale\s*=\s*"([^"]+)"') {
            $VersioneRemota = $matches[1]
            Write-Log "Versione remota: $VersioneRemota"
            if ($VersioneRemota -ne $VersioneLocale) {
                Write-Log "Nuova versione disponibile: $VersioneRemota"
                return $contenuto.Content
            } else {
                Write-Log "Versione aggiornata"
                return "OK"
            }
        } else {
            Write-Log "Impossibile leggere la versione remota"
            return "Errore"
        }
    } catch {
        Write-Log "Errore durante il download: $($_.Exception.Message)"
        return "Errore"
    }
}

function Aggiorna-Script {
    param(
        [string]$NuovoContenuto,
        [string]$PercorsoLocale
    )
    Write-Log "Aggiornamento script locale..."
    if ([string]::IsNullOrEmpty($PercorsoLocale)) {
        Write-Log "Errore: Percorso locale non valido."
        return "Errore"
    }
    if (!(Test-Path $PercorsoLocale)) {
        Write-Log "Percorso script non trovato: $PercorsoLocale"
        return "Errore"
    }
    $backupPath = "$PercorsoLocale.bak"
    try {
        Copy-Item $PercorsoLocale $backupPath -Force -ErrorAction Stop
        Write-Log "Backup creato: $backupPath"
    } catch {
        Write-Log "Errore durante la creazione del backup: $($_.Exception.Message)"
    }
    try {
        $NuovoContenuto | Out-File -FilePath $PercorsoLocale -Encoding UTF8 -Force -ErrorAction Stop
        Write-Log "Aggiornamento completato"
        return "OK"
    } catch {
        Write-Log "Errore durante l'aggiornamento: $($_.Exception.Message)"
        return "Errore"
    }
}

# ============================
#   FUNZIONI OPERATIVE (SOLO PULIZIA BASE E GAMING BOOST PLUS)
# ============================
function Pulizia-Base {
    Write-Log "Esecuzione Pulizia-Base"
    $tot = 0
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

# ============================
#   GAMING-BOOSTPLUS (SOLO CHIUSURA PROCESSI E OTTIMIZZAZIONE PING)
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
            $errorMessage = $($_.Exception.Message -replace '"', '""')
            Write-Log "Impossibile chiudere $procName - $errorMessage"
        }
    }
}

function Ottimizza-Ping {
    Write-Log "Ottimizzazione rete per ping basso..."
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
#   OTTIMIZZAZIONE 5G NSA LEGGERA (SOLO TCP E QoS)
# ============================
function Ottimizza-5GNSA {
    Write-Log "Avvio ottimizzazioni 5G NSA LEGGERE (solo TCP e QoS)..."
    try {
        netsh int tcp set global autotuninglevel=restricted | Out-Null
        netsh int tcp set global chimney=disabled | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global ecncapability=enabled | Out-Null
        netsh int tcp set global timestamps=disabled | Out-Null
        netsh int tcp set global rsc=disabled | Out-Null
        netsh int tcp set global nonsackrttresiliency=disabled | Out-Null
        netsh int tcp set global maxsynretransmissions=2 | Out-Null
        netsh int tcp set global initialRto=200 | Out-Null
        Write-Log "TCP ottimizzato per 5G NSA."
    } catch {
        Write-Log "Errore durante l'ottimizzazione TCP: $($_.Exception.Message)"
    }
    try {
        netsh int ipv4 set global sourceroutingbehavior=drop | Out-Null
        netsh int ipv4 set global taskoffload=disabled | Out-Null
        Write-Log "UDP ottimizzato per TruckersMP."
    } catch {
        Write-Log "Errore durante l'ottimizzazione UDP: $($_.Exception.Message)"
    }
    try {
        ipconfig /flushdns | Out-Null
        netsh interface ip delete arpcache | Out-Null
        Write-Log "DNS e ARP cache svuotati."
    } catch {
        Write-Log "Errore durante il flush DNS/ARP: $($_.Exception.Message)"
    }
    $uploadLimit = 34000
    netsh interface qos delete policy "AntiBufferbloat" 2>$null | Out-Null
    try {
        netsh interface qos add policy "AntiBufferbloat" `
            throttle=$uploadLimit `
            name=any `
            description="QoS Anti-Bufferbloat 5G NSA" | Out-Null
        Write-Log "QoS Anti-Bufferbloat applicato (Upload limit: $uploadLimit Kbps)."
    } catch {
        Write-Log "Errore durante la creazione QoS: $($_.Exception.Message)"
    }
    Write-Log "Ottimizzazioni 5G NSA LEGGERE completate."
}

function Ripristina-5GNSA {
    Write-Log "Ripristino impostazioni 5G NSA LEGGERE (solo TCP e QoS)..."
    try {
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global chimney=default | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global ecncapability=disabled | Out-Null
        netsh int tcp set global timestamps=enabled | Out-Null
        netsh int tcp set global rsc=enabled | Out-Null
        netsh int tcp set global nonsackrttresiliency=enabled | Out-Null
        netsh int tcp set global maxsynretransmissions=3 | Out-Null
        netsh int tcp set global initialRto=3000 | Out-Null
        Write-Log "TCP ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino TCP: $($_.Exception.Message)"
    }
    try {
        netsh int ipv4 set global sourceroutingbehavior=accept | Out-Null
        netsh int ipv4 set global taskoffload=enabled | Out-Null
        Write-Log "UDP ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino UDP: $($_.Exception.Message)"
    }
    try {
        netsh interface qos delete policy "AntiBufferbloat" 2>$null | Out-Null
        Write-Log "QoS Anti-Bufferbloat rimosso."
    } catch {
        Write-Log "Errore durante la rimozione QoS: $($_.Exception.Message)"
    }
    Write-Log "Ripristino 5G NSA LEGGERE completato."
}

# ============================
#   FUNZIONE: BACKUP DRIVER IN KDRIVE (DIRETTAMENTE IN kDrive)
# ============================
function Backup-DriverInKDrive {
    Write-Log "Avvio backup driver in kDrive..."
    $dest = "C:\Users\tiber\kDrive\Backup Driver"

    # Crea la cartella di destinazione se non esiste
    if (!(Test-Path $dest)) {
        Write-Log "Cartella di destinazione non esiste. Creazione..."
        New-Item -ItemType Directory -Path $dest -ErrorAction Stop | Out-Null
    }

    try {
        # Esegui export driver con DISM
        Write-Log "Esportazione driver con DISM..."
        $dismCmd = "dism /online /export-driver /destination:`"$dest`""
        $result = Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"$dismCmd`"" -Wait -PassThru

        Write-Log "DISM completato con exit code: $($result.ExitCode)"

        if ($result.ExitCode -eq 0) {
            Write-Log "Backup driver completato in: $dest"
            $TxtStatus.Text = "Backup driver completato in kDrive."
        } else {
            Write-Log "Errore durante il backup driver (exit code: $($result.ExitCode))"
            $TxtStatus.Text = "Errore durante il backup driver."
        }
    } catch {
        Write-Log "Errore durante il backup driver: $($_.Exception.Message)"
        $TxtStatus.Text = "Errore durante il backup driver."
    }
}

# ============================
#   FUNZIONE: BACKUP DOCUMENTI IN KDRIVE (CON ROBOCOPY)
# ============================
function Backup-DocumentiInKDrive {
    Write-Log "Avvio backup documenti in kDrive..."
    $source = "C:\Users\tiber\Documents"
    $dest = "C:\Users\tiber\kDrive\backup documenti"

    # Crea la cartella di destinazione se non esiste
    if (!(Test-Path $dest)) {
        Write-Log "Cartella di destinazione non esiste. Creazione..."
        New-Item -ItemType Directory -Path $dest -ErrorAction Stop | Out-Null
    }

    try {
        Write-Log "Esecuzione robocopy..."
        $robocopyCmd = "robocopy `"$source`" `"$dest`" /E /XO /R:2 /W:2 /FFT /Z /XA:SH"
        $result = Start-Process robocopy -ArgumentList "/E /XO /R:2 /W:2 /FFT /Z /XA:SH `"$source`" `"$dest`"" -Wait -PassThru

        Write-Log "robocopy completato con exit code: $($result.ExitCode)"

        if ($result.ExitCode -le 1) {
            Write-Log "Backup documenti completato con successo."
            $TxtStatus.Text = "Backup documenti completato."
        } else {
            Write-Log "Errore durante il backup documenti (exit code: $($result.ExitCode))"
            $TxtStatus.Text = "Errore durante il backup documenti."
        }
    } catch {
        Write-Log "Errore durante il backup documenti: $($_.Exception.Message)"
        $TxtStatus.Text = "Errore durante il backup documenti."
    }
}

# ============================
#   FUNZIONE: RIPARA SISTEMA
# ============================
function Ripara-Sistema {
    Write-Log "Avvio riparazione sistema..."
    Update-ProgressBar -Value 10 -Status "Controllo integrità file di sistema..."

    try {
        # SFC
        Write-Log "Esecuzione sfc /scannow..."
        $sfcResult = Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"sfc /scannow`"" -Wait -PassThru
        Write-Log "sfc completato con exit code: $($sfcResult.ExitCode)"

        # DISM
        Update-ProgressBar -Value 50 -Status "Riparazione immagine sistema..."
        Write-Log "Esecuzione DISM..."
        $dismCmd = "dism /online /cleanup-image /restorehealth"
        $dismResult = Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"$dismCmd`"" -Wait -PassThru
        Write-Log "DISM completato con exit code: $($dismResult.ExitCode)"

        # Chkdsk (opzionale)
        Update-ProgressBar -Value 80 -Status "Controllo disco (opzionale)..."
        Write-Log "Chkdsk non eseguito automaticamente. Avvia manualmente se necessario."

        Update-ProgressBar -Value 100 -Status "Riparazione sistema completata."
        $TxtStatus.Text = "Riparazione sistema completata."
    } catch {
        Write-Log "Errore durante la riparazione sistema: $($_.Exception.Message)"
        $TxtStatus.Text = "Errore durante la riparazione sistema."
    }
}

# ============================
#   FUNZIONE: CONTROLLA ETS2
# ============================
function Controlla-ETS2 {
    $proc = Get-Process | Where-Object { $_.ProcessName -like "*eurotruck*" -or $_.ProcessName -like "*ets2*" } -ErrorAction SilentlyContinue
    return $proc -ne $null
}

# ============================
#   TIMER PER RILEVAMENTO ETS2
# ============================
$global:GamingBoostAttivo = $false
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(5)

$timer.Add_Tick({
    if (Controlla-ETS2) {
        if (-not $global:GamingBoostAttivo) {
            Write-Log "ETS2 rilevato → Avvio Gaming Boost PLUS + Ottimizzazione Rete"
            Chiudi-ProcessiNonNecessari
            Ottimizza-Ping
            Ottimizza-5GNSA
            $TxtStatus.Text = "Gaming Boost PLUS + Rete ottimizzata (ETS2 rilevato)"
            $global:GamingBoostAttivo = $true
        }
    }
    else {
        if ($global:GamingBoostAttivo) {
            Write-Log "ETS2 chiuso → Ripristino completo"
            Ripristina-ProcessiERete
            Ripristina-5GNSA
            $TxtStatus.Text = "Ripristino completo (ETS2 chiuso)"
            $global:GamingBoostAttivo = $false
        }
    }
})

# ============================
#   GUI XAML (AGGIORNATA)
# ============================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       Title="Tiberio Edition V6-Light-Plus-Full-Ready" Height="580" Width="720"
       WindowStartupLocation="CenterScreen"
       Background="#F3F3F3"
       ResizeMode="NoResize">

   <Grid Margin="20">
       <Grid.RowDefinitions>
           <RowDefinition Height="Auto"/>
           <RowDefinition Height="*"/>
           <RowDefinition Height="Auto"/>
       </Grid.RowDefinitions>

       <TextBlock Text="Tiberio Edition V6-Light-Plus-Full-Ready"
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
               <Button x:Name="BtnRiparazioneSistema" Content="Riparazione Sistema" Height="32" Margin="0,0,0,6"/>
               <Button x:Name="BtnControllaAggiornamenti" Content="Controlla Aggiornamenti" Height="32" Margin="0,10,0,0"/>
           </StackPanel>

           <StackPanel Grid.Column="1" Margin="10,0,0,0">
               <TextBlock Text="Gaming" FontWeight="Bold" Margin="0,0,0,8"/>
               <Button x:Name="BtnGamingBoostPlus" Content="Gaming Boost PLUS" Height="32" Margin="0,0,0,6"/>
               <Button x:Name="BtnOttimizzaRete" Content="Ottimizzazione Rete" Height="32" Margin="0,0,0,6"/>
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
#   PARSING XAML
# ============================
try {
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Error "Errore durante il parsing del XAML: $($_.Exception.Message)"
    Write-Error "Controlla la sintassi del XAML."
    Write-Log "Errore parsing XAML: $($_.Exception.Message)"
    pause
    exit 1
}

# ============================
#   RIFERIMENTI CONTROLLI
# ============================
$BtnPuliziaBase            = $window.FindName("BtnPuliziaBase")
$BtnGamingBoostPlus      = $window.FindName("BtnGamingBoostPlus")
$BtnOttimizzaRete        = $window.FindName("BtnOttimizzaRete")
$BtnEsci                 = $window.FindName("BtnEsci")
$BtnControllaAggiornamenti = $window.FindName("BtnControllaAggiornamenti")
$BtnRiparazioneSistema   = $window.FindName("BtnRiparazioneSistema")
$BtnBackupDriver         = $window.FindName("BtnBackupDriver")
$BtnBackupDocumenti      = $window.FindName("BtnBackupDocumenti")
$TxtStatus               = $window.FindName("TxtStatus")
$ProgressBar             = $window.FindName("ProgressBar")

# ============================
#   FUNZIONE: UPDATE PROGRESS BAR
# ============================
function Update-ProgressBar {
    param([int]$Value, [string]$Status = "")
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
#   HANDLER PULSANTI
# ============================
$BtnPuliziaBase.Add_Click({
    $TxtStatus.Text = "Esecuzione Pulizia Base..."
    Write-Log "Avvio Pulizia Base"
    Update-ProgressBar -Value 10 -Status "Pulizia TEMP utente..."
    $freed = Pulizia-Base
    $MB = [math]::Round($freed / 1MB, 2)
    Update-ProgressBar -Value 100 -Status "Pulizia Base completata. Liberati $MB MB."
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
    Ottimizza-5GNSA
    Update-ProgressBar -Value 100 -Status "Ottimizzazione rete completata."
})

$BtnControllaAggiornamenti.Add_Click({
    $TxtStatus.Text = "Controllo aggiornamenti..."
    Write-Log "Avvio controllo aggiornamenti"
    $url = "https://raw.githubusercontent.com/M4r10685/TiberioEditionV6/main/TiberioEditionV6.ps1"
    $risultato = Controlla-Aggiornamenti -Url $url
    if ($risultato -eq "OK") {
        $TxtStatus.Text = "La versione è già aggiornata."
    } elseif ($risultato -eq "Errore") {
        $TxtStatus.Text = "Errore durante il controllo aggiornamenti."
    } else {
        Write-Log "Aggiornamento disponibile, procedo..."
        if ($MyInvocation.MyCommand.Definition) {
            $percorsoLocale = $MyInvocation.MyCommand.Definition
        } else {
            $percorsoLocale = Join-Path $PSScriptRoot "TiberioEditionV6-Light-Plus-Full-Ready.ps1"
            Write-Log "Avviso: Percorso dello script non determinato. Usato: $percorsoLocale"
        }
        $result = Aggiorna-Script -NuovoContenuto $risultato -PercorsoLocale $percorsoLocale
        if ($result -eq "OK") {
            $TxtStatus.Text = "Aggiornamento completato. Riavvia lo script."
            Update-ProgressBar -Value 100 -Status "Aggiornamento completato. Riavvio in corso..."
            Start-Sleep -Seconds 2
            $window.Close()
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$percorsoLocale`""
        } else {
            $TxtStatus.Text = "Errore durante l'aggiornamento."
        }
    }
})

$BtnRiparazioneSistema.Add_Click({
    $TxtStatus.Text = "Riparazione sistema in corso..."
    Write-Log "Avvio Riparazione Sistema V6"
    Update-ProgressBar -Value 10 -Status "Riparazione sistema in corso..."
    Ripara-Sistema
    Update-ProgressBar -Value 100 -Status "Riparazione sistema completata."
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
#   AVVIO GUI
# ============================
Write-Log "Avvio Tiberio Edition V6-Light-Plus-Full-Ready GUI..."
$timer.Start()
$window.Add_Closed({
    $timer.Stop()
    $timer = $null
})
$window.ShowDialog() | Out-Null

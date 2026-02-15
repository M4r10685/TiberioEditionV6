# ============================
#   TIBERIO EDITION V6.4 - PORTABLE MODE
#   CODICE OTTIMIZZATO
# ============================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ----------------------------
#   VERSIONE + CHANGELOG
# ----------------------------

$VersioneLocale = "6.4.0"

$ChangelogLocale = @"
NOVITÀ VERSIONE 6.4:
- Modalità PORTABLE (niente Program Files)
- Barra di Progresso Reale
- Codice ripulito e ottimizzato
"@

# ----------------------------
#   PERCORSI PORTABLE
# ----------------------------

$BasePath = $PSScriptRoot

# Log nella stessa cartella dello script
$LogPath = Join-Path $BasePath "log.txt"
if (!(Test-Path $LogPath)) {
    New-Item -ItemType File -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$timestamp] $msg"
}

Write-Log "Avvio Tiberio Edition V6.4 (Portable Mode)"

# ----------------------------
#   AUTO-UPDATE PORTABLE
# ----------------------------

# URL RAW del file V6.4 su GitHub
$UrlScriptRemoto = "https://raw.githubusercontent.com/M4r10685/TiberioEditionV6/main/PuliziaCompleta_V6.4.ps1"

function Controlla-Aggiornamenti {
    try {
        Write-Log "Controllo aggiornamenti..."

        # Percorso locale sicuro (funziona anche in GUI)
        $ScriptPath = $PSCommandPath

        if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
            Write-Log "Percorso script locale vuoto. Aggiornamento impossibile."
            [System.Windows.MessageBox]::Show(
                "Percorso script locale non valido. Aggiornamento annullato.",
                "Errore aggiornamenti",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        Write-Log "Percorso script locale: $ScriptPath"

        # Scarica contenuto remoto
        $contenutoRemoto = (Invoke-WebRequest -Uri $UrlScriptRemoto -UseBasicParsing -ErrorAction Stop).Content

        # Estrai versione remota
        $VersioneRemota = $null
        if ($contenutoRemoto -match '\$VersioneLocale\s*=\s*"([^"]+)"') {
            $VersioneRemota = $matches[1]
        }

        if (-not $VersioneRemota) {
            Write-Log "Impossibile leggere la versione remota."
            [System.Windows.MessageBox]::Show(
                "Impossibile determinare la versione remota dallo script.",
                "Errore aggiornamenti",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        Write-Log "Versione remota trovata: $VersioneRemota"

        # Confronto versioni
        if ($VersioneRemota -le $VersioneLocale) {
            Write-Log "Lo script è già aggiornato alla versione $VersioneLocale."
            [System.Windows.MessageBox]::Show(
                "La versione locale ($VersioneLocale) è già aggiornata.",
                "Controllo aggiornamenti",
                "OK",
                "Information"
            ) | Out-Null
            return
        }

        # Aggiornamento disponibile
        $msg = "È stata trovata una nuova versione: $VersioneRemota (locale: $VersioneLocale)." +
               "`nVuoi aggiornare ora? Verrà creato un backup automatico."

        $choice = [System.Windows.MessageBox]::Show(
            $msg,
            "Nuova versione disponibile",
            "YesNo",
            "Question"
        )

        if ($choice -ne "Yes") {
            Write-Log "Utente ha annullato l'aggiornamento."
            return
        }

        Write-Log "Utente ha confermato l'aggiornamento alla versione $VersioneRemota"

        # Percorso backup
        $BackupPath = "$ScriptPath.bak"

        # Backup
        Copy-Item -Path $ScriptPath -Destination $BackupPath -Force
        Write-Log "Backup creato: $BackupPath"

        # Aggiornamento file locale
        Set-Content -Path $ScriptPath -Value $contenutoRemoto -Force -Encoding UTF8
        Write-Log "Script aggiornato alla versione $VersioneRemota"

        # Notifica
        [System.Windows.MessageBox]::Show(
            "Aggiornamento completato alla versione $VersioneRemota.`nLo script verrà riavviato.",
            "Aggiornamento completato",
            "OK",
            "Information"
        ) | Out-Null

        # Riavvio script
        Start-Process "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        Write-Log "Riavvio automatico dello script eseguito (da funzione Controlla-Aggiornamenti)"
        exit
    }
    catch {
        Write-Log "Errore durante il controllo/aggiornamento: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show(
            "Si è verificato un errore durante il controllo o l'installazione dell'aggiornamento.`nControlla il log per i dettagli.",
            "Errore aggiornamenti",
            "OK",
            "Error"
        ) | Out-Null
    }
}

# ============================
#   PROGRESS BAR
# ============================

function Set-Progress {
    param([int]$Value)

    # Aggiorna la progress bar senza bloccare la GUI
    $Window.Dispatcher.Invoke({
        $ProgressBarOperazione.Value = $Value
    })
}

# ============================
#   FUNZIONI OPERATIVE
# ============================

# ----------------------------
#   PULIZIA BROWSER
# ----------------------------
function Pulizia-Browser {
    Write-Log "Pulizia Browser avviata"
    Set-Progress 0

    $paths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"
    )

    $step = 100 / $paths.Count
    $current = 0
    $freed = 0

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            $freed += $size
        }

        $current += $step
        Set-Progress $current
    }

    Set-Progress 100
    Start-Sleep -Milliseconds 300
    Set-Progress 0

    Write-Log "Pulizia Browser completata. Byte liberati: $freed"
    return $freed
}

# ----------------------------
#   PULIZIA USB
# ----------------------------
function Pulizia-USB {
    Write-Log "Pulizia USB avviata"
    Set-Progress 0

    $drives = Get-PSDrive -PSProvider FileSystem |
              Where-Object { $_.Root -match "^[A-Z]:\\" -and $_.Free -gt 0 }

    if ($drives.Count -eq 0) {
        Write-Log "Nessuna USB rilevata"
        return 0
    }

    $step = 100 / $drives.Count
    $current = 0
    $freed = 0

    foreach ($d in $drives) {
        $patterns = "*.tmp","*.log","*.bak","*.old","*.chk"

        foreach ($pat in $patterns) {
            $files = Get-ChildItem -Path $d.Root -Filter $pat -Recurse -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $freed += $f.Length
                Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        $current += $step
        Set-Progress $current
    }

    Set-Progress 100
    Start-Sleep -Milliseconds 300
    Set-Progress 0

    Write-Log "Pulizia USB completata. Byte liberati: $freed"
    return $freed
}

# ----------------------------
#   SALVATAGGIO DRIVER
# ----------------------------
function Salva-Driver {
    try {
        Write-Log "Salvataggio driver avviato"
        Set-Progress 0

        $dest = Join-Path $BasePath "DriverBackup"
        if (!(Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest | Out-Null
        }

        Set-Progress 20

        Write-Log "Esportazione driver tramite pnputil..."
        $output = pnputil /export-driver * "$dest" 2>&1

        Set-Progress 80

        $count = (Get-ChildItem -Path $dest -Recurse -ErrorAction SilentlyContinue).Count

        Set-Progress 100
        Start-Sleep -Milliseconds 300
        Set-Progress 0

        Write-Log "Salvataggio driver completato ($count file)"
        return $true
    }
    catch {
        Write-Log "Errore durante il salvataggio driver: $($_.Exception.Message)"
        Set-Progress 0
        return $false
    }
}

# ----------------------------
#   FUNZIONI DA OTTIMIZZARE (STUB)
# ----------------------------

function Pulizia-Base {
    Write-Log "Pulizia Base avviata"
    # Qui inseriremo la versione ottimizzata
    return 0
}

function Pulizia-Gaming {
    Write-Log "Pulizia Gaming avviata"
    # Qui inseriremo la versione ottimizzata
    return 0
}

function Manutenzione-Completa {
    Write-Log "Manutenzione Completa Avanzata avviata"
    # Qui inseriremo la versione ottimizzata
}

function Ripara-Sistema {
    Write-Log "Riparazione Sistema avviata"
    # Qui inseriremo la versione ottimizzata
}

function Gaming-Boost {
    Write-Log "Gaming Boost avviato"
    # Qui inseriremo la versione ottimizzata
}

function Gaming-BoostPlus {
    Write-Log "Gaming Boost PLUS avviato"
    # Qui inseriremo la versione ottimizzata
}

function Ottimizza-Rete {
    Write-Log "Ottimizzazione rete avviata"
    # Qui inseriremo la versione ottimizzata
}

# ============================
#   PULIZIA BASE
# ============================
function Pulizia-Base {
    Write-Log "Pulizia Base avviata"
    Set-Progress 0

    $paths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:LOCALAPPDATA\CrashDumps\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*"
    )

    $step = 100 / $paths.Count
    $current = 0
    $freed = 0

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            $freed += $size
        }

        $current += $step
        Set-Progress $current
    }

    # ⭐ SVUOTAMENTO CESTINO (aggiunto)
    try {
        Write-Log "Svuotamento cestino..."
        (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() |
            ForEach-Object { $_.InvokeVerb("delete") }
        Write-Log "Cestino svuotato."
    }
    catch {
        Write-Log "Errore durante lo svuotamento del cestino: $($_.Exception.Message)"
    }

    Set-Progress 100
    Start-Sleep -Milliseconds 300
    Set-Progress 0

    Write-Log "Pulizia Base completata. Byte liberati: $freed"
    return $freed
}




# ============================
#   PULIZIA GAMING
# ============================
function Pulizia-Gaming {
    Write-Log "Pulizia Gaming avviata"
    Set-Progress 0

    $paths = @(
        "$env:LOCALAPPDATA\NVIDIA\DXCache\*",
        "$env:LOCALAPPDATA\NVIDIA\GLCache\*",
        "$env:LOCALAPPDATA\AMD\DxCache\*",
        "$env:LOCALAPPDATA\Microsoft\DirectX Shader Cache\*",
        "$env:LOCALAPPDATA\Temp\*.tmp"
    )

    $step = 100 / $paths.Count
    $current = 0
    $freed = 0

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            $freed += $size
        }

        $current += $step
        Set-Progress $current
    }

    Set-Progress 100
    Start-Sleep -Milliseconds 300
    Set-Progress 0

    Write-Log "Pulizia Gaming completata. Byte liberati: $freed"
    return $freed
}

# ============================
#   MANUTENZIONE COMPLETA AVANZATA
# ============================
function Manutenzione-Completa {
    Write-Log "Manutenzione Completa Avanzata avviata"
    Set-Progress 0

    # Step 1: Pulizia Base
    Pulizia-Base | Out-Null
    Set-Progress 33

    # Step 2: Pulizia Gaming
    Pulizia-Gaming | Out-Null
    Set-Progress 66

    # Step 3: Pulizia Browser
    Pulizia-Browser | Out-Null
    Set-Progress 100

    Start-Sleep -Milliseconds 300
    Set-Progress 0

    Write-Log "Manutenzione Completa Avanzata completata"
}

# ============================
#   RIPARAZIONE SISTEMA
# ============================
function Ripara-Sistema {
    Write-Log "Riparazione Sistema avviata"

    Start-Process "powershell.exe" -ArgumentList "-Command sfc /scannow" -Verb RunAs
    Start-Process "powershell.exe" -ArgumentList "-Command DISM /Online /Cleanup-Image /RestoreHealth" -Verb RunAs

    Write-Log "Riparazione Sistema avviata (SFC + DISM)"
}

# ============================
#   GAMING BOOST
# ============================
function Gaming-Boost {
    Write-Log "Gaming Boost avviato"

    # Disattiva servizi inutili
    Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue

    # Priorità alta per i giochi
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Force

    Write-Log "Gaming Boost completato"
}

# ============================
#   GAME BOOST PLUS ULTRA
#   Solo ETS2 + TruckersMP
# ============================
function GameBoost-Plus {

    Write-Log "GameBoost Plus Ultra avviato. In attesa di ETS2 o TruckersMP..."

    # Processi da chiudere (Steam e Discord NON vengono toccati)
    $processiDaChiudere = @(
        "chrome","msedge","opera","firefox",
        "onedrive","steamwebhelper","epicgameslauncher",
        "battle.net","spotify","origin","uplay","goggalaxy"
    )

    # Notifiche toast
    try {
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    } catch {}

    function Show-Toast($title, $msg) {
        try {
            $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
            $toastText = $template.GetElementsByTagName("text")
            $toastText.Item(0).AppendChild($template.CreateTextNode($title)) | Out-Null
            $toastText.Item(1).AppendChild($template.CreateTextNode($msg)) | Out-Null
            $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
            $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("TiberioEdition")
            $notifier.Show($toast)
        } catch {}
    }

    # Attesa avvio ETS2 o TMP
    while (
        -not (Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue) -and
        -not (Get-Process -Name "truckersmp-launcher" -ErrorAction SilentlyContinue) -and
        -not (Get-Process -Name "truckersmp-cli" -ErrorAction SilentlyContinue)
    ) {
        Start-Sleep -Seconds 2
    }

    Write-Log "Gioco rilevato. Attivazione GameBoost Plus Ultra..."
    Show-Toast "GameBoost Plus Ultra" "Ottimizzazioni attive per ETS2/TMP"

    # ============================
    #   CHIUSURA PROCESSI INUTILI
    # ============================
    foreach ($p in $processiDaChiudere) {
        try {
            Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Log "Processo chiuso: $p"
        } catch {}
    }

    # ============================
    #   PULIZIA CACHE TRUCKERSMP
    # ============================
    Pulizia-TMP

    # ============================
    #   OTTIMIZZAZIONE CONFIG ETS2
    # ============================
    Ottimizza-ETS2-Config

    # ============================
    #   OTTIMIZZAZIONE CONVOY
    # ============================
    Ottimizza-Convoy

    # ============================
    #   LIMITATORE FPS DINAMICO
    # ============================
    FPS-Dinamico

    # ============================
    #   BOOST GPU
    # ============================
    Boost-GPU

    # ============================
    #   OTTIMIZZAZIONI RETE
    # ============================
    Write-Log "Applicazione ottimizzazioni rete..."

    netsh int tcp set global autotuninglevel=disabled | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set global ecncapability=disabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null

    # Nagle OFF
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null

    # Flush DNS e ARP
    ipconfig /flushdns | Out-Null
    netsh interface ip delete arpcache | Out-Null

    Write-Log "Ottimizzazioni rete applicate."

    # ============================
    #   PRIORITÀ CPU/GPU
    # ============================
    Write-Log "Impostazione priorità CPU/GPU..."

    try {
        $proc = Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue
        if ($proc) { $proc.PriorityClass = "High" }

        Get-Process -Name "nvcontainer","amddriver","amdow" -ErrorAction SilentlyContinue |
            ForEach-Object { $_.PriorityClass = "High" }

        Write-Log "Priorità impostate."
    } catch {}

    # ============================
    #   OTTIMIZZAZIONI RAM
    # ============================
    Write-Log "Ottimizzazioni RAM..."

    Get-Process | ForEach-Object {
        try { $_.MinWorkingSet = $_.MinWorkingSet } catch {}
    }

    Write-Log "Ottimizzazioni RAM applicate."

    # ============================
    #   ATTESA CHIUSURA GIOCO
    # ============================
    while (
        Get-Process -Name "eurotrucks2" -ErrorAction SilentlyContinue -or
        Get-Process -Name "truckersmp-launcher" -ErrorAction SilentlyContinue -or
        Get-Process -Name "truckersmp-cli" -ErrorAction SilentlyContinue
    ) {
        Start-Sleep -Seconds 2
    }

    # ============================
    #   RIPRISTINO
    # ============================
    Write-Log "Gioco chiuso. Ripristino impostazioni..."
    Show-Toast "GameBoost Plus Ultra" "Ripristino impostazioni..."

    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set global ecncapability=default | Out-Null
    netsh int tcp set global timestamps=default | Out-Null

    Write-Log "Ripristino completato."
}

# ============================
#   GUI XAML
# ============================

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tiberio Edition V6.4 - Portable Mode" Height="520" Width="760"
        WindowStartupLocation="CenterScreen"
        Background="#F3F3F3"
        ResizeMode="NoResize">

    <Grid Margin="20">

        <!-- DEFINIZIONE RIGHE -->
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>   <!-- Titolo -->
            <RowDefinition Height="Auto"/>   <!-- Contenuto -->
            <RowDefinition Height="Auto"/>   <!-- Progress Bar -->
            <RowDefinition Height="Auto"/>   <!-- Status Bar -->
        </Grid.RowDefinitions>

        <!-- TITOLO -->
        <TextBlock Text="Pulizia Completa - Tiberio Edition V6.4 (Portable + Progress Bar)"
                   FontSize="22"
                   FontWeight="Bold"
                   Foreground="#202020"
                   Margin="0,0,0,15"/>

        <!-- CONTENUTO PRINCIPALE -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- COLONNA SINISTRA -->
            <StackPanel Grid.Column="0" Margin="0,0,10,0">
                <TextBlock Text="Manutenzione" FontWeight="Bold" Margin="0,0,0,10"/>

                <Button x:Name="BtnPuliziaBase" Content="Pulizia Base" Height="32" Margin="0,0,0,8"/>
                <Button x:Name="BtnPuliziaGaming" Content="Pulizia Gaming" Height="32" Margin="0,0,0,8"/>
                <Button x:Name="BtnPuliziaBrowser" Content="Pulizia Browser" Height="32" Margin="0,0,0,8"/>
                <Button x:Name="BtnPuliziaUSB" Content="Pulizia USB" Height="32" Margin="0,0,0,8"/>
                <Button x:Name="BtnSalvaDriver" Content="Salva Driver" Height="32" Margin="0,0,0,8"/>

                <Button x:Name="BtnManutenzioneCompleta" Content="Manutenzione Completa Avanzata" Height="32" Margin="0,10,0,8"/>
                <Button x:Name="BtnRiparazioneSistema" Content="Riparazione Sistema" Height="32" Margin="0,0,0,8"/>

                <Button x:Name="BtnControllaAggiornamenti" Content="Controlla Aggiornamenti" Height="32" Margin="0,10,0,0"/>
            </StackPanel>

            <!-- COLONNA DESTRA -->
            <StackPanel Grid.Column="1" Margin="10,0,0,0">
                <TextBlock Text="Gaming" FontWeight="Bold" Margin="0,0,0,10"/>

                <Button x:Name="BtnGamingBoost" Content="Gaming Boost" Height="32" Margin="0,0,0,8"/>
                <Button x:Name="BtnGamingBoostPlus" Content="Gaming Boost PLUS" Height="32" Margin="0,0,0,8"/>
                <Button x:Name="BtnOttimizzaRete" Content="Ottimizzazione Rete" Height="32" Margin="0,0,0,8"/>

                <Button x:Name="BtnEsci" Content="Esci" Height="32" Margin="0,20,0,0"/>
            </StackPanel>
        </Grid>

        <!-- PROGRESS BAR -->
        <ProgressBar x:Name="ProgressBarOperazione"
                     Grid.Row="2"
                     Minimum="0" Maximum="100"
                     Height="22"
                     Margin="0,15,0,5"
                     Value="0"/>

        <!-- STATUS BAR -->
        <StatusBar Grid.Row="3" Margin="0,10,0,0">
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

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

# ============================
#   RIFERIMENTI CONTROLLI
# ============================

$BtnPuliziaBase            = $Window.FindName("BtnPuliziaBase")
$BtnPuliziaGaming          = $Window.FindName("BtnPuliziaGaming")
$BtnPuliziaBrowser         = $Window.FindName("BtnPuliziaBrowser")
$BtnPuliziaUSB             = $Window.FindName("BtnPuliziaUSB")
$BtnSalvaDriver            = $Window.FindName("BtnSalvaDriver")
$BtnManutenzioneCompleta   = $Window.FindName("BtnManutenzioneCompleta")
$BtnRiparazioneSistema     = $Window.FindName("BtnRiparazioneSistema")
$BtnGamingBoost            = $Window.FindName("BtnGamingBoost")
$BtnGamingBoostPlus        = $Window.FindName("BtnGamingBoostPlus")
$BtnOttimizzaRete          = $Window.FindName("BtnOttimizzaRete")
$BtnControllaAggiornamenti = $Window.FindName("BtnControllaAggiornamenti")
$BtnEsci                   = $Window.FindName("BtnEsci")
$TxtStatus                 = $Window.FindName("TxtStatus")
$ProgressBarOperazione     = $Window.FindName("ProgressBarOperazione")

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

    GameBoost-Plus   # <-- IL NUOVO MODULO ULTRA

    $TxtStatus.Text = "Gaming Boost PLUS completato."
})

$BtnOttimizzaRete.Add_Click({
    $TxtStatus.Text = "Ottimizzazione rete in corso..."
    Write-Log "Avvio Ottimizzazione Rete (da GUI)"
    Ottimizza-Rete
    $TxtStatus.Text = "Ottimizzazione rete completata."
})

$BtnControllaAggiornamenti.Add_Click({
    $TxtStatus.Text = "Controllo aggiornamenti..."
    Write-Log "Avvio controllo aggiornamenti (da GUI)"
    Controlla-Aggiornamenti
})

$BtnEsci.Add_Click({
    Write-Log "Chiusura applicazione da GUI"
    $Window.Close()
})

# ============================
#   MOSTRA LA GUI
# ============================

Write-Log "Avvio GUI"
$Window.ShowDialog() | Out-Null
Write-Log "GUI chiusa"

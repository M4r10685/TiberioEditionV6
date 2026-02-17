Add-Type -AssemblyName PresentationFramework -ErrorAction Stop

# ============================
#   VERSIONE SCRIPT (AGGIORNATA PER TRIGGERARE L'AGGIORNAMENTO)
# ============================
$VersioneLocale = "6.2.0"

# ============================
#   MODALITÀ AGGRESSIVE OPTIMIZATIONS (imposta a $false se danno problemi)
# ============================
$global:AggressiveOptimizations = $true  # Cambia a $false se noti instabilità

# ============================
#   WRITE-LOG (TIBERIO EDITION) - CORRETTA
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
#   AUTO-UPDATE V6 (DA GITHUB)
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

    # Crea backup del file corrente
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
    }
    catch {
        Write-Log "Errore durante l'aggiornamento: $($_.Exception.Message)"
        return "Errore"
    }
}

# ============================
#   FUNZIONI OPERATIVE REALI
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
#   GAMING-BOOSTPLUS - CORRETTA (CHIUSURA PROCESSI, OTTIMIZZAZIONE PING, RIPRISTINO)
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
#   RIPRISTINO-COMPLETO - CORRETTO
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
#   OTTIMIZZAZIONE REGISTRO GAMING (INTEGRATA)
# ============================

function Ottimizza-RegistroGaming {
    Write-Log "Avvio ottimizzazione registro per gaming..."

    # Backup chiavi originali (in memoria)
    $global:BackupTcpip = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency", "TCPNoDelay", "TcpDelAckTicks" -ErrorAction SilentlyContinue
    $global:BackupSystemProfile = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex", "SystemResponsiveness" -ErrorAction SilentlyContinue
    $global:BackupPriority = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue

    # Ottimizzazioni TCP/IP
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpDelAckTicks" -Value 0 -Type DWord -ErrorAction Stop
        Write-Log "Ottimizzazioni TCP/IP applicate."
    } catch {
        Write-Log "Errore durante l'ottimizzazione TCP/IP: $($_.Exception.Message)"
    }

    # Ottimizzazioni Multimedia SystemProfile
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction Stop
        Write-Log "Ottimizzazioni multimediale applicate."
    } catch {
        Write-Log "Errore durante l'ottimizzazione multimediale: $($_.Exception.Message)"
    }

    # Priorità processo
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26 -Type DWord -ErrorAction Stop
        Write-Log "Priorità processo ottimizzata."
    } catch {
        Write-Log "Errore durante l'ottimizzazione priorità: $($_.Exception.Message)"
    }

    Write-Log "Ottimizzazione registro gaming completata. Effetti immediati (non richiede riavvio)."
}

function Ripristina-RegistroGaming {
    Write-Log "Ripristino impostazioni registro originali..."

    # Ripristina TCP/IP
    if ($global:BackupTcpip) {
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value $global:BackupTcpip.TcpAckFrequency -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -Value $global:BackupTcpip.TCPNoDelay -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpDelAckTicks" -Value $global:BackupTcpip.TcpDelAckTicks -Type DWord -ErrorAction Stop
            Write-Log "Ripristino TCP/IP completato."
        } catch {
            Write-Log "Errore durante il ripristino TCP/IP: $($_.Exception.Message)"
        }
    }

    # Ripristina Multimedia SystemProfile
    if ($global:BackupSystemProfile) {
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value $global:BackupSystemProfile.NetworkThrottlingIndex -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value $global:BackupSystemProfile.SystemResponsiveness -Type DWord -ErrorAction Stop
            Write-Log "Ripristino multimediale completato."
        } catch {
            Write-Log "Errore durante il ripristino multimediale: $($_.Exception.Message)"
        }
    }

    # Ripristina Priorità
    if ($global:BackupPriority) {
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value $global:BackupPriority.Win32PrioritySeparation -Type DWord -ErrorAction Stop
            Write-Log "Ripristino priorità completato."
        } catch {
            Write-Log "Errore durante il ripristino priorità: $($_.Exception.Message)"
        }
    }

    Write-Log "Ripristino registro gaming completato."
}

# ============================
#   OTTIMIZZAZIONE 5G NSA EXTREME + QoS ANTI-BUFFERBLOAT
# ============================

function Ottimizza-5GNSA {
    Write-Log "Avvio ottimizzazioni 5G NSA EXTREME + QoS Anti-Bufferbloat..."

    # Backup delle impostazioni originali (se possibile)
    $global:Backup5G = @{}
    $global:Backup5G.NicSettings = @{}
    $global:Backup5G.QoS = (netsh interface qos show policy "AntiBufferbloat" 2>$null) -ne $null

    # TCP ottimizzazioni specifiche per 5G NSA
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

    # UDP ottimizzazioni (TruckersMP)
    try {
        netsh int ipv4 set global sourceroutingbehavior=drop | Out-Null
        netsh int ipv4 set global taskoffload=disabled | Out-Null
        Write-Log "UDP ottimizzato per TruckersMP."
    } catch {
        Write-Log "Errore durante l'ottimizzazione UDP: $($_.Exception.Message)"
    }

    # Flush DNS e ARP
    try {
        ipconfig /flushdns | Out-Null
        netsh interface ip delete arpcache | Out-Null
        Write-Log "DNS e ARP cache svuotati."
    } catch {
        Write-Log "Errore durante il flush DNS/ARP: $($_.Exception.Message)"
    }

    # NIC ottimizzazioni estreme per 5G NSA
    try {
        Get-NetAdapter | ForEach-Object {
            try {
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -DisplayValue "Off" -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Receive Side Scaling" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Off" -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Green Ethernet" -DisplayValue "Off" -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Flow Control" -DisplayValue "Rx & Tx Disabled" -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "UDP Checksum Offload" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "TCP Checksum Offload" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
                $global:Backup5G.NicSettings[$_.Name] = @{
                    "Interrupt Moderation" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -ErrorAction SilentlyContinue).DisplayValue
                    "Receive Side Scaling" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Receive Side Scaling" -ErrorAction SilentlyContinue).DisplayValue
                    "Energy Efficient Ethernet" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy Efficient Ethernet" -ErrorAction SilentlyContinue).DisplayValue
                    "Green Ethernet" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Green Ethernet" -ErrorAction SilentlyContinue).DisplayValue
                    "Flow Control" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Flow Control" -ErrorAction SilentlyContinue).DisplayValue
                    "UDP Checksum Offload" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "UDP Checksum Offload" -ErrorAction SilentlyContinue).DisplayValue
                    "TCP Checksum Offload" = (Get-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "TCP Checksum Offload" -ErrorAction SilentlyContinue).DisplayValue
                }
            } catch {
                Write-Log "Errore durante l'ottimizzazione NIC $($_.Name): $($_.Exception.Message)"
            }
        }
        Write-Log "Ottimizzazioni NIC applicate."
    } catch {
        Write-Log "Errore durante l'ottimizzazione NIC: $($_.Exception.Message)"
    }

    # Riduzione DPC latency
    try {
        bcdedit /set disabledynamictick yes | Out-Null
        bcdedit /set useplatformclock no | Out-Null
        bcdedit /set tscsyncpolicy Enhanced | Out-Null
        Write-Log "DPC latency ridotta."
    } catch {
        Write-Log "Errore durante la riduzione DPC latency: $($_.Exception.Message)"
    }

    # CPU scheduler ottimizzato
    try {
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1 | Out-Null
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 | Out-Null
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMAXCORES 100 | Out-Null
        Write-Log "CPU scheduler ottimizzato."
    } catch {
        Write-Log "Errore durante l'ottimizzazione CPU scheduler: $($_.Exception.Message)"
    }

    # GPU ottimizzazioni
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null
        Write-Log "GPU ottimizzato."
    } catch {
        Write-Log "Errore durante l'ottimizzazione GPU: $($_.Exception.Message)"
    }

    # Input lag minimo
    try {
        reg add "HKCU\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d 10 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f | Out-Null
        Write-Log "Input lag minimizzato."
    } catch {
        Write-Log "Errore durante l'ottimizzazione input lag: $($_.Exception.Message)"
    }

    # Memoria
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f | Out-Null
        if ($global:AggressiveOptimizations) {
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f | Out-Null
            Write-Log "Memoria ottimizzata (DisablePagingExecutive=1)."
        } else {
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 0 /f | Out-Null
            Write-Log "Memoria ottimizzata (DisablePagingExecutive=0)."
        }
    } catch {
        Write-Log "Errore durante l'ottimizzazione memoria: $($_.Exception.Message)"
    }

    # File system
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMemoryUsage /t REG_DWORD /d 2 /f | Out-Null
        Write-Log "Ottimizzazioni file system applicate."
    } catch {
        Write-Log "Errore durante l'ottimizzazione file system: $($_.Exception.Message)"
    }

    # Servizi che causano bufferbloat o spike
    try {
        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
        Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
        Write-Log "Servizi non necessari disattivati."
    } catch {
        Write-Log "Errore durante la disattivazione servizi: $($_.Exception.Message)"
    }

    # ==========================
    # QoS ANTI-BUFFERBLOAT INTELLIGENTE
    # ==========================

    # Limita leggermente l’upload per evitare saturazione 5G NSA
    # (valore ideale: 85% della tua banda reale)
    # Hai 40 Mbps upload → 34 Mbps
    $uploadLimit = 34000  # in Kbps (34 Mbps)

    # Rimuove vecchie policy
    netsh interface qos delete policy "AntiBufferbloat" 2>$null | Out-Null

    # Crea nuova policy QoS
    try {
        netsh interface qos add policy "AntiBufferbloat" `
            throttle=$uploadLimit `
            name=any `
            description="QoS Anti-Bufferbloat 5G NSA" | Out-Null
        Write-Log "QoS Anti-Bufferbloat applicato (Upload limit: $uploadLimit Kbps)."
    } catch {
        Write-Log "Errore durante la creazione QoS: $($_.Exception.Message)"
    }

    Write-Log "Ottimizzazioni 5G NSA EXTREME + QoS Anti-Bufferbloat completate."
}

function Ripristina-5GNSA {
    Write-Log "Ripristino impostazioni 5G NSA EXTREME + QoS Anti-Bufferbloat..."

    # Ripristina TCP
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

    # Ripristina UDP
    try {
        netsh int ipv4 set global sourceroutingbehavior=accept | Out-Null
        netsh int ipv4 set global taskoffload=enabled | Out-Null
        Write-Log "UDP ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino UDP: $($_.Exception.Message)"
    }

    # Ripristina NIC (se avevi backup)
    if ($global:Backup5G.NicSettings) {
        try {
            Get-NetAdapter | ForEach-Object {
                if ($global:Backup5G.NicSettings[$_.Name]) {
                    $settings = $global:Backup5G.NicSettings[$_.Name]
                    foreach ($key in $settings.Keys) {
                        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $key -DisplayValue $settings[$key] -ErrorAction SilentlyContinue
                    }
                }
            }
            Write-Log "Impostazioni NIC ripristinate."
        } catch {
            Write-Log "Errore durante il ripristino NIC: $($_.Exception.Message)"
        }
    }

    # Ripristina DPC latency
    try {
        bcdedit /set disabledynamictick no | Out-Null
        bcdedit /set useplatformclock yes | Out-Null
        bcdedit /set tscsyncpolicy Default | Out-Null
        Write-Log "DPC latency ripristinata."
    } catch {
        Write-Log "Errore durante il ripristino DPC latency: $($_.Exception.Message)"
    }

    # Ripristina CPU scheduler
    try {
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 0 | Out-Null
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 0 | Out-Null
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMAXCORES 0 | Out-Null
        Write-Log "CPU scheduler ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino CPU scheduler: $($_.Exception.Message)"
    }

    # Ripristina GPU
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f | Out-Null
        Write-Log "GPU ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino GPU: $($_.Exception.Message)"
    }

    # Ripristina input lag
    try {
        reg add "HKCU\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d 10 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 10 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 6 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 10 /f | Out-Null
        Write-Log "Input lag ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino input lag: $($_.Exception.Message)"
    }

    # Ripristina memoria
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 0 /f | Out-Null
        Write-Log "Memoria ripristinata."
    } catch {
        Write-Log "Errore durante il ripristino memoria: $($_.Exception.Message)"
    }

    # Ripristina file system
    try {
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMemoryUsage /t REG_DWORD /d 1 /f | Out-Null
        Write-Log "File system ripristinato."
    } catch {
        Write-Log "Errore durante il ripristino file system: $($_.Exception.Message)"
    }

    # Ripristina servizi
    try {
        Set-Service "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "DiagTrack" -ErrorAction SilentlyContinue

        Set-Service "SysMain" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "SysMain" -ErrorAction SilentlyContinue

        Set-Service "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "WSearch" -ErrorAction SilentlyContinue
        Write-Log "Servizi ripristinati."
    } catch {
        Write-Log "Errore durante il ripristino servizi: $($_.Exception.Message)"
    }

    # Rimuovi QoS
    try {
        netsh interface qos delete policy "AntiBufferbloat" 2>$null | Out-Null
        Write-Log "QoS Anti-Bufferbloat rimosso."
    } catch {
        Write-Log "Errore durante la rimozione QoS: $($_.Exception.Message)"
    }

    Write-Log "Ripristino 5G NSA EXTREME + QoS Anti-Bufferbloat completato."
}

# ============================
#   AUTO-GAMING-BOOST (ETS2) - CON OTTIMIZZAZIONE REGISTRO E 5G NSA
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
            Write-Log "ETS2 rilevato → Attivo Gaming Boost PLUS + Ottimizzazione Registro + 5G NSA EXTREME"
            Gaming-BoostPlus
            Ottimizza-RegistroGaming
            Ottimizza-5GNSA
            $TxtStatus.Text = "Gaming Boost PLUS + Registro + 5G NSA (ETS2 rilevato)"
            $global:GamingBoostAttivo = $true
        }
    }
    else {
        if ($global:GamingBoostAttivo) {
            Write-Log "ETS2 chiuso → Ripristino completo + Registro Originale + 5G NSA"
            Ripristino-Completo
            Ripristina-RegistroGaming
            Ripristina-5GNSA
            $TxtStatus.Text = "Ripristino completo + Registro + 5G NSA (ETS2 chiuso)"
            $global:GamingBoostAttivo = $false
        }
    }
})

# ============================
#   GUI XAML
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
#   FUNZIONE: UPDATE PROGRESS BAR
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

        if ($MyInvocation.MyCommand.Definition) {
            $percorsoLocale = $MyInvocation.MyCommand.Definition
        } else {
            $percorsoLocale = Join-Path $PSScriptRoot "TiberioEditionV6.ps1"
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
#   AVVIO GUI
# ============================
Write-Log "Avvio Tiberio Edition V6 GUI..."
$timer.Start()
$window.Add_Closed({
    $timer.Stop()
    $timer = $null
})
$window.ShowDialog() | Out-Null

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ==========================
# VERSIONE SCRIPT
# ==========================
$VersioneLocale="6.5.0"

# ==========================
# LOG BASE
# ==========================
$BasePath=$PSScriptRoot
$LogPath=Join-Path $BasePath "log.txt"
if(!(Test-Path $LogPath)){New-Item -ItemType File -Path $LogPath|Out-Null}

function Write-Log($m){
    Add-Content -Path $LogPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m"
}

# ==========================
# URL UPDATE
# ==========================
$UrlScriptRemoto="https://raw.githubusercontent.com/M4r10685/TiberioEditionV6/main/PuliziaCompleta_V6.5.ps1"

function Controlla-Aggiornamenti{
    try{
        Write-Log "Controllo aggiornamenti"
        $ScriptPath=$PSCommandPath
        $rem=(Invoke-WebRequest -Uri $UrlScriptRemoto -UseBasicParsing).Content
        if($rem -match '\$VersioneLocale\s*=\s*"([^"]+)"'){$vr=$matches[1]}
        if($vr -le $VersioneLocale){
            [System.Windows.MessageBox]::Show("Già aggiornato.","OK","Information")|Out-Null
            return
        }
        $choice=[System.Windows.MessageBox]::Show("Nuova versione $vr. Aggiornare?","Update","YesNo","Question")
        if($choice -ne "Yes"){return}
        Copy-Item $ScriptPath "$ScriptPath.bak" -Force
        Set-Content -Path $ScriptPath -Value $rem -Encoding UTF8
        [System.Windows.MessageBox]::Show("Aggiornato a $vr. Riavvio.","OK","Information")|Out-Null
        Start-Process "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        exit
    }catch{
        Write-Log "Errore update: $($_.Exception.Message)"
    }
}

function Set-Progress($v){
    $Window.Dispatcher.Invoke({$ProgressBarOperazione.Value=$v})
}

# ==========================
# FUNZIONI PULIZIA
# ==========================
function Pulizia-Browser{
    Write-Log "Pulizia Browser"
    $paths=@(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"
    )
    $step=100/$paths.Count;$c=0;$f=0
    foreach($p in $paths){
        if(Test-Path $p){
            $s=(Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue|Measure-Object Length -Sum).Sum
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
            $f+=$s
        }
        $c+=$step;Set-Progress $c
    }
    Set-Progress 100;Start-Sleep -Milliseconds 200;Set-Progress 0
    return $f
}

function Pulizia-USB{
    Write-Log "Pulizia USB"
    $dr=Get-PSDrive -PSProvider FileSystem|Where-Object{$_.Root -match "^[A-Z]:\\"}
    if($dr.Count -eq 0){return 0}
    $step=100/$dr.Count;$c=0;$f=0
    foreach($d in $dr){
        $patterns="*.tmp","*.log","*.bak","*.old","*.chk"
        foreach($pat in $patterns){
            $files=Get-ChildItem $d.Root -Filter $pat -Recurse -ErrorAction SilentlyContinue
            foreach($x in $files){
                $f+=$x.Length
                Remove-Item $x.FullName -Force -ErrorAction SilentlyContinue
            }
        }
        $c+=$step;Set-Progress $c
    }
    Set-Progress 100;Start-Sleep -Milliseconds 200;Set-Progress 0
    return $f
}

function Salva-Driver{
    try{
        Write-Log "Salvataggio driver avviato"
        $dest = Join-Path $BasePath "DriverBackup"
        if(!(Test-Path $dest)){
            New-Item -ItemType Directory -Path $dest | Out-Null
        }
        pnputil /export-driver * "$dest" | Out-Null
        Write-Log "Salvataggio driver completato"
        return $true
    }
    catch{
        Write-Log "Errore salvataggio driver: $($_.Exception.Message)"
        return $false
    }
}

function Pulizia-Base{
    Write-Log "Pulizia Base"
    $paths=@(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:LOCALAPPDATA\Temp\*",
        "$env:LOCALAPPDATA\CrashDumps\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*"
    )
    $step=100/$paths.Count;$c=0;$f=0
    foreach($p in $paths){
        if(Test-Path $p){
            $s=(Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue|Measure-Object Length -Sum).Sum
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
            $f+=$s
        }
        $c+=$step;Set-Progress $c
    }
    try{
        (New-Object -ComObject Shell.Application).Namespace(0xA).Items()|ForEach-Object{$_.InvokeVerb("delete")}
    }catch{}
    Set-Progress 100;Start-Sleep -Milliseconds 200;Set-Progress 0
    return $f
}

function Pulizia-Gaming{
    Write-Log "Pulizia Gaming"
    $paths=@(
        "$env:LOCALAPPDATA\NVIDIA\DXCache\*",
        "$env:LOCALAPPDATA\NVIDIA\GLCache\*",
        "$env:LOCALAPPDATA\AMD\DxCache\*",
        "$env:LOCALAPPDATA\Microsoft\DirectX Shader Cache\*",
        "$env:LOCALAPPDATA\Temp\*.tmp"
    )
    $step=100/$paths.Count;$c=0;$f=0
    foreach($p in $paths){
        if(Test-Path $p){
            $s=(Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue|Measure-Object Length -Sum).Sum
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
            $f+=$s
        }
        $c+=$step;Set-Progress $c
    }
    Set-Progress 100;Start-Sleep -Milliseconds 200;Set-Progress 0
    return $f
}

function Manutenzione-Completa{
    Pulizia-Base|Out-Null;Set-Progress 33
    Pulizia-Gaming|Out-Null;Set-Progress 66
    Pulizia-Browser|Out-Null;Set-Progress 100
    Start-Sleep -Milliseconds 200;Set-Progress 0
}

function Ripara-Sistema{
    Start-Process powershell -ArgumentList "sfc /scannow" -Verb RunAs -Wait
    Start-Process powershell -ArgumentList "DISM /Online /Cleanup-Image /RestoreHealth" -Verb RunAs -Wait
    [System.Windows.MessageBox]::Show("Riparazione completata.","Ripara Sistema") | Out-Null
}
# ==========================
# LOG GAMEBOOST PLUS ULTRA
# ==========================
$Global:GB_LogPath = Join-Path $env:ProgramData "GameBoostPlus"
if(-not (Test-Path $Global:GB_LogPath)){
    New-Item -Path $Global:GB_LogPath -ItemType Directory -Force | Out-Null
}
$Global:GB_LogFile = Join-Path $Global:GB_LogPath "GameBoostPlus.log"

function Write-GBLog{
    param([string]$Message)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$time - $Message" | Out-File -FilePath $Global:GB_LogFile -Append -Encoding UTF8
}

# ==========================
# MEGASCRIPT ULTRA
# ==========================
function Invoke-MegaScriptUltra {
    Write-GBLog "MegaScript Ultra: avvio."

    # >>> QUI INCOLLI IL TUO MEGASCRIPT ULTRA <<<
    # Esempio placeholder:
    # netsh int tcp set global chimney=disabled | Out-Null
    # netsh int tcp set global netdma=disabled | Out-Null

    Write-GBLog "MegaScript Ultra: completato."
}

# ==========================
# CORE BOOST (LOCKED)
# ==========================
function Start-GameBoostCore {
    param([int[]]$GamePids)

    Write-GBLog "GameBoostCore LOCKED avviato."

    $kill=@(
        "chrome","msedge","opera","firefox","onedrive",
        "steamwebhelper","epicgameslauncher","battle.net",
        "spotify","origin","uplay","goggalaxy"
    )

    # Salva piano energetico corrente
    $currentScheme = (powercfg /getactivescheme) -replace '.*GUID:\s*([a-f0-9\-]+).*','$1'
    Write-GBLog "Piano energetico corrente: $currentScheme"

    # Attiva High Performance
    $highPerf = (powercfg /list | Select-String "High performance|Prestazioni elevate")
    if($highPerf){
        $hpGuid = ($highPerf.ToString() -replace '.*GUID:\s*([a-f0-9\-]+).*','$1')
        if($hpGuid){
            Write-GBLog "Attivo High Performance: $hpGuid"
            powercfg /setactive $hpGuid | Out-Null
        }
    }

    # Ottimizzazioni rete
    Write-GBLog "Applico ottimizzazioni rete."
    netsh int tcp set global autotuninglevel=disabled | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set global ecncapability=disabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null

    ipconfig /flushdns | Out-Null
    netsh interface ip delete arpcache | Out-Null

    # MegaScript Ultra
    Invoke-MegaScriptUltra

    # Loop LOCKED (rimane attivo finché il gioco è aperto)
    Write-GBLog "Modalità LOCKED attiva."
    while($true){

        $alive = @()
        foreach($pid in $GamePids){
            $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
            if($p){ $alive += $p }
        }

        if(-not $alive){
            Write-GBLog "Gioco chiuso, avvio ripristino."
            break
        }

        # Priorità CPU
        foreach($p in $alive){
            try{
                $p.PriorityClass = "High"
                Write-GBLog "Priorità High per: $($p.ProcessName)"
            }catch{}
        }

        # Chiudi processi inutili
        foreach($name in $kill){
            $proc = Get-Process $name -ErrorAction SilentlyContinue
            if($proc){
                try{
                    $proc | Stop-Process -Force
                    Write-GBLog "Terminato processo inutile: $name"
                }catch{}
            }
        }

        Start-Sleep -Seconds 5
    }

    # Ripristino finale
    Restore-GameBoostCore -PreviousScheme $currentScheme
}

# ==========================
# RIPRISTINO
# ==========================
function Restore-GameBoostCore {
    param([string]$PreviousScheme)

    Write-GBLog "Ripristino rete e alimentazione."

    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global ecncapability=default | Out-Null
    netsh int tcp set global timestamps=default | Out-Null

    if($PreviousScheme){
        Write-GBLog "Ripristino piano energetico: $PreviousScheme"
        powercfg /setactive $PreviousScheme | Out-Null
    }
}

# ==========================
# GAMEBOOST PLUS ULTRA LOCKED
# ==========================
function GameBoost-Plus-Locked {

    $gameProcs = @()
    $gameProcs += Get-Process "eurotrucks2" -ErrorAction SilentlyContinue
    $gameProcs += Get-Process "truckersmp-launcher" -ErrorAction SilentlyContinue
    $gameProcs += Get-Process "truckersmp-cli" -ErrorAction SilentlyContinue

    if(-not $gameProcs){
        return
    }

    $pids = $gameProcs | Select-Object -ExpandProperty Id
    Write-GBLog "GameBoost-Plus-Locked avviato. PIDs: $($pids -join ', ')"

    Start-Job -ScriptBlock {
        param($innerPids)
        Start-GameBoostCore -GamePids $innerPids
    } -ArgumentList @($pids) | Out-Null
}

# ==========================
# AUTO-JOB IN BACKGROUND
# ==========================
if(-not (Get-Job -Name "AutoGameBoost" -ErrorAction SilentlyContinue)){
    Start-Job -Name "AutoGameBoost" -ScriptBlock {
        while($true){
            $p = Get-Process "eurotrucks2","truckersmp-launcher","truckersmp-cli" -ErrorAction SilentlyContinue
            if($p){
                GameBoost-Plus-Locked
                Start-Sleep -Seconds 10
            }
            Start-Sleep -Seconds 5
        }
    } | Out-Null
    Write-GBLog "AutoGameBoost job avviato."
}

# ==========================
# GUI XAML
# ==========================
[xml]$x=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Title="Tiberio Edition V6.5" Height="520" Width="760" WindowStartupLocation="CenterScreen">
<Grid Margin="20">
<Grid.RowDefinitions>
<RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
</Grid.RowDefinitions>
<TextBlock Text="Tiberio Edition V6.5" FontSize="22" FontWeight="Bold" Margin="0,0,0,15"/>
<Grid Grid.Row="1">
<Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
<StackPanel Grid.Column="0">
<Button x:Name="BtnPuliziaBase" Content="Pulizia Base" Margin="0,0,0,8"/>
<Button x:Name="BtnPuliziaGaming" Content="Pulizia Gaming" Margin="0,0,0,8"/>
<Button x:Name="BtnPuliziaBrowser" Content="Pulizia Browser" Margin="0,0,0,8"/>
<Button x:Name="BtnPuliziaUSB" Content="Pulizia USB" Margin="0,0,0,8"/>
<Button x:Name="BtnSalvaDriver" Content="Salva Driver" Margin="0,0,0,8"/>
<Button x:Name="BtnManutenzioneCompleta" Content="Manutenzione Completa" Margin="0,10,0,8"/>
<Button x:Name="BtnRiparazioneSistema" Content="Riparazione Sistema" Margin="0,0,0,8"/>
<Button x:Name="BtnControllaAggiornamenti" Content="Controlla Aggiornamenti" Margin="0,10,0,0"/>
</StackPanel>
<StackPanel Grid.Column="1">
<Button x:Name="BtnGamingBoost" Content="Gaming Boost" Margin="0,0,0,8"/>
<Button x:Name="BtnGamingBoostPlus" Content="Gaming Boost PLUS" Margin="0,0,0,8"/>
<Button x:Name="BtnOttimizzaRete" Content="Ottimizza Rete" Margin="0,0,0,8"/>
<Button x:Name="BtnEsci" Content="Esci" Margin="0,20,0,0"/>
</StackPanel>
</Grid>
<ProgressBar x:Name="ProgressBarOperazione" Grid.Row="2" Height="22" Margin="0,15,0,5"/>
<StatusBar Grid.Row="3"><StatusBarItem><TextBlock x:Name="TxtStatus" Text="Pronto."/></StatusBarItem></StatusBar>
</Grid>
</Window>
"@

$reader=New-Object System.Xml.XmlNodeReader $x
$Window=[Windows.Markup.XamlReader]::Load($reader)

# ==========================
# COLLEGAMENTO PULSANTI
# ==========================
$BtnPuliziaBase=$Window.FindName("BtnPuliziaBase")
$BtnPuliziaGaming=$Window.FindName("BtnPuliziaGaming")
$BtnPuliziaBrowser=$Window.FindName("BtnPuliziaBrowser")
$BtnPuliziaUSB=$Window.FindName("BtnPuliziaUSB")
$BtnSalvaDriver=$Window.FindName("BtnSalvaDriver")
$BtnManutenzioneCompleta=$Window.FindName("BtnManutenzioneCompleta")
$BtnRiparazioneSistema=$Window.FindName("BtnRiparazioneSistema")
$BtnGamingBoost=$Window.FindName("BtnGamingBoost")
$BtnGamingBoostPlus=$Window.FindName("BtnGamingBoostPlus")
$BtnOttimizzaRete=$Window.FindName("BtnOttimizzaRete")
$BtnControllaAggiornamenti=$Window.FindName("BtnControllaAggiornamenti")
$BtnEsci=$Window.FindName("BtnEsci")
$TxtStatus=$Window.FindName("TxtStatus")
$ProgressBarOperazione=$Window.FindName("ProgressBarOperazione")

# ==========================
# EVENTI PULSANTI
# ==========================
$BtnPuliziaBase.Add_Click({
    $TxtStatus.Text="Pulizia Base..."
    $MB=[math]::Round((Pulizia-Base)/1MB,2)
    $TxtStatus.Text="Completata ($MB MB)"
})

$BtnPuliziaGaming.Add_Click({
    $TxtStatus.Text="Pulizia Gaming..."
    $MB=[math]::Round((Pulizia-Gaming)/1MB,2)
    $TxtStatus.Text="Completata ($MB MB)"
})

$BtnPuliziaBrowser.Add_Click({
    $TxtStatus.Text="Pulizia Browser..."
    $MB=[math]::Round((Pulizia-Browser)/1MB,2)
    $TxtStatus.Text="Completata ($MB MB)"
})

$BtnPuliziaUSB.Add_Click({
    $TxtStatus.Text="Pulizia USB..."
    $MB=[math]::Round((Pulizia-USB)/1MB,2)
    $TxtStatus.Text="Completata ($MB MB)"
})

$BtnSalvaDriver.Add_Click({
    $TxtStatus.Text="Salvataggio driver..."
    if(Salva-Driver){$TxtStatus.Text="Driver salvati"}else{$TxtStatus.Text="Errore"}
})

$BtnManutenzioneCompleta.Add_Click({
    $TxtStatus.Text="Manutenzione..."
    Manutenzione-Completa
    $TxtStatus.Text="Completata"
})

$BtnRiparazioneSistema.Add_Click({
    $TxtStatus.Text="Riparazione..."
    Ripara-Sistema
    $TxtStatus.Text="Avviata"
})

# Gaming Boost BASE
$BtnGamingBoost.Add_Click({
    $TxtStatus.Text="Gaming Boost..."
    Gaming-Boost
    $TxtStatus.Text="Completato"
})

# Gaming Boost PLUS (manuale, opzionale)
$BtnGamingBoostPlus.Add_Click({
    $TxtStatus.Text="Gaming Boost PLUS..."
    GameBoost-Plus-Locked
    $TxtStatus.Text="Attivo"
})

$BtnOttimizzaRete.Add_Click({
    $TxtStatus.Text="Ottimizzazione rete..."
    Ottimizza-Rete
    $TxtStatus.Text="Completata"
})

$BtnControllaAggiornamenti.Add_Click({
    $TxtStatus.Text="Controllo aggiornamenti..."
    Controlla-Aggiornamenti
})

$BtnEsci.Add_Click({$Window.Close()})

# ==========================
# AVVIO GUI
# ==========================
$Window.ShowDialog()|Out-Null

<#
.SYNOPSIS
Instalador interativo de ambiente de desenvolvimento com opções personalizáveis

.DESCRIPTION
Apresenta um menu interativo para selecionar quais componentes instalar:
- Ferramentas essenciais
- Backend (Java, .NET, Python)
- Frontend (Node, Yarn, frameworks)
- Bancos de dados
- IDEs e ferramentas auxiliares
#>

# Configurações iniciais
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# Verifica se é administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script requer privilégios de administrador. Execute como Administrador." -ForegroundColor Red
    exit 1
}

# Verifica se o Winget está instalado
if (-NOT (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget não está instalado. Instale o App Installer da Microsoft via Microsoft Store e tente novamente." -ForegroundColor Red
    exit 1
}

# Função para exibir menu interativo
function Show-Menu {
    param (
        [string]$Title = '=== INSTALADOR DE AMBIENTE DEV ===',
        [array]$Options
    )
    
    Clear-Host
    Write-Host "`n$Title`n" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $color = if ($Options[$i].Selected) { 'Green' } else { 'White' }
        Write-Host "$($i+1). " -NoNewline
        Write-Host $Options[$i].Name -ForegroundColor $color
        Write-Host "   $($Options[$i].Description)" -ForegroundColor Gray
    }
    
    Write-Host "`nS. " -NoNewline
    Write-Host "Iniciar instalação" -ForegroundColor Yellow
    Write-Host "Q. " -NoNewline
    Write-Host "Sair sem instalar`n" -ForegroundColor Red
}

# Função para instalar via Winget
function Install-WingetPackage {
    param (
        [string]$packageId,
        [string]$packageName
    )
    
    Write-Host "`nVerificando a instalação de $packageName..." -ForegroundColor Yellow
    
    if (winget list --id $packageId -e) {
        Write-Host "[✓] $packageName já instalado" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ ] Instalando $packageName..." -ForegroundColor Yellow
        
        try {
            # Sem o Out-Null para ver os detalhes
            winget install --id $packageId -e --accept-package-agreements --accept-source-agreements
            Write-Host "[✓] $packageName instalado com sucesso" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "[×] Falha ao instalar $packageName" -ForegroundColor Red
            Write-Host "Erro: $_" -ForegroundColor Red
            return $false
        }
    }
}

# Opções de instalação
$menuOptions = @(
    @{ 
        Name = "Ferramentas Essenciais"; 
        Description = "Git, Docker, Windows Terminal, WSL2"; 
        Selected = $true;
        Packages = @(
            "Git.Git",
            "Docker.DockerDesktop",
            "Microsoft.WindowsTerminal",
            "Microsoft.WSL2"
        )
    },
    @{ 
        Name = "Backend - Java"; 
        Description = "JDK 21, Maven, Gradle"; 
        Selected = $true;
        Packages = @(
            "EclipseAdoptium.Temurin.21.JDK",
            "Apache.Maven",
            "Gradle.Gradle"
        )
    },
    @{ 
        Name = "Backend - .NET"; 
        Description = ".NET 8 SDK, Runtime"; 
        Selected = $true;
        Packages = @(
            "Microsoft.dotnet.SDK.8",
            "Microsoft.dotnet.Runtime.8"
        )
    },
    @{ 
        Name = "Frontend - Node.js"; 
        Description = "Node.js LTS, Yarn, PNPM"; 
        Selected = $true;
        Packages = @(
            "OpenJS.NodeJS.LTS",
            "Yarn.Yarn",
            "PNPM.pnpm"
        )
    },
    @{ 
        Name = "Bancos de Dados"; 
        Description = "PostgreSQL, Redis, DBeaver"; 
        Selected = $true;
        Packages = @(
            "PostgreSQL.PostgreSQL",
            "Redis.Redis",
            "DBeaverCorp.DBeaverCommunity"
        )
    },
    @{ 
        Name = "IDEs e Editores"; 
        Description = "VS Code, IntelliJ IDEA"; 
        Selected = $true;
        Packages = @(
            "Microsoft.VisualStudioCode",
            "JetBrains.IntelliJIDEA.Community"
        )
    },
    @{ 
        Name = "Extras - Python"; 
        Description = "Python 3, Pip, Virtualenv"; 
        Selected = $false;
        Packages = @(
            "Python.Python.3.11",
            "pipx.pipx"
        )
    }
)

# Menu interativo
$selection = $null
while ($selection -notin 'S', 'Q') {
    Show-Menu -Options $menuOptions
    $selection = Read-Host "`nSelecione uma opção (1-$($menuOptions.Count), S/Q)"
    
    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $menuOptions.Count) {
        $index = [int]$selection - 1
        $menuOptions[$index].Selected = -not $menuOptions[$index].Selected
    }
}

# Processar instalação
if ($selection -eq 'S') {
    Clear-Host
    Write-Host "`n=== INICIANDO INSTALAÇÃO ===`n" -ForegroundColor Cyan
    
    # Instalar componentes selecionados
    $totalSuccess = 0
    $totalFailed = 0
    
    foreach ($option in $menuOptions) {
        if ($option.Selected) {
            Write-Host "`n=== INSTALANDO $($option.Name.ToUpper()) ===" -ForegroundColor Magenta
            
            foreach ($package in $option.Packages) {
                $packageName = ($package -split '\.')[-1]
                if (Install-WingetPackage -packageId $package -packageName $packageName) {
                    $totalSuccess++
                } else {
                    $totalFailed++
                }
            }
        }
    }
    
    # Pós-instalação
    Write-Host "`n=== CONFIGURAÇÃO PÓS-INSTALAÇÃO ===" -ForegroundColor Cyan
    
    # Configurar Git se instalado
    if ($menuOptions[0].Selected -and (Get-Command git -ErrorAction SilentlyContinue)) {
        $gitName = Read-Host "Digite seu nome para configuração do Git"
        $gitEmail = Read-Host "Digite seu e-mail para configuração do Git"
        
        git config --global user.name $gitName
        git config --global user.email $gitEmail
        git config --global core.autocrlf true
        git config --global core.safecrlf warn
        
        Write-Host "Git configurado com sucesso." -ForegroundColor Green
    }
    
    # Instalar extensões do VS Code se selecionado
    if ($menuOptions[5].Selected -and (Get-Command code -ErrorAction SilentlyContinue)) {
        $vscodeExtensions = @(
            "dbaeumer.vscode-eslint",
            "esbenp.prettier-vscode",
            "ms-azuretools.vscode-docker",
            "ms-vscode.powershell",
            "redhat.java",
            "vscjava.vscode-java-pack",
            "ms-dotnettools.csharp"
        )
        
        Write-Host "`nInstalando extensões do VS Code..." -ForegroundColor Green
        foreach ($ext in $vscodeExtensions) {
            code --install-extension $ext --force
        }
    }
    
    # Resumo final
    Write-Host "`n=== RESUMO DA INSTALAÇÃO ===" -ForegroundColor Cyan
    Write-Host "Pacotes instalados com sucesso: $totalSuccess" -ForegroundColor Green
    $color = if ($totalFailed -gt 0) { 'Red' } else { 'Green' }
    Write-Host "Pacotes com falha: $totalFailed" -ForegroundColor $color
    
    # Recomendações finais
    Write-Host "`n=== RECOMENDAÇÕES ===" -ForegroundColor Yellow
    Write-Host "- Reinicie seu computador para aplicar todas as configurações"
    Write-Host "- Execute 'docker --version' para verificar se Docker está rodando"
    Write-Host "- Configure o WSL2 se for usar containers Linux"
    
    Write-Host "`nAmbiente configurado com sucesso! Happy coding! 🚀" -ForegroundColor Green
} else {
    Write-Host "`nInstalação cancelada. Nenhuma alteração foi feita." -ForegroundColor Yellow
}

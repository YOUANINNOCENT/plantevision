<#
docker-run.ps1
Script d'aide pour démarrer/arrêter/voir les logs du stack Docker Compose

Usage (depuis le dossier racine du projet `plante`):
  # Démarrer en arrière-plan (build si nécessaire)
  .\docker-run.ps1 up

  # Démarrer et suivre les logs (attach)
  .\docker-run.ps1 up -FollowLogs

  # Arrêter et supprimer les conteneurs
  .\docker-run.ps1 down

  # Afficher les logs
  .\docker-run.ps1 logs

Options:
  -Service <name>    Filtrer les logs sur un service (ex: backend, db)
  -Rebuild           Force le rebuild avant up
  -FollowLogs        Suit les logs après le up

Note: nécessite Docker et Docker Compose installés.
#>

param(
    [Parameter(Position=0)] [ValidateSet('up','down','logs')] [string]$Action = 'up',
    [string]$Service = '',
    [switch]$Rebuild,
    [switch]$FollowLogs
)

Set-StrictMode -Version Latest

function Test-Docker {
    try {
        docker version --format '{{.Server.Version}}' > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Docker)) {
    Write-Error "Docker n'est pas trouvé. Installez Docker Desktop ou Docker Engine et réessayez."
    exit 1
}

switch ($Action) {
    'up' {
        $cmd = 'docker compose up -d'
        if ($Rebuild) { $cmd = 'docker compose up -d --build' }
        Write-Host "Exécution: $cmd"
        iex $cmd

        if ($FollowLogs) {
            if ([string]::IsNullOrEmpty($Service)) {
                Write-Host "Suivi des logs (Ctrl+C pour quitter)..."
                Invoke-Expression 'docker compose logs -f'
            } else {
                Write-Host "Suivi des logs pour le service: $Service"
                iex "docker compose logs -f $Service"
            }
        }
    }

    'down' {
        Write-Host 'Arrêt et suppression des conteneurs, réseaux et volumes nommés (images conservées)'
        Invoke-Expression 'docker compose down -v'
    }

    'logs' {
        if ([string]::IsNullOrEmpty($Service)) {
            Invoke-Expression 'docker compose logs --tail=200'
        } else {
            iex "docker compose logs --tail=200 $Service"
        }
    }
}

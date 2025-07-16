# Script: Discover-AzureResources.ps1

Write-Host "--- Iniciando descubrimiento de recursos en la Suscripción: $(Get-AzContext).Subscription.Name ---"
Write-Host "Esto puede tardar unos momentos si tienes muchos recursos..."

# --- 1. Listar TODOS los Grupos de Recursos ---
Write-Host "`n## 1. Listado de TODOS los Grupos de Recursos ##"
$resourceGroups = Get-AzResourceGroup | Select-Object ResourceGroupName, Location, ProvisioningState | Sort-Object ResourceGroupName
if ($resourceGroups) {
    $resourceGroups | Format-Table -AutoSize
} else {
    Write-Host "No se encontraron Grupos de Recursos en esta suscripción."
}

# --- 2. Listar TODOS los Recursos, agrupados por Grupo de Recursos ---
Write-Host "`n## 2. Listado Detallado de Recursos por Grupo de Recursos ##"
if ($resourceGroups) {
    foreach ($rg in $resourceGroups) {
        Write-Host "`n### Recursos en el Grupo de Recursos: $($rg.ResourceGroupName) (Ubicación: $($rg.Location)) ###"
        try {
            $resourcesInRG = Get-AzResource -ResourceGroupName $rg.ResourceGroupName |
                             Select-Object Name, ResourceType, Location, ProvisioningState |
                             Sort-Object ResourceType, Name

            if ($resourcesInRG) {
                $resourcesInRG | Format-Table -AutoSize
            } else {
                Write-Host "  No se encontraron recursos en este grupo de recursos."
            }
        }
        catch {
            Write-Warning "  Error al obtener recursos para el Grupo de Recursos '$($rg.ResourceGroupName)': $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "No hay Grupos de Recursos para listar recursos detallados."
}

# --- 3. Listar TODOS los Recursos de la Suscripción (Vista Plana) ---
Write-Host "`n## 3. Listado de TODOS los Recursos de la Suscripción (Vista Plana) ##"
Write-Host "Esto puede ser muy extenso si tienes muchos recursos."
try {
    $allResources = Get-AzResource | Select-Object Name, ResourceType, ResourceGroupName, Location, ProvisioningState | Sort-Object ResourceType, Name
    if ($allResources) {
        $allResources | Format-Table -AutoSize
    } else {
        Write-Host "No se encontraron recursos en la suscripción."
    }
}
catch {
    Write-Warning "Error al obtener todos los recursos de la suscripción: $($_.Exception.Message)"
}

Write-Host "`n--- Descubrimiento de Recursos Completado ---"
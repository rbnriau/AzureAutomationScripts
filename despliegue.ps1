# Deploy-BasicAzureInfra.ps1

# --- 1. Configuración de Variables ---
# Nombres y ubicaciones para tus recursos. ¡Puedes cambiarlos!
$ResourceGroupName = "MiGrupoRecursosPS"
$Location = "westeurope" # Puedes usar 'eastus', 'northeurope', etc.
$VNetName = "MiVNetPS"
$Subnet1Name = "SubredVM1"
$Subnet2Name = "SubredVM2"
$VM1Name = "VM1-Subred1"
$VM2Name = "VM2-Subred2"
$VMSize = "Standard_B1s" # Tamaño VM ligero y económico
$VMImage = "UbuntuLTS" # Ubuntu Server 18.04-LTS (ligero)
$Username = "azureuser" # Usuario administrador para las VMs
$Password = ConvertTo-SecureString "P@55w0rd123" -AsPlainText -Force # ¡CAMBIA ESTA CONTRASEÑA!

Write-Host "Iniciando despliegue de infraestructura en Azure..."
Write-Host "Grupo de Recursos: $ResourceGroupName en $Location"

# --- 2. Crear Grupo de Recursos ---
Write-Host "`nCreando Grupo de Recursos '$ResourceGroupName'..."
try {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop | Out-Null
    Write-Host "Grupo de Recursos creado."
}
catch {
    Write-Error "Error al crear el Grupo de Recursos: $($_.Exception.Message)"
    exit
}

# --- 3. Crear Red Virtual y Subredes ---
Write-Host "`nCreando Red Virtual '$VNetName' y Subredes..."
try {
    # Definir las subredes
    $Subnet1 = New-AzVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix "10.0.0.0/24"
    $Subnet2 = New-AzVirtualNetworkSubnetConfig -Name $Subnet2Name -AddressPrefix "10.0.1.0/24"

    # Crear la VNet con las subredes
    $VNet = New-AzVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $VNetName `
        -AddressPrefix "10.0.0.0/16" `
        -Subnet $Subnet1,$Subnet2 `
        -ErrorAction Stop

    Write-Host "Red Virtual y Subredes creadas."
}
catch {
    Write-Error "Error al crear la Red Virtual o Subredes: $($_.Exception.Message)"
    exit
}

# --- 4. Crear Máquina Virtual 1 en Subred 1 ---
Write-Host "`nCreando Máquina Virtual '$VM1Name' en '$Subnet1Name'..."
try {
    # Obtener la subred específica para la VM
    $Subnet1Obj = Get-AzVirtualNetworkSubnetConfig -Name $Subnet1Name -VirtualNetwork $VNet

    # Crear configuración de IP Pública (opcional, pero útil para SSH/RDP)
    $PublicIP1 = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name "$VM1Name-IP" -AllocationMethod Dynamic

    # Crear interfaz de red
    $Nic1 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $Location -Name "$VM1Name-Nic" -SubnetId $Subnet1Obj.Id -PublicIpAddressId $PublicIP1.Id

    # Configuración de la VM
    $VM1Config = New-AzVMConfig -VMName $VM1Name -VMSize $VMSize
    $VM1Config = Set-AzVMOperatingSystem -VM $VM1Config -Linux -ComputerName $VM1Name -Credential (Get-Credential -UserName $Username -Message "Credenciales para $VM1Name") -DisablePasswordAuthentication
    # OJO: La línea anterior usa Get-Credential, que es más seguro. Si prefieres la password plana como en la variable:
    # $VM1Config = Set-AzVMOperatingSystem -VM $VM1Config -Linux -ComputerName $VM1Name -Credential (New-Object System.Management.Automation.PSCredential($Username, $Password)) -DisablePasswordAuthentication
    $VM1Config = Set-AzVMSourceImage -VM $VM1Config -Publisher Canonical -Offer UbuntuServer -Skus 18.04-LTS -Version latest
    $VM1Config = Add-AzVMNetworkInterface -VM $VM1Config -Id $Nic1.Id

    # Crear la VM
    New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM1Config -ErrorAction Stop

    Write-Host "Máquina Virtual '$VM1Name' creada."
    Write-Host "IP Pública de '$VM1Name': $($PublicIP1.IpAddress)"
}
catch {
    Write-Error "Error al crear la Máquina Virtual '$VM1Name': $($_.Exception.Message)"
    # No salimos aquí para intentar crear la segunda VM
}

# --- 5. Crear Máquina Virtual 2 en Subred 2 ---
Write-Host "`nCreando Máquina Virtual '$VM2Name' en '$Subnet2Name'..."
try {
    # Obtener la subred específica para la VM
    $Subnet2Obj = Get-AzVirtualNetworkSubnetConfig -Name $Subnet2Name -VirtualNetwork $VNet

    # Crear configuración de IP Pública (opcional, pero útil para SSH/RDP)
    $PublicIP2 = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name "$VM2Name-IP" -AllocationMethod Dynamic

    # Crear interfaz de red
    $Nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $Location -Name "$VM2Name-Nic" -SubnetId $Subnet2Obj.Id -PublicIpAddressId $PublicIP2.Id

    # Configuración de la VM
    $VM2Config = New-AzVMConfig -VMName $VM2Name -VMSize $VMSize
    $VM2Config = Set-AzVMOperatingSystem -VM $VM2Config -Linux -ComputerName $VM2Name -Credential (Get-Credential -UserName $Username -Message "Credenciales para $VM2Name") -DisablePasswordAuthentication
    # OJO: La línea anterior usa Get-Credential, que es más seguro. Si prefieres la password plana como en la variable:
    # $VM2Config = Set-AzVMOperatingSystem -VM $VM2Config -Linux -ComputerName $VM2Name -Credential (New-Object System.Management.Automation.PSCredential($Username, $Password)) -DisablePasswordAuthentication
    $VM2Config = Set-AzVMSourceImage -VM $VM2Config -Publisher Canonical -Offer UbuntuServer -Skus 18.04-LTS -Version latest
    $VM2Config = Add-AzVMNetworkInterface -VM $VM2Config -Id $Nic2.Id

    # Crear la VM
    New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM2Config -ErrorAction Stop

    Write-Host "Máquina Virtual '$VM2Name' creada."
    Write-Host "IP Pública de '$VM2Name': $($PublicIP2.IpAddress)"
}
catch {
    Write-Error "Error al crear la Máquina Virtual '$VM2Name': $($_.Exception.Message)"
}

Write-Host "`nDespliegue de infraestructura finalizado."
Write-Host "¡No olvides eliminar el Grupo de Recursos '$ResourceGroupName' cuando hayas terminado para evitar costes!"
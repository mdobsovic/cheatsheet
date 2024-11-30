# Pripájanie VHDX súborov s kontrolou, či sú pripojené:
```pwsh
$images = @("C:\APP\Disk1.vhdx", "C:\APP\Disk2.vhdx", "C:\APP\Disk3.vhdx")
foreach ($image in $images) {
    if ((Get-DiskImage $image).Attached -ne $true) {
        Mount-DiskImage -ImagePath $image
    }
}
```
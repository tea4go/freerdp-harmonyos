# 创建临时签名配置
$keytoolPath = "C:\Program Files\Huawei\DevEco Studio\jbr\bin\keytool.exe"
$configDir = "$env:USERPROFILE\.ohos\config"
$projectName = "default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ="

New-Item -Path $configDir -ItemType Directory -Force | Out-Null

# 生成 p12 密钥库
& "$keytoolPath" -genkeypair -alias debugKey -keyalg EC -keysize 256 -validity 3650 `
  -keystore "$configDir\$projectName.p12" -storetype PKCS12 `
  -storepass "00000001" -keypass "00000001" `
  -dname "CN=Debug,OU=Dev,O=Test,L=City,ST=State,C=CN"

Write-Host "签名文件生成完成"

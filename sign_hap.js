/**
 * Sign HAP manually using DevEco Studio's signing infrastructure
 * Decrypts obfuscated passwords from build-profile.json5 and calls hap-sign-tool.jar
 */
'use strict';

const path = require('path');
const { execSync } = require('child_process');
const fs = require('fs');

// Load DecipherUtil from DevEco Studio
const devEcoBase = 'C:/Program Files/Huawei/DevEco Studio';
const pluginBase = path.join(devEcoBase, 'tools/hvigor/hvigor-ohos-plugin');
const DecipherUtil = require(path.join(pluginBase, 'src/utils/decipher-util.js')).DecipherUtil;

// materialDir is the parent of the .p12 file (getKeyStorePwd uses path.resolve(storeFile, '..'))
const materialDir = 'C:/Users/tony/.ohos/config';

// Encrypted passwords from build-profile.json5
const encryptedKeyPassword = '0000001ADF2D9256C7800699DD8B7F942C6F2D1EFDFF01BDAC0ECB84597E5078EF172D01E3CC2D5AC7C6';
const encryptedStorePassword = '0000001A3C0B334C841EE9F3F4AF1A21D863628E8380CFB80D0ECB935B28B90E0D8A25B1160B7CB86C4F';

let keyPassword, storePassword;
try {
  keyPassword = DecipherUtil.decryptPwd(materialDir, encryptedKeyPassword, 'keyPassword');
  console.log('keyPassword decrypted:', keyPassword);
} catch (e) {
  console.error('Failed to decrypt keyPassword:', e.message);
  process.exit(1);
}

try {
  storePassword = DecipherUtil.decryptPwd(materialDir, encryptedStorePassword, 'storePassword');
  console.log('storePassword decrypted:', storePassword);
} catch (e) {
  console.error('Failed to decrypt storePassword:', e.message);
  process.exit(1);
}

// Sign parameters
const signToolJar = path.join(devEcoBase, 'sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar');
const javaExe = path.join(devEcoBase, 'jbr/bin/java.exe');

const certPath = 'C:/Users/tony/.ohos/config/default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ=.cer';
const profilePath = 'C:/Users/tony/.ohos/config/default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ=.p7b';
const storeFile = 'C:/Users/tony/.ohos/config/default_freerdp-harmonyos_lEHWiL5R0PEmwzGQYsMdjAf0qDQI-qDO2EiktMNWoxQ=.p12';
const keyAlias = 'debugKey';
const signAlg = 'SHA256withECDSA';

const inputHap = 'entry/build/default/outputs/default/entry-default-unsigned-fixed.hap';
const outputHap = 'entry/build/default/outputs/default/entry-default-signed.hap';

// Build sign command (matches HapSignCommandBuilder.initCommandParams order + addCalledJarFile)
const signCmd = [
  `"${javaExe}"`,
  `-jar "${signToolJar}"`,
  'sign-app',
  `-mode localSign`,
  `-keystoreFile "${storeFile}"`,
  `-keystorePwd "${storePassword}"`,
  `-keyAlias ${keyAlias}`,
  `-keyPwd "${keyPassword}"`,
  `-signAlg ${signAlg}`,
  `-profileFile "${profilePath}"`,
  `-appCertFile "${certPath}"`,
  `-inFile "${inputHap}"`,
  `-outFile "${outputHap}"`
].join(' ');

console.log('\nRunning sign command...');
console.log('Input:', inputHap);
console.log('Output:', outputHap);

try {
  const result = execSync(signCmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  console.log('Sign output:', result);
  console.log('\nSigning SUCCESS!');

  // Verify output
  const stat = fs.statSync(outputHap);
  console.log(`Signed HAP size: ${stat.size} bytes`);
} catch (e) {
  console.error('Sign FAILED:', e.stderr || e.message);
  process.exit(1);
}

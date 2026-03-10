# Configuração Firebase (Push + Analytics)

O projeto já está preparado para Firebase. Falta apenas gerar os arquivos de configuração.

## Passos (execute no terminal)

### 1. Login no Firebase

```bash
firebase login
```

Isso abrirá o navegador para autenticar com sua conta Google.

### 2. Configurar Firebase

**Opção A – FlutterFire (recomendado)**

Quando o FlutterFire pedir o package name, digite: **`com.digo.smartagenda`** (não deixe em branco).

```bash
cd /Users/digo/Documents/projetos/smart_agenda
$HOME/.pub-cache/bin/flutterfire configure --project=smart-agenda-a550b -y
```

**Opção B – Configuração manual (se o FlutterFire falhar)**

1. Acesse [Firebase Console](https://console.firebase.google.com) → projeto **smart-agenda**
2. **Adicionar app** → Android → package name: `com.digo.smartagenda` → registrar
3. Baixe `google-services.json` e coloque em `android/app/`
4. **Adicionar app** → iOS → bundle ID: `com.digo.smartagenda` → registrar
5. Baixe `GoogleService-Info.plist` e coloque em `ios/Runner/`
6. Gere o `firebase_options.dart` com:

```bash
$HOME/.pub-cache/bin/flutterfire configure --project=smart-agenda-a550b --platforms=android,ios -a com.digo.smartagenda -i com.digo.smartagenda -y
```

(O FlutterFire pode exigir macos/web; se pedir, adicione `-m com.digo.smartagenda`)

O comando irá:
- Criar ou selecionar um projeto Firebase
- Adicionar apps Android (`com.digo.smartagenda`) e iOS (`com.digo.smartagenda`)
- Gerar `lib/firebase_options.dart`
- Baixar `android/app/google-services.json`
- Baixar `ios/Runner/GoogleService-Info.plist`

### 3. iOS: instalar pods

```bash
cd ios && pod install && cd ..
```

### 4. Android: configurar FCM (opcional)

Para push no Android, o `google-services.json` já contém a config. Se for enviar push via API, use o **Server Key** (ou credenciais OAuth 2.0) do projeto no Firebase Console → Project Settings → Cloud Messaging.

### 5. iOS: habilitar Push no Xcode

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione o target Runner → Signing & Capabilities
3. Adicione **Push Notifications**
4. Adicione **Background Modes** → Remote notifications (se não estiver)

## Uso no código

- **Analytics**: `FirebaseService.logEvent(name: 'evento', parameters: {'campo': 'valor'})`
- **User ID**: `FirebaseService.setUserId(userId)` (chamado no login)
- **Push**: handlers em `main.dart` (`_onPushMessage`, `_onPushMessageOpened`)

## Envio de push

- **Firebase Console** → Cloud Messaging → New campaign
- Ou via **REST API** com o Server Key do projeto

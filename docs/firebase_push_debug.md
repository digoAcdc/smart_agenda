# Debug: Push não aparece

## Possíveis causas

### 1. App em foreground (aberto na tela)
**Corrigido**: Agora exibimos notificação local quando o push chega com o app aberto.

### 2. Formato da mensagem no Firebase Console
Para aparecer em **background/fechado**, a mensagem precisa ter **Título** e **Corpo** na aba "Mensagem de notificação". Se enviar só "Dados personalizados" (data-only), o sistema não mostra automaticamente.

**Correto**: Campanha → Mensagem de notificação → preencher Título e Texto da notificação.

### 3. Permissão negada
O usuário precisa ter aceitado notificações. Verificar em Configurações do Android → Apps → Smart Agenda → Notificações.

### 4. App nunca aberto após instalar
O dispositivo só se registra no FCM após o app abrir e chamar `getToken()`. Quem instalou mas nunca abriu não recebe.

### 5. Dispositivos sem Google Play Services
Huawei (sem GMS), China, emuladores sem GMS: FCM não funciona.

### 6. Envio para "Todos"
No Firebase Console, "Enviar para todos" = todos os dispositivos **registrados** para o app. Só conta quem já abriu o app e obteve token.

## Como testar

1. **Foreground**: Abra o app, envie push → deve aparecer notificação.
2. **Background**: Minimize o app (não feche), envie push → deve aparecer na barra.
3. **Terminated**: Feche o app (remova dos recentes), envie push → deve aparecer; ao tocar, o app abre.

## Log para debug

Adicione temporariamente em `_onPushMessage`:
```dart
debugPrint('Push received: ${message.notification?.title} / ${message.notification?.body}');
```
E no handler de background em `firebase_service.dart`:
```dart
debugPrint('Background push: ${message.messageId}');
```

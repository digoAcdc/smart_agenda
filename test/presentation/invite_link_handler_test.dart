import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/presentation/services/invite_link_handler.dart';

void main() {
  test('le o codigo do link do site e do botao "Abrir no app"', () {
    expect(
      InviteLinkHandler.tokenFromUri(
        Uri.parse('https://rbarbosa.tech/convite/abcdefghjk23'),
      ),
      'abcdefghjk23',
    );
    expect(
      InviteLinkHandler.tokenFromUri(
        Uri.parse('smartagenda://convite/abcdefghjk23'),
      ),
      'abcdefghjk23',
    );
  });

  test('ignora links que nao sao convite ou codigo invalido', () {
    expect(
      InviteLinkHandler.tokenFromUri(
        Uri.parse('https://rbarbosa.tech/privacidade'),
      ),
      isNull,
    );
    expect(
      InviteLinkHandler.tokenFromUri(
        Uri.parse('https://outro.site/convite/abcdefghjk23'),
      ),
      isNull,
    );
    expect(
      InviteLinkHandler.tokenFromUri(
        Uri.parse('https://rbarbosa.tech/convite/../x'),
      ),
      isNull,
    );
  });

  test('le o codigo do install referrer do Google Play', () {
    expect(
      InviteLinkHandler.tokenFromReferrer('convite=abcdefghjk23'),
      'abcdefghjk23',
    );
    expect(
      InviteLinkHandler.tokenFromReferrer('convite%3Dabcdefghjk23'),
      'abcdefghjk23',
    );
    expect(
      InviteLinkHandler.tokenFromReferrer(
        'utm_source=google-play&utm_medium=organic',
      ),
      isNull,
    );
    expect(InviteLinkHandler.tokenFromReferrer(null), isNull);
  });
}

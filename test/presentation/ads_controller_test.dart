import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/domain/repositories/i_ads_service.dart';
import 'package:smart_agenda/domain/repositories/i_premium_service.dart';
import 'package:smart_agenda/presentation/controllers/ads_controller.dart';

class _FakeAds implements IAdsService {
  int initCalls = 0;
  bool consent = true;
  @override
  Future<bool> initialize() async {
    initCalls++;
    return consent;
  }

  @override
  Future<bool> privacyOptionsRequired() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePremium implements IPremiumService {
  bool premium = false;
  bool resolved = false;
  final _changes = StreamController<void>.broadcast();
  void resolve({required bool isPremium}) {
    premium = isPremium;
    resolved = true;
    _changes.add(null);
  }

  @override
  bool get isPremium => premium;
  @override
  bool get isResolved => resolved;
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<void> refresh() async {}
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('nao pede consentimento nem anuncio antes de saber o plano', () async {
    final ads = _FakeAds(), premium = _FakePremium();
    final c = AdsController(ads, premium)..onInit();
    await _settle();
    expect(ads.initCalls, 0);
    expect(c.showAds, isFalse);
  });

  test('Pro nunca inicializa anuncios', () async {
    final ads = _FakeAds(), premium = _FakePremium();
    final c = AdsController(ads, premium)..onInit();
    premium.resolve(isPremium: true);
    await _settle();
    expect(ads.initCalls, 0);
    expect(c.showAds, isFalse);
  });

  test('Free inicializa uma vez e mostra anuncios', () async {
    final ads = _FakeAds(), premium = _FakePremium();
    final c = AdsController(ads, premium)..onInit();
    premium.resolve(isPremium: false);
    premium.resolve(isPremium: false);
    await _settle();
    await _settle();
    expect(ads.initCalls, 1);
    expect(c.showAds, isTrue);
    expect(c.privacyOptionsRequired.value, isTrue);
  });

  test('sem consentimento nao mostra anuncios', () async {
    final ads = _FakeAds()..consent = false, premium = _FakePremium();
    final c = AdsController(ads, premium)..onInit();
    premium.resolve(isPremium: false);
    await _settle();
    expect(c.showAds, isFalse);
  });

  test('virou Pro: anuncios somem na hora', () async {
    final ads = _FakeAds(), premium = _FakePremium();
    final c = AdsController(ads, premium)..onInit();
    premium.resolve(isPremium: false);
    await _settle();
    expect(c.showAds, isTrue);
    premium.resolve(isPremium: true);
    expect(c.showAds, isFalse);
  });
}

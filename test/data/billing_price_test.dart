import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:smart_agenda/data/services/billing_service_impl.dart';

PricingPhaseWrapper _phase(String price, int micros, String period, RecurrenceMode mode) =>
    PricingPhaseWrapper(
      billingCycleCount: mode == RecurrenceMode.infiniteRecurring ? 0 : 1,
      billingPeriod: period,
      formattedPrice: price,
      priceAmountMicros: micros,
      priceCurrencyCode: 'BRL',
      recurrenceMode: mode,
    );

void main() {
  // Promocao (R$ 4,99 no 1o mes e depois R$ 9,90) vem antes do plano base.
  final offers = GooglePlayProductDetails.fromProductDetails(
    ProductDetailsWrapper(
      description: 'Pro',
      name: 'Smart Agenda Pro',
      productId: 'smart_agenda_premium',
      productType: ProductType.subs,
      title: 'Smart Agenda Pro',
      subscriptionOfferDetails: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'mensal',
          offerId: 'primeiro-mes',
          offerTags: const [],
          offerIdToken: 'promo',
          pricingPhases: [
            _phase('R\$ 4,99', 4990000, 'P1M', RecurrenceMode.finiteRecurring),
            _phase('R\$ 9,90', 9900000, 'P1M', RecurrenceMode.infiniteRecurring),
          ],
        ),
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'mensal',
          offerTags: const [],
          offerIdToken: 'base',
          pricingPhases: [
            _phase('R\$ 9,90', 9900000, 'P1M', RecurrenceMode.infiniteRecurring),
          ],
        ),
      ],
    ),
  );

  test('escolhe o plano base, nao a promocao', () {
    expect(offers.first.price, 'R\$ 4,99'); // o que o app mostrava antes
    final base = selectBasePlan(offers)! as GooglePlayProductDetails;
    expect(base.subscriptionIndex, 1);
  });

  test('preco mostrado e o recorrente com periodo', () {
    expect(recurringPriceLabel(selectBasePlan(offers)!), 'R\$ 9,90 por mês');
  });

  test('sem ofertas nao quebra', () {
    expect(selectBasePlan(const []), isNull);
  });
}

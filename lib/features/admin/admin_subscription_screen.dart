import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AdminSubscriptionScreen extends StatefulWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  State<AdminSubscriptionScreen> createState() =>
      _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState
    extends State<AdminSubscriptionScreen> {
  int _selectedPlan = 1;
  int _selectedPayment = 0;

  final plans = [
    {
      'name': 'BULANAN',
      'price': 49000,
      'duration': '30 Hari',
    },
    {
      'name': '3 BULAN',
      'price': 129000,
      'duration': '90 Hari',
    },
    {
      'name': 'TAHUNAN',
      'price': 399000,
      'duration': '365 Hari',
    },
  ];

  final payments = [
    'QRIS',
    'DANA',
    'GoPay',
    'Transfer Bank',
  ];

  String rupiah(int amount) {
    final formatter = amount.toString().split('').reversed.toList();
    String result = '';

    for (int i = 0; i < formatter.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result += '.';
      }
      result += formatter[i];
    }

    return 'Rp${result.split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = plans[_selectedPlan];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN SUBSCRIPTION'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //----------------------------------
            // STATUS PREMIUM
            //----------------------------------

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5C0000),
                    Color(0xFF1A0000),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BooyahTheme.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: BooyahTheme.gold,
                    size: 40,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PREMIUM AKTIF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '28 Hari Tersisa',
                          style: TextStyle(
                            color: BooyahTheme.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //----------------------------------
            // PAKET
            //----------------------------------

            const Text(
              'PILIH PAKET',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            ...plans.asMap().entries.map(
              (e) {
                final selectedCard =
                    _selectedPlan == e.key;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = e.key;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selectedCard
                          ? BooyahTheme.gold.withValues(
                              alpha: 0.08,
                            )
                          : BooyahTheme.card,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedCard
                            ? BooyahTheme.gold
                            : BooyahTheme.maroon
                                .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedCard
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: selectedCard
                              ? BooyahTheme.gold
                              : BooyahTheme.textMuted,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.value['name']
                                    .toString(),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),

                              Text(
                                e.value['duration']
                                    .toString(),
                                style: const TextStyle(
                                  color:
                                      BooyahTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          rupiah(
                            e.value['price'] as int,
                          ),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w800,
                            color: BooyahTheme.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            //----------------------------------
            // PAYMENT
            //----------------------------------

            const Text(
              'METODE PEMBAYARAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: payments.asMap().entries.map(
                (e) {
                  final selectedMethod =
                      _selectedPayment == e.key;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPayment = e.key;
                      });
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selectedMethod
                            ? BooyahTheme.gold
                                .withValues(alpha: 0.1)
                            : BooyahTheme.card,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedMethod
                              ? BooyahTheme.gold
                              : BooyahTheme.maroon
                                  .withValues(
                                    alpha: 0.2,
                                  ),
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color: selectedMethod
                              ? BooyahTheme.gold
                              : BooyahTheme.textPri,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(height: 20),

            //----------------------------------
            // SUMMARY
            //----------------------------------

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BooyahTheme.card,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: BooyahTheme.maroon
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _row(
                    'Paket',
                    selected['name'].toString(),
                  ),
                  const SizedBox(height: 10),
                  _row(
                    'Durasi',
                    selected['duration']
                        .toString(),
                  ),
                  const Divider(),
                  _row(
                    'Total',
                    rupiah(
                      selected['price'] as int,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            //----------------------------------
            // BUTTON
            //----------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur pembayaran akan dihubungkan ke backend.',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.payment,
                ),
                label: const Text(
                  'PERPANJANG SUBSCRIPTION',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      BooyahTheme.gold,
                  foregroundColor:
                      Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: BooyahTheme.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
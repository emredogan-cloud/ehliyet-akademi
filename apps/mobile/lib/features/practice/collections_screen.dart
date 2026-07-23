import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../domain/practice/collections.dart';
import '../../domain/practice/exam.dart';
import 'widgets/bank_scope.dart';

/// Sınav koleksiyonları — her gün yenilenen, temalı otomatik setler.
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koleksiyonlar')),
      body: SafeArea(
        top: false,
        child: PracticeContentBuilder(
          builder: (context, bank) {
            final now = DateTime.now();
            String p2(int n) => n.toString().padLeft(2, '0');
            final daySeed = seedFromDate('${now.year}-${p2(now.month)}-${p2(now.day)}');
            final weekSeed = seedFromDate('week:${now.year}-${p2(now.month)}');
            final collections = examCollections(
              bank.questions,
              daySeed: daySeed,
              weekSeed: weekSeed,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                for (final c in collections) ...[
                  _CollectionCard(collection: c),
                  const SizedBox(height: AppSpacing.s3),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});
  final CollectionSpec collection;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: () => context.push('/practice/collection/${collection.id}'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.surface3,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(collection.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection.label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(collection.description,
                    style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Column(
            children: [
              Text('${collection.count}',
                  style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('soru', style: TextStyle(color: p.text3, fontSize: 11)),
            ],
          ),
          Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}

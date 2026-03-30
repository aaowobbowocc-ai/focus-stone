import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

class ChangelogPage {
  static Future<List<Map<String, dynamic>>> _fetch() async {
    try {
      final res = await html.HttpRequest.getString(
          'changelog.json?_=${DateTime.now().millisecondsSinceEpoch}');
      final list = jsonDecode(res) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> show(BuildContext context) async {
    final entries = await _fetch();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5E6C8),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ChangelogSheet(entries: entries),
    );
  }
}

class _ChangelogSheet extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _ChangelogSheet({required this.entries});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Text('更新日誌',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C0A))),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Expanded(
              child: Center(
                child: Text('暫無資料', style: TextStyle(color: Color(0xFF8B5E3C))),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final items = (e['items'] as List).cast<String>();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDD9A3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF7B4F2E),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          child: Row(
                            children: [
                              Text(e['title'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const Spacer(),
                              Text(e['date'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('・', style: TextStyle(
                                      color: Color(0xFF7B4F2E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(item,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF4A2C0A),
                                            height: 1.5)),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

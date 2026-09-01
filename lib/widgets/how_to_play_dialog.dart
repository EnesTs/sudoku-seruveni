import 'package:flutter/material.dart';

class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HowToPlayDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.amber, size: 28),
          SizedBox(width: 8),
          Text('Nasıl Oynanır?', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRuleItem('1️⃣ Satır & Sütun Kuralı', 'Her satırda ve her sütunda yalnızca 1 hayvan bulunabilir.'),
            _buildRuleItem('2️⃣ Renk Bölgesi Kuralı', 'Her renkli bölgenin içinde tam olarak 1 hayvan olmalıdır.'),
            _buildRuleItem('3️⃣ Temas Yasağı', 'Hayvanlar birbirine çaprazlar dahil komşu olamaz (3x3 etki alanı).'),
            _buildRuleItem('❌ Çarpı İşareti', 'Emin olduğun boş karelere tek tıkla ❌ koyarak olasılıkları ele.'),
            _buildRuleItem('💡 İleri Düzey Taktik', 'Bir bölgenin boş kareleri tek bir sütundaysa, o sütundaki diğer tüm kareleri eleyebilirsin!'),
          ],
        ),
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
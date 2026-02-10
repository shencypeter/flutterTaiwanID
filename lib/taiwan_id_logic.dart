// ============================================================
// Business Logic (ported from Kotlin)
// ============================================================

const Map<String, int> LETTER_MAP = {
  'A': 10, 'B': 11, 'C': 12, 'D': 13, 'E': 14,
  'F': 15, 'G': 16, 'H': 17, 'I': 34, 'J': 18,
  'K': 19, 'L': 20, 'M': 21, 'N': 22, 'O': 35,
  'P': 23, 'Q': 24, 'R': 25, 'S': 26, 'T': 27,
  'U': 28, 'V': 29, 'W': 32, 'X': 30, 'Y': 31,
  'Z': 33,
};

const Map<String, String> CITY_MAP = {
  'A': '臺北市', 'B': '臺中市', 'C': '基隆市',
  'D': '臺南市', 'E': '高雄市', 'F': '新北市',
  'G': '宜蘭縣', 'H': '桃園市', 'I': '嘉義市',
  'J': '新竹縣', 'K': '苗栗縣', 'L': '臺中縣',
  'M': '南投縣', 'N': '彰化縣', 'O': '新竹市',
  'P': '雲林縣', 'Q': '嘉義縣', 'R': '臺南縣',
  'S': '高雄縣', 'T': '屏東縣', 'U': '花蓮縣',
  'V': '臺東縣', 'W': '金門縣', 'X': '澎湖縣',
  'Y': '陽明山管理局', 'Z': '連江縣',
};

// ------------------------------------------------------------
// Input Router
// ------------------------------------------------------------

String analyzeInput(String raw) {
  if (raw.trim().isEmpty) return '未輸入任何資料。';

  final input = raw.toUpperCase();

  if (RegExp(r'^[A-Z][0-9]{9}$').hasMatch(input)) {
    return analyzeFullId(input);
  }
  if (RegExp(r'^[0-9]{9}$').hasMatch(input)) {
    return inferLeadingLetterByObservedChecksum(input);
  }
  if (RegExp(r'^[A-Z][0-9]{8}$').hasMatch(input)) {
    return inferChecksum(input);
  }

  return '輸入格式無法識別。';
}

// ------------------------------------------------------------
// Full ID
// ------------------------------------------------------------

String analyzeFullId(String id) {
  final letter = id[0];
  final digits = id.substring(1);
  final valid = calculateChecksum(letter, digits) == 0;

  return '''
偵測到${valid ? "有效的" : "無效的"}完整身分證號
身分證號：$id

（出生／報戶口戶籍地）：${CITY_MAP[letter] ?? "未知"}
性別：${inferSex(digits)}
身分類型：${inferCitizenType(digits)}
'''.trim();
}

// ------------------------------------------------------------
// Inference helpers
// ------------------------------------------------------------

String inferSex(String digits) {
  switch (digits[0]) {
    case '1':
      return '男性';
    case '2':
      return '女性';
    default:
      return '其他';
  }
}

String inferCitizenType(String digits) {
  switch (digits[1]) {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
      return '在臺灣出生之本國國民';
    case '6':
      return '入籍國民（原為外國人）';
    case '7':
      return '入籍國民（原為無戶籍國民）';
    case '8':
      return '入籍國民（原為香港或澳門居民）';
    case '9':
      return '入籍國民（原為大陸地區居民）';
    default:
      return '未知';
  }
}

// ------------------------------------------------------------
// 9 digits without letter
// ------------------------------------------------------------

String inferLeadingLetterByObservedChecksum(String nineDigits) {
  final baseDigits = nineDigits.substring(0, 8);
  final observedChecksum = int.parse(nineDigits[8]);
  final results = <String>[];

  for (final letter in LETTER_MAP.keys) {
    final computed =
        (10 - calculateChecksum(letter, baseDigits)) % 10;
    if (computed == observedChecksum) {
      results.add(letter);
    }
  }

  if (results.isEmpty) {
    return '找不到符合條件的身分證字母。';
  }

  final buffer = StringBuffer()
    ..writeln('偵測到 9 碼數字（電話語音輸入模式）\n')
    ..writeln('可確定資訊：')
    ..writeln('性別：${inferSex(nineDigits)}')
    ..writeln('身分類型：${inferCitizenType(nineDigits)}\n')
    ..writeln('可能的戶籍地／完整身分證號：');

  for (final letter in results) {
    buffer.writeln(
      '- $letter$baseDigits$observedChecksum（${CITY_MAP[letter]}）',
    );
  }

  return buffer.toString();
}

// ------------------------------------------------------------
// Letter + first 8 digits
// ------------------------------------------------------------

String inferChecksum(String partialId) {
  final letter = partialId[0];
  final baseDigits = partialId.substring(1);

  final validLastDigits = List.generate(10, (i) => i)
      .where((d) =>
          calculateChecksum(letter, '$baseDigits$d') == 0)
      .toList();

  if (validLastDigits.isEmpty) {
    return '無法計算出合法的檢查碼。';
  }

  final buffer = StringBuffer()
    ..writeln('偵測到缺少最後一碼的身分證號\n');

  for (final d in validLastDigits) {
    buffer
      ..writeln('補齊後的完整身分證號：$letter$baseDigits$d')
      ..writeln('是否有效：是')
      ..writeln('（出生／報戶口戶籍地）：${CITY_MAP[letter]}')
      ..writeln('性別：${inferSex(baseDigits)}')
      ..writeln('身分類型：${inferCitizenType(baseDigits)}\n');
  }

  return buffer.toString();
}

// ------------------------------------------------------------
// Checksum core
// ------------------------------------------------------------

int calculateChecksum(String letter, String digits) {
  final value = LETTER_MAP[letter];
  if (value == null) return -1;

  final tens = value ~/ 10;
  final ones = value % 10;

  final weights = [1, 9, 8, 7, 6, 5, 4, 3, 2, 1, 1];
  final numbers = <int>[tens, ones];

  for (final ch in digits.split('')) {
    numbers.add(int.parse(ch));
  }

  final sum = List.generate(
    numbers.length,
    (i) => numbers[i] * weights[i],
  ).reduce((a, b) => a + b);

  return sum % 10;
}

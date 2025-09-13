import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';


class PasswordGenerator {
  final bool useUpper;
  final bool useDigits;
  final bool useSymbols;
  final int length;
  final String algorithm;
  final String seed;

  PasswordGenerator({
    required this.useUpper,
    required this.useDigits,
    required this.useSymbols,
    required this.length,
    required this.algorithm,
    required this.seed,
  });

  String generate() {
    final n = length;

    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const symbols = '@#\$%&*+-_=?!';

    var alphabet = lower;
    if (useUpper) alphabet += upper;
    if (useDigits) alphabet += digits;
    if (useSymbols) alphabet += symbols;

    if (alphabet.isEmpty) alphabet = lower;

    final bytes = _expandBytes('$algorithm|$seed', n * 2);

    final chars = List.generate(n, (i) {
      final idx = bytes[i] % alphabet.length;
      return alphabet[idx];
    });

    // garante pelo menos uma de cada classe selecionada
    final rnd = _expandBytes('classes|$seed', 64);
    int rPtr = 0;

    void ensureOne(String set, bool enabled, RegExp tester) {
      if (!enabled) return;
      if (!tester.hasMatch(chars.join())) {
        final pos = rnd[rPtr++ % rnd.length] % n;
        final pick = set[rnd[rPtr++ % rnd.length] % set.length];
        chars[pos] = pick;
      }
    }

    ensureOne(upper, useUpper, RegExp(r'[A-Z]'));
    ensureOne(digits, useDigits, RegExp(r'\d'));
    ensureOne(symbols, useSymbols, RegExp(r'[@#\$%&*\+\-_=!\?]'));

    return chars.join();
  }

  List<int> _expandBytes(String seed, int count) {
    final out = <int>[];
    var i = 0;
    while (out.length < count) {
      final data = utf8.encode('$seed|$i');
      final h = sha256.convert(data).bytes;
      out.addAll(h);
      i++;
    }
    return out.sublist(0, count);
  }

  double strength(String password) {
    final n = password.length;
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp(r'[^\w]').hasMatch(password);

    final classes = [hasLower, hasUpper, hasDigit, hasSymbol].where((e) => e).length;
    final scoreLen = (n.clamp(8, 32) - 8) / (32 - 8);
    final scoreClass = (classes - 1) / 3;
    return (0.6 * scoreLen + 0.4 * scoreClass).clamp(0.0, 1.0);
  }

  static String labelForStrength(double s) {
    if (s < 0.33) return 'Fraca';
    if (s < 0.66) return 'Média';
    return 'Forte';
  }

  static Color colorForStrength(double s) {
    if (s < 0.33) return const Color(0xFFE53935); // vermelho
    if (s < 0.66) return const Color(0xFFFFA726); // laranja
    return const Color(0xFF43A047); // verde
  }
}

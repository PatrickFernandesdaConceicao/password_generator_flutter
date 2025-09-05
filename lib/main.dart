import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const PasswordApp());

class PasswordApp extends StatelessWidget {
  const PasswordApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de Senhas (Didático)',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const PasswordGeneratorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});
  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  final formKey = GlobalKey<FormState>();

  final servicoCtrl = TextEditingController();
  final usuarioCtrl = TextEditingController();
  final fraseCtrl = TextEditingController();

  String algoritmo = 'SHA-256';
  double comprimento = 16;
  bool useUpper = true;
  bool useDigits = true;
  bool useSymbols = false;

  String senhaGerada = '';
  double forca = 0.0; // 0..1

  @override
  void dispose() {
    servicoCtrl.dispose();
    usuarioCtrl.dispose();
    fraseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = comprimento.round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de Senhas (Didático)'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '⚠️ Atividade didática: não use em contas reais. '
                'Para produção, estude PBKDF2/scrypt/Argon2.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: servicoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Serviço/Site *',
                  hintText: 'ex.: email, banco, github',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o serviço' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usuarioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Usuário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fraseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Frase-base (segredo) *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a frase-base' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: algoritmo,
                decoration: const InputDecoration(
                  labelText: 'Método (hash) *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'MD5', child: Text('MD5')),
                  DropdownMenuItem(value: 'SHA-1', child: Text('SHA-1')),
                  DropdownMenuItem(value: 'SHA-256', child: Text('SHA-256')),
                ],
                onChanged: (v) => setState(() => algoritmo = v ?? 'SHA-256'),
              ),
              const SizedBox(height: 16),
              Text('Comprimento: $len'),
              Slider(
                value: comprimento,
                min: 8,
                max: 32,
                divisions: 24,
                label: '$len',
                onChanged: (v) => setState(() => comprimento = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: useUpper,
                onChanged: (v) => setState(() => useUpper = v),
                title: const Text('Permitir maiúsculas (A–Z)'),
                dense: true,
              ),
              SwitchListTile(
                value: useDigits,
                onChanged: (v) => setState(() => useDigits = v),
                title: const Text('Permitir números (0–9)'),
                dense: true,
              ),
              SwitchListTile(
                value: useSymbols,
                onChanged: (v) => setState(() => useSymbols = v),
                title: const Text('Permitir símbolos (@#\$%&*+-_=?!)'),
                dense: true,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.vpn_key),
                label: const Text('Gerar senha'),
                onPressed: _onGerar,
              ),
              const SizedBox(height: 12),
              if (senhaGerada.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        senhaGerada,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: senhaGerada));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Senha copiada!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StrengthBar(score: forca),
                const SizedBox(height: 4),
                Text(
                  _labelForStrength(forca),
                  style: TextStyle(
                    color: _colorForStrength(forca),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onGerar() {
    if (!formKey.currentState!.validate()) return;

    final seed = [
      servicoCtrl.text.trim(),
      usuarioCtrl.text.trim(),
      fraseCtrl.text, // ordem simples + pipe para separação
    ].join('|');

    final n = comprimento.round();

    // Deriva bytes de forma determinística a partir da semente + algoritmo.
    final bytes = _expandBytes('$algoritmo|$seed', n * 2);

    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const symbols = '@#\$%&*+-_=?!';

    var alphabet = lower;
    if (useUpper) alphabet += upper;
    if (useDigits) alphabet += digits;
    if (useSymbols) alphabet += symbols;

    // Garante que sempre exista um alfabeto mínimo.
    if (alphabet.isEmpty) {
      alphabet = lower;
    }

    // Mapeia bytes para chars permitidos.
    final chars = List.generate(n, (i) {
      final idx = bytes[i] % alphabet.length;
      return alphabet[idx];
    });

    // Se opções ativas, força presença de classes escolhidas.
    final rnd = _expandBytes('classes|$seed', 64); // bytes extras p/ índices
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

    final senha = chars.join();

    // Calcula força simples: comprimento + diversidade.
    final hasLower = RegExp(r'[a-z]').hasMatch(senha);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(senha);
    final hasDigit = RegExp(r'\d').hasMatch(senha);
    final hasSymbol = RegExp(r'[^\w]').hasMatch(senha);

    final classes = [hasLower, hasUpper, hasDigit, hasSymbol].where((e) => e).length;
    final scoreLen = (n.clamp(8, 32) - 8) / (32 - 8); // 0..1
    final scoreClass = (classes - 1) / 3; // 0..1 (1..4 classes)
    final score = (0.6 * scoreLen + 0.4 * scoreClass).clamp(0.0, 1.0);

    setState(() {
      senhaGerada = senha;
      forca = score.toDouble();
    });
  }

  // Expansão determinística: concatena SHA-256(seed + i) até obter "count" bytes.
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

  static String _labelForStrength(double s) {
    if (s < 0.33) return 'Fraca';
    if (s < 0.66) return 'Média';
    return 'Forte';
  }

  static Color _colorForStrength(double s) {
    if (s < 0.33) return Colors.red;
    if (s < 0.66) return Colors.orange;
    return Colors.green;
  }
}

class _StrengthBar extends StatelessWidget {
  final double score;
  const _StrengthBar({required this.score});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: score.clamp(0, 1),
        minHeight: 10,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_generator.dart';
import '../widgets/strength_bar.dart';

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
  double forca = 0.0;

  @override
  void dispose() {
    servicoCtrl.dispose();
    usuarioCtrl.dispose();
    fraseCtrl.dispose();
    super.dispose();
  }

  void _onGerar() {
    if (!formKey.currentState!.validate()) return;

    final seed = [
      servicoCtrl.text.trim(),
      usuarioCtrl.text.trim(),
      fraseCtrl.text,
    ].join('|');

    final generator = PasswordGenerator(
      useUpper: useUpper,
      useDigits: useDigits,
      useSymbols: useSymbols,
      length: comprimento.round(),
      algorithm: algoritmo,
      seed: seed,
    );

    final senha = generator.generate();
    final score = generator.strength(senha);

    setState(() {
      senhaGerada = senha;
      forca = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final len = comprimento.round();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerador de Senhas')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
              SwitchListTile(
                value: useUpper,
                onChanged: (v) => setState(() => useUpper = v),
                title: const Text('Permitir maiúsculas (A–Z)'),
              ),
              SwitchListTile(
                value: useDigits,
                onChanged: (v) => setState(() => useDigits = v),
                title: const Text('Permitir números (0–9)'),
              ),
              SwitchListTile(
                value: useSymbols,
                onChanged: (v) => setState(() => useSymbols = v),
                title: const Text('Permitir símbolos (@#\$%&*+-_=?!)'),
              ),
              const SizedBox(height: 16),
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
                StrengthBar(score: forca),
                const SizedBox(height: 4),
                Text(
                  PasswordGenerator.labelForStrength(forca),
                  style: TextStyle(
                    color: PasswordGenerator.colorForStrength(forca),
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
}

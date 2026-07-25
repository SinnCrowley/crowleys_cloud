import 'package:crowleys_cloud/app_constants.dart';
import 'package:flutter/material.dart';

String colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

Color? parseHexColor(String hex) {
  var clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) {
    clean = 'FF$clean';
  }
  if (clean.length == 8) {
    final val = int.tryParse(clean, radix: 16);
    if (val != null) return Color(val);
  }
  return null;
}

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.title,
  });

  final Color initialColor;
  final String title;

  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    required String title,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (_) =>
          ColorPickerDialog(initialColor: initialColor, title: title),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;
  bool _updatingFromText = false;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      text: colorToHex(widget.initialColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _onColorChanged(HSVColor newHsv) {
    setState(() {
      _hsvColor = newHsv;
      if (!_updatingFromText) {
        _hexController.text = colorToHex(newHsv.toColor());
      }
    });
  }

  void _onHexSubmitted(String text) {
    final parsed = parseHexColor(text);
    if (parsed != null) {
      _updatingFromText = true;
      setState(() {
        _hsvColor = HSVColor.fromColor(parsed);
      });
      _updatingFromText = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();

    return AlertDialog(
      backgroundColor: appSurface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.title,
        style: TextStyle(color: appText, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Presets Header
              Text(
                'Presets',
                style: TextStyle(
                  color: appSubtext,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: presetThemeColors.map((color) {
                  final isSelected =
                      currentColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      _onColorChanged(HSVColor.fromColor(color));
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.black26,
                          width: isSelected ? 3.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Saturation / Value Box
              Text(
                'Custom Palette',
                style: TextStyle(
                  color: appSubtext,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _SatValPicker(
                    hsvColor: _hsvColor,
                    onChanged: _onColorChanged,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Hue Slider Bar
              SizedBox(
                height: 32,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _HuePicker(
                    hsvColor: _hsvColor,
                    onChanged: _onColorChanged,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Color Preview & Hex Input Field
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: appBorder),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      style: TextStyle(
                        color: appText,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'HEX RGB Code',
                        labelStyle: TextStyle(color: appSubtext),
                        hintText: '#FA5252',
                        hintStyle: TextStyle(color: appSubtext),
                        filled: true,
                        fillColor: appBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appAccent),
                        ),
                      ),
                      onChanged: _onHexSubmitted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: appSubtext)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, currentColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: appAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _SatValPicker extends StatelessWidget {
  const _SatValPicker({required this.hsvColor, required this.onChanged});

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  void _handleGesture(Offset localPosition, RenderBox renderBox) {
    final size = renderBox.size;
    if (size.width <= 0 || size.height <= 0) return;
    final sat = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final val = 1.0 - (localPosition.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsvColor.withSaturation(sat).withValue(val));
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onPanDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              _handleGesture(details.localPosition, box);
            }
          },
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              _handleGesture(details.localPosition, box);
            }
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: _SatValPainter(hsvColor: hsvColor),
          ),
        );
      },
    );
  }
}

class _SatValPainter extends CustomPainter {
  _SatValPainter({required this.hsvColor});

  final HSVColor hsvColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor();

    // Saturation gradient (horizontal white to hue color)
    final satGradient = LinearGradient(colors: [Colors.white, hueColor]);
    final satPaint = Paint()..shader = satGradient.createShader(rect);
    canvas.drawRect(rect, satPaint);

    // Value gradient (vertical transparent to black)
    const valGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    final valPaint = Paint()..shader = valGradient.createShader(rect);
    canvas.drawRect(rect, valPaint);

    // Selection Indicator Handle
    final dx = hsvColor.saturation * size.width;
    final dy = (1.0 - hsvColor.value) * size.height;

    canvas.drawCircle(
      Offset(dx, dy),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(dx, dy),
      8,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SatValPainter oldDelegate) {
    return oldDelegate.hsvColor != hsvColor;
  }
}

class _HuePicker extends StatelessWidget {
  const _HuePicker({required this.hsvColor, required this.onChanged});

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  void _handleGesture(Offset localPosition, RenderBox renderBox) {
    final size = renderBox.size;
    if (size.width <= 0 || size.height <= 0) return;
    final hue = (localPosition.dx / size.width).clamp(0.0, 1.0) * 360.0;
    onChanged(hsvColor.withHue(hue));
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onPanDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              _handleGesture(details.localPosition, box);
            }
          },
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              _handleGesture(details.localPosition, box);
            }
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: _HuePainter(hue: hsvColor.hue),
          ),
        );
      },
    );
  }
}

class _HuePainter extends CustomPainter {
  _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = <Color>[
      const Color(0xFFFF0000),
      const Color(0xFFFF8000),
      const Color(0xFFFFFF00),
      const Color(0xFF00FF00),
      const Color(0xFF00FFFF),
      const Color(0xFF0000FF),
      const Color(0xFFFF00FF),
      const Color(0xFFFF0000),
    ];

    final gradient = LinearGradient(colors: colors);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Indicator handle
    final dx = (hue / 360.0) * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(dx, size.height / 2),
          width: 8,
          height: size.height + 4,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(dx, size.height / 2),
          width: 6,
          height: size.height + 2,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

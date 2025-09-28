import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

enum CommandType { oneBit, oneByte }

String? validateGroupAddress(String v) {
  final parts = v.split('/');
  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
  if (parts.length != 3 ||
      a == null || a < 0 || a > 31 ||
      b == null || b < 0 || b > 7 ||
      c == null || c < 0 || c > 255 ||
      (a == 0 && b == 0 && c == 0)) {
    return 'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
  }
  return null;
}

class TimeCommand {
  CommandType type;
  // Bitmask for weekdays: 0 = Monday ... 6 = Sunday
  // bit set => day active
  int weekdaysMask;
  // Stored as HH:mm 24h
  String time;
  // For 1-bit: 0 or 1; For 1-byte: 0..255
  int value;
  // KNX three-level group address for this command
  String groupAddress;
  TimeCommand({
    this.type = CommandType.oneBit,
    this.weekdaysMask = 0,
    this.time = '08:00',
    this.value = 1,
    this.groupAddress = '',
  });
}

class TimeProgram {
  String guid;
  late final ValueNotifier<String> nameNotifier;
  List<TimeCommand> commands;

  TimeProgram({
    String? guid,
    String name = '',
    List<TimeCommand>? commands,
  })  : guid = guid ?? const Uuid().v4(),
        commands = commands ?? [] {
    nameNotifier = ValueNotifier<String>(name);
  }

  String get name => nameNotifier.value;
  set name(String value) => nameNotifier.value = value;
}

class TimeProgramWidget extends StatefulWidget {
  final TimeProgram program;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const TimeProgramWidget({
    super.key,
    required this.program,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<TimeProgramWidget> createState() => _TimeProgramWidgetState();
}

class _TimeProgramWidgetState extends State<TimeProgramWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: widget.program.guid,
            decoration: const InputDecoration(labelText: 'GUID'),
            enabled: false,
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: widget.program.nameNotifier,
            builder: (context, name, _) {
              return TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) {
                  widget.program.name = v;
                  widget.onChanged();
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Befehle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Befehl hinzufügen',
                onPressed: () {
                  setState(() {
                    final defaultGa = widget.program.commands.isNotEmpty
                        ? widget.program.commands.last.groupAddress
                        : '';
                    widget.program.commands
                        .add(TimeCommand(groupAddress: defaultGa));
                  });
                  widget.onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.program.commands.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('Noch keine Befehle. Mit + hinzufügen.'),
            ),
          for (int i = 0; i < widget.program.commands.length; i++)
            _CommandCard(
              key: ObjectKey(widget.program.commands[i]),
              command: widget.program.commands[i],
              onChanged: widget.onChanged,
              onRemove: () {
                setState(() => widget.program.commands.removeAt(i));
                widget.onChanged();
              },
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Programm löschen', style: TextStyle(color: Colors.red)),
            ),
          )
        ],
      ),
    );
  }
}

class _CommandCard extends StatefulWidget {
  final TimeCommand command;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _CommandCard({
    super.key,
    required this.command,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_CommandCard> createState() => _CommandCardState();
}

class _CommandCardState extends State<_CommandCard> {
  static const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  late final TextEditingController _byteController;
  String? _byteError;
  String? _gaError;
  late final TextEditingController _gaController;

  @override
  void initState() {
    super.initState();
    _byteController = TextEditingController(text: widget.command.value.toString());
    _byteError = null;
    _gaError = widget.command.groupAddress.isEmpty ? null : validateGroupAddress(widget.command.groupAddress);
    _gaController = TextEditingController(text: widget.command.groupAddress);
  }

  @override
  void dispose() {
    _byteController.dispose();
    _gaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.command;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _gaController,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse',
                helperText: 'Format: Haupt/Mittel/Unter (z. B. 1/2/3)',
                errorText: _gaError,
              ),
              onChanged: (v) {
                setState(() {
                  widget.command.groupAddress = v;
                  _gaError = validateGroupAddress(v);
                });
                widget.onChanged();
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _TypeDropdown(
                      value: c.type,
                      onChanged: (t) {
                        setState(() {
                          c.type = t;
                          if (c.type == CommandType.oneByte) {
                            _byteController.text =
                                c.value.clamp(0, 255).toString();
                            _byteError = null;
                          }
                        });
                        widget.onChanged();
                      },
                    ),
                    const SizedBox(width: 12),
                    _TimeField(
                      initial: c.time,
                      onChanged: (v) {
                        c.time = v;
                        widget.onChanged();
                      },
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Befehl entfernen',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(_days[i]),
                    selected: _isDaySelected(c.weekdaysMask, i),
                    onSelected: (sel) {
                      setState(() {
                        c.weekdaysMask = _toggleDay(c.weekdaysMask, i);
                      });
                      widget.onChanged();
                    },
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    setState(() => c.weekdaysMask = _maskForWeekdays());
                    widget.onChanged();
                  },
                  child: const Text('Wochentage'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => c.weekdaysMask = _maskForWeekend());
                    widget.onChanged();
                  },
                  child: const Text('Wochenende'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => c.weekdaysMask = _maskForAll());
                    widget.onChanged();
                  },
                  child: const Text('Alle'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => c.weekdaysMask = 0);
                    widget.onChanged();
                  },
                  child: const Text('Keine'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (c.type == CommandType.oneBit)
              Row(
                children: [
                  const Text('Wert:'),
                  const SizedBox(width: 8),
                  Switch(
                    value: c.value == 1,
                    onChanged: (v) {
                      setState(() => c.value = v ? 1 : 0);
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(c.value == 1 ? 'Ein (1)' : 'Aus (0)'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Wert:'),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _byteController,
                          decoration: InputDecoration(
                            isDense: true,
                            errorText: _byteError,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            setState(() {
                              if (n == null || n < 0 || n > 255) {
                                _byteError = '0..255';
                                // do not update c.value on invalid input
                              } else {
                                _byteError = null;
                                c.value = n;
                              }
                            });
                            if (n != null && n >= 0 && n <= 255) {
                              widget.onChanged();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: 255,
                          divisions: 255,
                          value: c.value.clamp(0, 255).toDouble(),
                          onChanged: (v) {
                            setState(() {
                              c.value = v.round();
                              _byteError = null;
                              // keep text field in sync when sliding
                              _byteController.text = c.value.toString();
                            });
                            widget.onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                  const Text('1-Byte (0..255)'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static bool _isDaySelected(int mask, int dayIndex) => (mask & (1 << dayIndex)) != 0;
  static int _toggleDay(int mask, int dayIndex) => mask ^ (1 << dayIndex);
  static int _maskForAll() => 0x7F; // 7 days
  static int _maskForWeekdays() => 0x1F; // Mon..Fri
  static int _maskForWeekend() => (1 << 5) | (1 << 6); // Sat, Sun
}

class _TypeDropdown extends StatelessWidget {
  final CommandType value;
  final ValueChanged<CommandType> onChanged;
  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<CommandType>(
      value: value,
      items: const [
        DropdownMenuItem(value: CommandType.oneBit, child: Text('1-Bit')),
        DropdownMenuItem(value: CommandType.oneByte, child: Text('1-Byte')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _TimeField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  const _TimeField({required this.initial, required this.onChanged});

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time),
      label: Text(_value),
      onPressed: () async {
        final parts = _value.split(':');
        final h = int.tryParse(parts.isNotEmpty ? parts[0] : '8') ?? 8;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59)),
          builder: (ctx, child) {
            // Ensure 24h format typical for German locale
            final mq = MediaQuery.of(ctx);
            return MediaQuery(
              data: mq.copyWith(alwaysUse24HourFormat: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
        if (picked != null) {
          setState(() {
            _value = _format(picked);
          });
          widget.onChanged(_value);
        }
      },
    );
  }

  String _format(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' ;
}

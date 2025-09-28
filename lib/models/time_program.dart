import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum CommandType { oneBit, oneByte }

class TimeCommand {
  CommandType type;
  int weekdaysMask;
  String time;
  int value;
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

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:xml/xml_events.dart';

class XmltvProgramme {
  const XmltvProgramme({
    required this.channelId,
    required this.start,
    required this.end,
    required this.title,
    this.description,
  });

  final String channelId; // lowercased
  final DateTime start; // UTC
  final DateTime end; // UTC
  final String title;
  final String? description;
}

/// XMLTV timestamps: `yyyyMMddHHmmss [±HHMM]`, sometimes truncated and
/// sometimes without the offset (assume UTC then).
DateTime? parseXmltvDate(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  final match = RegExp(
    r'^(\d{4,14})(?:\s*([+-])(\d{2}):?(\d{2}))?',
  ).firstMatch(s);
  if (match == null) return null;
  final digits = match.group(1)!.padRight(14, '0');
  final year = int.parse(digits.substring(0, 4));
  if (year < 1970) return null;
  var dt = DateTime.utc(
    year,
    int.parse(digits.substring(4, 6)),
    int.parse(digits.substring(6, 8)),
    int.parse(digits.substring(8, 10)),
    int.parse(digits.substring(10, 12)),
    int.parse(digits.substring(12, 14)),
  );
  if (match.group(2) != null) {
    final offset = Duration(
      hours: int.parse(match.group(3)!),
      minutes: int.parse(match.group(4)!),
    );
    dt = match.group(2) == '+' ? dt.subtract(offset) : dt.add(offset);
  }
  return dt;
}

/// Streaming XMLTV parse: XML events in, programme batches out. Nothing is
/// accumulated beyond the current batch, so file size doesn't matter.
///
/// [wantedChannels] (lowercased ids) drops programmes for channels the user
/// doesn't have; [minEnd]/[maxStart] clamp the horizon — together they cut
/// multi-day full-provider EPGs down to a few percent of their row count.
Stream<List<XmltvProgramme>> parseXmltv(
  Stream<String> chunks, {
  Set<String>? wantedChannels,
  DateTime? minEnd,
  DateTime? maxStart,
  int batchSize = 2000,
}) async* {
  var batch = <XmltvProgramme>[];

  String? channel;
  DateTime? start;
  DateTime? end;
  var inProgramme = false;
  String? textTarget; // 'title' | 'desc'
  final title = StringBuffer();
  final desc = StringBuffer();

  void closeProgramme() {
    inProgramme = false;
    textTarget = null;
    final ch = channel;
    final from = start;
    final to = end;
    channel = null;
    if (ch == null || ch.isEmpty || from == null || to == null) return;
    if (!to.isAfter(from) ||
        (wantedChannels != null && !wantedChannels.contains(ch)) ||
        (minEnd != null && !to.isAfter(minEnd)) ||
        (maxStart != null && !from.isBefore(maxStart))) {
      return;
    }
    final t = title.toString().trim();
    final d = desc.toString().trim();
    batch.add(
      XmltvProgramme(
        channelId: ch,
        start: from,
        end: to,
        title: t.isEmpty ? 'No title' : t,
        description: d.isEmpty ? null : d,
      ),
    );
  }

  final events = chunks.toXmlEvents().normalizeEvents().flatten();
  await for (final event in events) {
    switch (event) {
      case XmlStartElementEvent(name: 'programme'):
        String? attr(String name) {
          for (final a in event.attributes) {
            if (a.name == name) return a.value;
          }
          return null;
        }

        channel = attr('channel')?.trim().toLowerCase();
        start = parseXmltvDate(attr('start'));
        end = parseXmltvDate(attr('stop'));
        title.clear();
        desc.clear();
        inProgramme = true;
        // Self-closing programmes never get an end event.
        if (event.isSelfClosing) closeProgramme();
      case XmlStartElementEvent(name: 'title') when inProgramme:
        textTarget = 'title';
      case XmlStartElementEvent(name: 'desc') when inProgramme:
        textTarget = 'desc';
      case XmlTextEvent() when textTarget != null:
        (textTarget == 'title' ? title : desc).write(event.value);
      case XmlCDATAEvent() when textTarget != null:
        (textTarget == 'title' ? title : desc).write(event.value);
      case XmlEndElementEvent(name: 'title' || 'desc'):
        textTarget = null;
      case XmlEndElementEvent(name: 'programme'):
        closeProgramme();
      default:
        break;
    }
    if (batch.length >= batchSize) {
      yield batch;
      batch = <XmltvProgramme>[];
    }
  }
  if (batch.isNotEmpty) yield batch;
}

class _XmltvJob {
  const _XmltvJob(
    this.port,
    this.filePath,
    this.wantedChannels,
    this.minEndMs,
    this.maxStartMs,
  );

  final SendPort port;
  final String filePath;
  final Set<String> wantedChannels;
  final int minEndMs;
  final int maxStartMs;
}

Future<void> _xmltvWorker(_XmltvJob job) async {
  try {
    final chunks = File(
      job.filePath,
    ).openRead().transform(const Utf8Decoder(allowMalformed: true));
    final batches = parseXmltv(
      chunks,
      wantedChannels: job.wantedChannels,
      minEnd: DateTime.fromMillisecondsSinceEpoch(job.minEndMs, isUtc: true),
      maxStart: DateTime.fromMillisecondsSinceEpoch(
        job.maxStartMs,
        isUtc: true,
      ),
    );
    await for (final batch in batches) {
      job.port.send(batch);
    }
    job.port.send(null); // done
  } catch (e) {
    job.port.send('$e');
  }
}

/// Parses an XMLTV file in a background isolate, streaming programme batches
/// back so the caller can insert-and-drop each one (1GB-RAM box friendly).
Stream<List<XmltvProgramme>> parseXmltvFileInIsolate(
  String filePath, {
  required Set<String> wantedChannels,
  required DateTime minEnd,
  required DateTime maxStart,
}) async* {
  final port = ReceivePort();
  final isolate = await Isolate.spawn(
    _xmltvWorker,
    _XmltvJob(
      port.sendPort,
      filePath,
      wantedChannels,
      minEnd.toUtc().millisecondsSinceEpoch,
      maxStart.toUtc().millisecondsSinceEpoch,
    ),
    onError: port.sendPort,
  );
  try {
    await for (final message in port) {
      if (message == null) break;
      if (message is List<XmltvProgramme>) {
        yield message;
      } else if (message is String) {
        throw Exception('EPG parse failed: $message');
      } else if (message is List) {
        // Uncaught isolate error arrives as [error, stackTrace].
        throw Exception('EPG parse failed: ${message.first}');
      }
    }
  } finally {
    port.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

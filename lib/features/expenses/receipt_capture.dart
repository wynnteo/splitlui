import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'receipt_hints.dart';
import 'receipt_total_detector.dart';

class ReceiptDraft {
  const ReceiptDraft(this.jpeg, this.suggestedTotal, this.hints,
    this.totalAnalysis);
  final Uint8List jpeg;
  final String? suggestedTotal;
  final ReceiptHints hints;
  final ReceiptTotalAnalysis totalAnalysis;
}

/// OCR hints are not trusted accounting values; always require user review.
class ReceiptCapture {
  static const maxBytes = 5 * 1024 * 1024;

  static Future<ReceiptDraft?> choose(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source, maxWidth: 2000, imageQuality: 85);
    if (photo == null) return null;
    final compressed = await FlutterImageCompress.compressWithFile(
      photo.path, quality: 75, format: CompressFormat.jpeg,
      minWidth: 1600, minHeight: 1600);
    if (compressed == null || compressed.isEmpty ||
        compressed.length > maxBytes) {
      throw StateError('Receipt image could not be compressed under 5 MB');
    }
    String text = '';
    final recogniser = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      text = (await recogniser.processImage(
        InputImage.fromFilePath(photo.path))).text;
    } catch (_) {
      // Keep the receipt image even when OCR cannot read the text.
    } finally {
      await recogniser.close();
    }
    final totals=ReceiptTotalDetector.parse(text);
    return ReceiptDraft(Uint8List.fromList(compressed),
      totals.ambiguous ? null : totals.suggested?.amount,
      ReceiptHints.parse(text), totals);
  }

  static String? extractTotal(String text) {
    final analysis=ReceiptTotalDetector.parse(text);
    return analysis.ambiguous ? null : analysis.suggested?.amount;
  }
}

class ReceiptStorage {
  final SupabaseClient db = Supabase.instance.client;
  static const bucket = 'splitlui-receipts';
  static final _rng = Random.secure();

  Future<Map<String,dynamic>?> get({String? expenseId,
      String? fundEntryId}) async {
    var query = db.from('trip_receipts').select('object_path');
    if (expenseId != null) query = query.eq('expense_id', expenseId);
    else if (fundEntryId != null) query = query.eq('fund_entry_id', fundEntryId);
    else throw ArgumentError('Receipt target missing');
    return await query.maybeSingle();
  }

  Future<String> signedUrl(String path) =>
      db.storage.from(bucket).createSignedUrl(path, 60);

  static String _uuid() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0,8)}-${hex.substring(8,12)}-'
      '${hex.substring(12,16)}-${hex.substring(16,20)}-'
      '${hex.substring(20)}';
  }

  Future<void> upload({required String groupId, required Uint8List jpeg,
      String? expenseId, String? fundEntryId}) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null || (expenseId == null) == (fundEntryId == null)) {
      throw StateError('Invalid receipt target');
    }
    final path = '$groupId/$uid/${_uuid()}.jpg';
    await db.storage.from(bucket).uploadBinary(path, jpeg,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',upsert:false,cacheControl:'3600'));
    try {
      await db.rpc('attach_trip_receipt', params: {
        'p_group':groupId, 'p_expense':expenseId,
        'p_fund_entry':fundEntryId, 'p_object_path':path,
      });
    } catch (_) {
      // The RPC may have succeeded server-side even though the response was
      // lost. Do NOT delete the uploaded image here: a committed mapping
      // might now point to it. Offline sync checks the existing mapping
      // before uploading again. Orphan cleanup must be a separate,
      // explicitly reconciled maintenance operation.
      try {
        final linked = await get(
          expenseId:expenseId,fundEntryId:fundEntryId);
        if (linked?['object_path'] == path) return;
      } catch (_) { /* Keep the object until it can be reconciled. */ }
      rethrow;
    }
  }
}


/// A signed link is requested only when a member opens an expense detail.
/// The underlying bucket is private and never uses a public asset URL.
class ReceiptAttachmentPreview extends StatefulWidget {
  const ReceiptAttachmentPreview({super.key, this.expenseId, this.fundEntryId});
  final String? expenseId;
  final String? fundEntryId;

  @override
  State<ReceiptAttachmentPreview> createState() =>
      _ReceiptAttachmentPreviewState();
}

class _ReceiptAttachmentPreviewState extends State<ReceiptAttachmentPreview> {
  late final Future<String?> url;

  Future<String?> load() async {
    final storage = ReceiptStorage();
    final receipt = await storage.get(
      expenseId: widget.expenseId,
      fundEntryId: widget.fundEntryId);
    if (receipt == null) return null;
    return storage.signedUrl(receipt['object_path'] as String);
  }

  @override
  void initState() {
    super.initState();
    url = load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: url,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error));
        }
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(snapshot.data!,
            height: 220, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined, size: 36)),
        ),
      );
    },
  );
}

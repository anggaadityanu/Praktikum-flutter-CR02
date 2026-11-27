/// Validator password baru: sama dengan aturan di server
/// (8 sampai 72 karakter, minimal satu huruf dan satu angka).
String? validasiPasswordBaru(String? nilai) {
  final t = nilai ?? '';
  if (t.isEmpty) return 'Password wajib diisi';
  if (t.length < 8) return 'Password minimal 8 karakter';
  if (t.length > 72) return 'Password maksimal 72 karakter';
  if (!RegExp(r'[A-Za-z]').hasMatch(t)) {
    return 'Password harus mengandung minimal satu huruf';
  }
  if (!RegExp(r'\d').hasMatch(t)) {
    return 'Password harus mengandung minimal satu angka';
  }
  return null;
}

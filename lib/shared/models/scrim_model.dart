class ScrimModel {
  final String id, title, adminName, date, time, mode;
  final int slotFilled, slotTotal, fee, prize;
  final bool isPremium;

  const ScrimModel({
    required this.id, required this.title, required this.adminName,
    required this.date, required this.time, required this.mode,
    required this.slotFilled, required this.slotTotal,
    required this.fee, required this.prize, required this.isPremium,
  });

  bool get isFull       => slotFilled >= slotTotal;
  bool get isAlmostFull => !isFull && (slotFilled / slotTotal) >= 0.7;
  int  get slotRemaining => slotTotal - slotFilled;

  String get slotStatus {
    if (isFull)       return 'PENUH';
    if (isAlmostFull) return 'HAMPIR PENUH';
    return 'TERSEDIA';
  }
}

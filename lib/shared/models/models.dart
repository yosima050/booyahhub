// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

// ── Enums ──
enum ScrimStatus { menungguVerifikasi, menungguRoomId, berlangsung, selesai }
enum KlaimStatus { available, processing, verified, rejected }
enum UserRole { peserta, admin, platform }
enum PremiumStatus { reguler, premium, kedaluwarsa }
enum RegStatus {
  pendingPayment, waitingVerify, verified,
  rejected, waitingRoomId, ongoing, finished
}

// ── Scrim Model ──
class ScrimModel {
  final String id, title, adminName, date, time, mode, description;
  final int slotFilled, slotTotal, fee, prize;
  final bool isPremium;

  const ScrimModel({
    required this.id, required this.title, required this.adminName,
    required this.date, required this.time, required this.mode,
    required this.description, required this.slotFilled,
    required this.slotTotal, required this.fee,
    required this.prize, required this.isPremium,
  });

  bool get isFull       => slotFilled >= slotTotal;
  bool get isAlmostFull => !isFull && (slotFilled / slotTotal) >= 0.7;
  int  get slotRemaining => slotTotal - slotFilled;
  double get slotPercent => slotFilled / slotTotal;

  String get slotStatusLabel {
    if (isFull) return 'PENUH';
    if (isAlmostFull) return 'HAMPIR PENUH';
    return 'TERSEDIA';
  }

  Color slotColor(BuildContext ctx) {
    if (isFull) return const Color(0xFFFF1744);
    if (isAlmostFull) return const Color(0xFFFFAB00);
    return const Color(0xFF00C853);
  }
}

// ── Riwayat / Booking Model ──
class RiwayatModel {
  final String id, scrimTitle, adminName, date, time, roomId;
  final int fee;
  final ScrimStatus status;
  final int? rank, points;

  const RiwayatModel({
    required this.id, required this.scrimTitle, required this.adminName,
    required this.date, required this.time, this.roomId = '',
    required this.fee, required this.status, this.rank, this.points,
  });
}

// ── Klaim Hadiah Model ──
class KlaimModel {
  final String id, scrimTitle, event;
  final int amount;
  final KlaimStatus status;
  final String bankName, bankNumber;

  const KlaimModel({
    required this.id, required this.scrimTitle, required this.event,
    required this.amount, required this.status,
    this.bankName = '', this.bankNumber = '',
  });
}

// ── Tim / Pendaftar Model ──
class PendaftarModel {
  final String id, teamName, captainId, paymentMethod, amount, time;
  bool isApproved, isRejected;

  PendaftarModel({
    required this.id, required this.teamName, required this.captainId,
    required this.paymentMethod, required this.amount, required this.time,
    this.isApproved = false, this.isRejected = false,
  });
}

// ── Skor Tim Model ──
class TeamScoreModel {
  final String id, teamName, icon;
  int placement, kills;

  TeamScoreModel({
    required this.id, required this.teamName, required this.icon,
    required this.placement, required this.kills,
  });

  // Sistem poin Free Fire scrim
  int get placementPoint {
    switch (placement) {
      case 1: return 12;
      case 2: return 9;
      case 3: return 7;
      case 4: return 5;
      default: return 2;
    }
  }
  int get totalPoint => placementPoint + kills;
}

// ── User Model ──
class UserModel {
  final String id, name, email, icon;
  UserRole role;
  bool isSuspended;
  PremiumStatus premiumStatus;

  UserModel({
    required this.id, required this.name, required this.email,
    required this.icon, required this.role,
    this.isSuspended = false,
    this.premiumStatus = PremiumStatus.reguler,
  });
}

// ── Notifikasi Model ──
class NotifModel {
  final String icon, title, message, time;
  final Color color;
  bool isRead;
  NotifModel({
    required this.icon, required this.title, required this.message,
    required this.time, required this.color, this.isRead = false,
  });
}

// ── Transaksi Model ──
class TransaksiModel {
  final String icon, description, team, date, amount;
  final bool isIncome;

  const TransaksiModel({
    required this.icon, required this.description, required this.team,
    required this.date, required this.amount, required this.isIncome,
  });
}

// ── Dummy Data ──
class DummyData {
  static List<ScrimModel> get scrims => [
    const ScrimModel(
      id: '1', title: 'BOOYAH CUP SEASON 7', adminName: 'ProScrim_ID',
      date: '11 Mar 2026', time: '19:00 WIB', mode: 'Battle Royale',
      description: 'Scrim BR kompetitif. Room ID dikirim 30 menit sebelum mulai.',
      slotFilled: 15, slotTotal: 20, fee: 25000, prize: 297500, isPremium: true,
    ),
    const ScrimModel(
      id: '2', title: 'MIDNIGHT CLASH RANKED', adminName: 'EliteGaming',
      date: '11 Mar 2026', time: '21:00 WIB', mode: 'Clash Squad',
      description: '', slotFilled: 16, slotTotal: 16, fee: 15000, prize: 204000, isPremium: false,
    ),
    const ScrimModel(
      id: '3', title: 'SUNDAY WARRIOR CUP', adminName: 'ScrimKing_JKT',
      date: '13 Mar 2026', time: '15:00 WIB', mode: 'Battle Royale',
      description: '', slotFilled: 5, slotTotal: 24, fee: 20000, prize: 340000, isPremium: true,
    ),
  ];

  static List<RiwayatModel> get riwayat => [
    const RiwayatModel(
      id: '1', scrimTitle: 'BOOYAH CUP SEASON 7',
      adminName: 'ProScrim_ID', date: '11 Mar 2026', time: '19:00 WIB',
      roomId: 'FF-98723', fee: 25000, status: ScrimStatus.berlangsung,
    ),
    const RiwayatModel(
      id: '2', scrimTitle: 'MIDNIGHT CLASH RANKED',
      adminName: 'EliteGaming', date: '15 Mar 2026', time: '21:00 WIB',
      fee: 15000, status: ScrimStatus.menungguVerifikasi,
    ),
    const RiwayatModel(
      id: '3', scrimTitle: 'BOOYAH CUP SEASON 6',
      adminName: 'ProScrim_ID', date: '8 Mar 2026', time: '19:00 WIB',
      roomId: 'FF-88211', fee: 25000, status: ScrimStatus.selesai,
      rank: 4, points: 115,
    ),
  ];

  static List<KlaimModel> get klaim => [
    const KlaimModel(
      id: '1', scrimTitle: 'BOOYAH CUP S6', event: 'Juara 3',
      amount: 42500, status: KlaimStatus.processing,
      bankName: 'BCA', bankNumber: '•••• 4521',
    ),
    const KlaimModel(
      id: '2', scrimTitle: 'BOOYAH CUP S5', event: 'Juara 3',
      amount: 59500, status: KlaimStatus.available,
      bankName: '', bankNumber: '',
    ),
    const KlaimModel(
      id: '3', scrimTitle: 'MIDNIGHT CLASH S3', event: 'Juara 2',
      amount: 76000, status: KlaimStatus.verified,
      bankName: 'BCA', bankNumber: '•••• 4521',
    ),
  ];

  static List<PendaftarModel> get pendaftar => [
    PendaftarModel(id:'1', teamName:'FIRE WOLVES',  captainId:'WolfAlpha#321', paymentMethod:'Transfer', amount:'Rp25.000', time:'18:42'),
    PendaftarModel(id:'2', teamName:'DEATH SQUAD',  captainId:'DeathX#456',   paymentMethod:'QRIS',     amount:'Rp25.000', time:'18:55'),
    PendaftarModel(id:'3', teamName:'EAGLE FORCE',  captainId:'Eagle#789',    paymentMethod:'Transfer', amount:'Rp25.000', time:'19:01'),
    PendaftarModel(id:'4', teamName:'TIGER CLAN',   captainId:'Tiger#222',    paymentMethod:'QRIS',     amount:'Rp25.000', time:'19:10'),
  ];

  static List<TeamScoreModel> get scores => [
    TeamScoreModel(id:'1', teamName:'FIRE WOLVES',  icon:'🐺', placement:4, kills:17),
    TeamScoreModel(id:'2', teamName:'DEATH SQUAD',  icon:'⚔️', placement:1, kills:28),
    TeamScoreModel(id:'3', teamName:'EAGLE FORCE',  icon:'🦅', placement:2, kills:24),
    TeamScoreModel(id:'4', teamName:'TIGER CLAN',   icon:'🐯', placement:3, kills:19),
    TeamScoreModel(id:'5', teamName:'BLAZE TEAM',   icon:'🔥', placement:5, kills:14),
    TeamScoreModel(id:'6', teamName:'SKULL FC',     icon:'💀', placement:6, kills:11),
  ];

  static List<UserModel> get users => [
    UserModel(id:'1', name:'WolfAlpha#321', email:'wolf@mail.com',  icon:'🐺', role:UserRole.peserta),
    UserModel(id:'2', name:'ProScrim_ID',   email:'pro@mail.com',   icon:'🔥', role:UserRole.admin,    premiumStatus: PremiumStatus.premium),
    UserModel(id:'3', name:'DeathX#456',    email:'death@mail.com', icon:'⚔️', role:UserRole.peserta),
    UserModel(id:'4', name:'Eagle#789',     email:'eagle@mail.com', icon:'🦅', role:UserRole.admin),
    UserModel(id:'5', name:'SuspendUser',   email:'sus@mail.com',   icon:'🚫', role:UserRole.peserta,  isSuspended: true),
    UserModel(id:'6', name:'IronFist#111',  email:'iron@mail.com',  icon:'🏆', role:UserRole.peserta),
  ];

  static List<TransaksiModel> get transaksi => [
    const TransaksiModel(icon:'💳', description:'QRIS – Booyah Cup S7',     team:'FIRE WOLVES',  date:'11 Mar', amount:'Rp25.000',  isIncome:true),
    const TransaksiModel(icon:'🏦', description:'Transfer – Midnight Clash', team:'DEATH SQUAD',  date:'11 Mar', amount:'Rp15.000',  isIncome:true),
    const TransaksiModel(icon:'💸', description:'Klaim Hadiah Diproses',     team:'ALPHA SQUAD',  date:'10 Mar', amount:'Rp148.750', isIncome:false),
    const TransaksiModel(icon:'💳', description:'QRIS – Sunday Warrior',     team:'GHOST RECON',  date:'10 Mar', amount:'Rp20.000',  isIncome:true),
    const TransaksiModel(icon:'💸', description:'Klaim Hadiah Diproses',     team:'DEATH DEALER', date:'9 Mar',  amount:'Rp89.250',  isIncome:false),
  ];

  static List<NotifModel> get notifikasi => [
    NotifModel(icon: '🔴', title: 'ROOM ID TERSEDIA',
      message: 'Room ID BOOYAH CUP S7 jam 19:00 sudah tersedia. Segera join!',
      time: '30 menit lalu', color: const Color(0xFFFF4444), isRead: false),
    NotifModel(icon: '✅', title: 'PEMBAYARAN DIKONFIRMASI',
      message: 'Pembayaran Booyah Cup S7 sebesar Rp25.000 telah dikonfirmasi.',
      time: '2 jam lalu', color: const Color(0xFF00C853), isRead: false),
    NotifModel(icon: '🏆', title: 'HASIL PERTANDINGAN',
      message: 'Tim FIRE WOLVES meraih peringkat ke-4 di BOOYAH CUP S6.',
      time: '2 hari lalu', color: const Color(0xFFFFD700)),
    NotifModel(icon: '💰', title: 'HADIAH DALAM PROSES',
      message: 'Transfer hadiah Rp42.500 sedang diproses. Est. 1x24 jam.',
      time: '3 hari lalu', color: const Color(0xFFFFAB00)),
  ];
}

// Helper formatter
String fmtRupiah(int n) {
  if (n >= 1000000) return 'Rp${(n / 1000000).toStringAsFixed(1)}jt';
  if (n >= 1000) return 'Rp${(n / 1000).toStringAsFixed(0)}k';
  return 'Rp$n';
}

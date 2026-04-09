import 'package:flutter/material.dart';

class BankAccount {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String? accountType;

  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.accountType,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountType: json['account_type'],
    );
  }

  String get maskedAccountNumber {
    if (accountNumber.length < 4) return accountNumber;
    return '****' + accountNumber.substring(accountNumber.length - 4);
  }
}

class PayoutRequest {
  final int id;
  final double amount;
  final String type;
  final String status;
  final String? receiptUrl;
  final DateTime? createdAt;

  const PayoutRequest({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.receiptUrl,
    this.createdAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id'] ?? 0,
      amount: _toDouble(json['amount']) ?? 0.0,
      type: json['type'] ?? '',
      status: json['status'] ?? 'pending',
      receiptUrl: json['receipt_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  bool get isPaid => status == 'paid';
}

class Collaboration {
  final int id;
  final int brandId;
  final int creatorId;
  final int? packageId;
  final double amount;
  final double platformFee;
  final double creatorAmount;
  final String status;
  final String? brandNotes;
  final String? revisionNotes;
  final int revisionCount;
  final int maxRevisions;
  final String? deliverableContent;
  final String? deliverableType;
  final String? deliverablePreviewPath;
  final String? deliverablePreviewStatus;
  final bool creatorClaimed;
  final bool brandClaimed;
  final double? resolvedRefundAmount;
  final double? resolvedCreatorAmount;
  
  final Map<String, dynamic>? brand;
  final Map<String, dynamic>? creator;
  final Map<String, dynamic>? package;
  final List<PayoutRequest> payoutRequests;

  const Collaboration({
    required this.id,
    required this.brandId,
    required this.creatorId,
    this.packageId,
    required this.amount,
    required this.platformFee,
    required this.creatorAmount,
    required this.status,
    this.brandNotes,
    this.revisionNotes,
    this.revisionCount = 0,
    this.maxRevisions = 0,
    this.deliverableContent,
    this.deliverableType,
    this.deliverablePreviewPath,
    this.deliverablePreviewStatus,
    this.creatorClaimed = false,
    this.brandClaimed = false,
    this.resolvedRefundAmount,
    this.resolvedCreatorAmount,
    this.brand,
    this.creator,
    this.package,
    this.payoutRequests = const [],
  });

  factory Collaboration.fromJson(Map<String, dynamic> json) {
    return Collaboration(
      id: json['id'] ?? 0,
      brandId: json['brand_id'] ?? 0,
      creatorId: json['creator_id'] ?? 0,
      packageId: json['package_id'],
      amount: _toDouble(json['amount']) ?? 0.0,
      platformFee: _toDouble(json['platform_fee']) ?? 0.0,
      creatorAmount: _toDouble(json['creator_amount']) ?? 0.0,
      status: json['status'] ?? 'pending',
      brandNotes: json['brand_notes'],
      revisionNotes: json['revision_notes'],
      revisionCount: json['revision_count'] ?? 0,
      maxRevisions: json['max_revisions'] ?? 0,
      deliverableContent: json['deliverable_content'],
      deliverableType: json['deliverable_type'],
      deliverablePreviewPath: json['deliverable_preview_path'],
      deliverablePreviewStatus: json['deliverable_preview_status'],
      creatorClaimed: json['creator_claimed'] ?? false,
      brandClaimed: json['brand_claimed'] ?? false,
      resolvedRefundAmount: _toDouble(json['resolved_refund_amount'], nullable: true),
      resolvedCreatorAmount: _toDouble(json['resolved_creator_amount'], nullable: true),
      brand: json['brand'],
      creator: json['creator'],
      package: json['package'],
      payoutRequests: (json['payout_requests'] as List<dynamic>? ?? [])
          .map((p) => PayoutRequest.fromJson(p))
          .toList(),
    );
  }

  int get statusIndex {
    final map = {
      'pending': 0,
      'accepted': 1,
      'paid': 2,
      'revision_requested': 2,
      'disputed': 3,
      'delivered': 3,
      'resolved': 4,
      'completed': 4,
      'rejected': -1
    };
    return map[status] ?? 0;
  }

  double get progressPercentage {
    final idx = statusIndex;
    if (idx < 0) return 0.0;
    return (idx / 4.0);
  }

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending Acceptance';
      case 'accepted': return 'Accepted - Awaiting Payment';
      case 'paid': return 'Paid - Creator Working';
      case 'revision_requested': return 'Revision Requested';
      case 'delivered': return 'Delivered - Reviewing';
      case 'disputed': return 'Dispute Under Review';
      case 'resolved': return 'Mediation Settled';
      case 'completed': return 'Project Completed';
      case 'rejected': return 'Project Rejected';
      default: return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (statusIndex) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.indigo;
      case 3: return Colors.amber;
      case 4: return Colors.green;
      case -1: return Colors.red;
      default: return Colors.grey;
    }
  }
}

double? _toDouble(dynamic val, {bool nullable = false}) {
  if (val == null) return nullable ? null : 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? (nullable ? null : 0.0);
  return nullable ? null : 0.0;
}

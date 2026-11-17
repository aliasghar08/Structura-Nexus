// ============================================================================
// CollaborationService & StructuralDiffEngine — Real-Time Cloud Collaboration
// Manages shared project sessions, active collaborator presence, pinned 3D
// joint/member review comments, and baseline vs current structural revision diffs.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import '../models/structural_models.dart';
import 'firebase_auth_service.dart';

class ReviewComment {
  final String id;
  final String sessionId;
  final String? nodeId;
  final String? memberId;
  final String authorName;
  final String authorEmail;
  final String text;
  final DateTime timestamp;
  bool isResolved;
  final List<double>? coords;

  ReviewComment({
    required this.id,
    required this.sessionId,
    this.nodeId,
    this.memberId,
    required this.authorName,
    required this.authorEmail,
    required this.text,
    required this.timestamp,
    this.isResolved = false,
    this.coords,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'node_id': nodeId,
        'member_id': memberId,
        'author_name': authorName,
        'author_email': authorEmail,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'is_resolved': isResolved,
        'coords': coords,
      };

  factory ReviewComment.fromJson(Map<String, dynamic> json) => ReviewComment(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        nodeId: json['node_id'] as String?,
        memberId: json['member_id'] as String?,
        authorName: json['author_name'] as String? ?? 'Reviewer',
        authorEmail: json['author_email'] as String? ?? 'engineer@nexus.lab',
        text: json['text'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        isResolved: json['is_resolved'] as bool? ?? false,
        coords: (json['coords'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      );
}

class CollaboratorPresence {
  final String userId;
  final String displayName;
  final String role; // 'CO_ENGINEER' or 'VIEWER_COMMENTER'
  final String colorHex;
  final String? selectedEntityId;
  final DateTime lastActive;

  CollaboratorPresence({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.colorHex,
    this.selectedEntityId,
    required this.lastActive,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'role': role,
        'color_hex': colorHex,
        'selected_entity_id': selectedEntityId,
        'last_active': lastActive.toIso8601String(),
      };
}

enum DiffChangeType {
  added,
  modified,
  removed,
}

class MemberDiff {
  final String memberId;
  final DiffChangeType changeType;
  final String? oldSection;
  final String? newSection;
  final double? oldDcr;
  final double? newDcr;
  final String details;

  const MemberDiff({
    required this.memberId,
    required this.changeType,
    this.oldSection,
    this.newSection,
    this.oldDcr,
    this.newDcr,
    required this.details,
  });
}

class DiffSummary {
  final int addedCount;
  final int modifiedCount;
  final int removedCount;
  final List<MemberDiff> diffs;

  const DiffSummary({
    required this.addedCount,
    required this.modifiedCount,
    required this.removedCount,
    required this.diffs,
  });

  bool get hasChanges => addedCount > 0 || modifiedCount > 0 || removedCount > 0;
}

class StructuralDiffEngine {
  /// Compares baseline model vs current model to isolate added, modified, and removed elements.
  static DiffSummary compare({
    required StructuralModel baseline,
    required StructuralModel current,
  }) {
    final Map<String, StructuralMember> baseMembers = {for (final m in baseline.members) m.id: m};
    final Map<String, StructuralMember> currMembers = {for (final m in current.members) m.id: m};

    final List<MemberDiff> diffs = [];
    int added = 0;
    int modified = 0;
    int removed = 0;

    // Check for added & modified members
    for (final currId in currMembers.keys) {
      final currM = currMembers[currId]!;
      if (!baseMembers.containsKey(currId)) {
        added++;
        diffs.add(MemberDiff(
          memberId: currId,
          changeType: DiffChangeType.added,
          newSection: currM.section,
          newDcr: currM.governingDcr,
          details: 'Newly inserted member profile ${currM.section}',
        ));
      } else {
        final baseM = baseMembers[currId]!;
        final bool sectionChanged = baseM.section != currM.section;
        final bool releaseChanged = baseM.hasReleases != currM.hasReleases;
        final bool crackChanged = baseM.crackedSectionFactor != currM.crackedSectionFactor;

        if (sectionChanged || releaseChanged || crackChanged) {
          modified++;
          final List<String> changeNotes = [];
          if (sectionChanged) changeNotes.add('${baseM.section} → ${currM.section}');
          if (releaseChanged) changeNotes.add('Releases modified');
          if (crackChanged) changeNotes.add('Ieff ${baseM.crackedSectionFactor} → ${currM.crackedSectionFactor}');

          diffs.add(MemberDiff(
            memberId: currId,
            changeType: DiffChangeType.modified,
            oldSection: baseM.section,
            newSection: currM.section,
            oldDcr: baseM.governingDcr,
            newDcr: currM.governingDcr,
            details: changeNotes.join('; '),
          ));
        }
      }
    }

    // Check for removed members
    for (final baseId in baseMembers.keys) {
      if (!currMembers.containsKey(baseId)) {
        removed++;
        final baseM = baseMembers[baseId]!;
        diffs.add(MemberDiff(
          memberId: baseId,
          changeType: DiffChangeType.removed,
          oldSection: baseM.section,
          oldDcr: baseM.governingDcr,
          details: 'Removed from current structural revision',
        ));
      }
    }

    return DiffSummary(
      addedCount: added,
      modifiedCount: modified,
      removedCount: removed,
      diffs: diffs,
    );
  }
}

class CollaborationService {
  static final CollaborationService _instance = CollaborationService._internal();
  factory CollaborationService() => _instance;
  CollaborationService._internal();

  String? _activeSessionId;
  String get activeSessionId => _activeSessionId ?? 'nexus_demo_session';
  bool get hasActiveSession => _activeSessionId != null;

  String _currentRole = 'CO_ENGINEER';
  String get currentRole => _currentRole;
  bool get canEdit => _currentRole == 'CO_ENGINEER';

  final List<ReviewComment> _inMemoryComments = [];
  final StreamController<List<ReviewComment>> _commentsController = StreamController.broadcast();
  Stream<List<ReviewComment>> get commentsStream => _commentsController.stream;

  final List<CollaboratorPresence> _inMemoryCollaborators = [];
  final StreamController<List<CollaboratorPresence>> _collaboratorsController = StreamController.broadcast();
  Stream<List<CollaboratorPresence>> get collaboratorsStream => _collaboratorsController.stream;

  StructuralModel? _baselineModel;
  StructuralModel? get baselineModel => _baselineModel;

  void setBaselineModel(StructuralModel model) {
    _baselineModel = model.copyWith();
  }

  /// Initializes or joins a shared collaboration session.
  Future<String> initSession(StructuralModel model, {String? sessionId, String role = 'CO_ENGINEER'}) async {
    _activeSessionId = sessionId ?? 'sess_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    _currentRole = role;
    setBaselineModel(model);

    // Seed mock presence and initial review comment if empty
    if (_inMemoryComments.isEmpty) {
      _inMemoryComments.add(
        ReviewComment(
          id: 'comm_1',
          sessionId: _activeSessionId!,
          nodeId: model.nodes.isNotEmpty ? model.nodes.last.id : 'N1',
          authorName: 'Sarah Chen, PE',
          authorEmail: 'schen@structure.org',
          text: 'Verify W14X90 column splice connection capacity under combined lateral wind drift.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
          isResolved: false,
          coords: model.nodes.isNotEmpty ? [model.nodes.last.x, model.nodes.last.y, model.nodes.last.z] : [0, 3.6, 0],
        ),
      );
      _commentsController.add(List.from(_inMemoryComments));
    }

    if (_inMemoryCollaborators.isEmpty) {
      final user = FirebaseAuthService().currentUser;
      _inMemoryCollaborators.add(
        CollaboratorPresence(
          userId: user?.uid ?? 'lead_eng_1',
          displayName: user?.displayName ?? 'Ali Asghar (Lead)',
          role: 'CO_ENGINEER',
          colorHex: '#00F0FF',
          lastActive: DateTime.now(),
        ),
      );
      _inMemoryCollaborators.add(
        CollaboratorPresence(
          userId: 'collab_2',
          displayName: 'Elena Rostova, SE',
          role: 'VIEWER_COMMENTER',
          colorHex: '#F59E0B',
          lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      );
      _collaboratorsController.add(List.from(_inMemoryCollaborators));
    }

    return _activeSessionId!;
  }

  /// Generates a shareable 1-click review link
  String generateShareLink({String? sessionId, String role = 'VIEWER_COMMENTER'}) {
    final sess = sessionId ?? activeSessionId;
    return 'https://structura-nexus.web.app/?session=$sess&role=$role';
  }

  /// Adds a new review comment pinned to a joint or member
  Future<ReviewComment> addComment({
    required String text,
    String? nodeId,
    String? memberId,
    List<double>? coords,
  }) async {
    final user = FirebaseAuthService().currentUser;
    final comment = ReviewComment(
      id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: activeSessionId,
      nodeId: nodeId,
      memberId: memberId,
      authorName: user?.displayName ?? (user?.email?.split('@').first ?? 'Staff Reviewer'),
      authorEmail: user?.email ?? 'engineer@nexus.lab',
      text: text,
      timestamp: DateTime.now(),
      isResolved: false,
      coords: coords,
    );

    _inMemoryComments.add(comment);
    _commentsController.add(List.from(_inMemoryComments));
    return comment;
  }

  /// Toggles resolved status of a comment
  void toggleResolveComment(String commentId) {
    final i = _inMemoryComments.indexWhere((c) => c.id == commentId);
    if (i >= 0) {
      _inMemoryComments[i].isResolved = !_inMemoryComments[i].isResolved;
      _commentsController.add(List.from(_inMemoryComments));
    }
  }

  List<ReviewComment> get comments => List.unmodifiable(_inMemoryComments);
  List<CollaboratorPresence> get collaborators => List.unmodifiable(_inMemoryCollaborators);
}

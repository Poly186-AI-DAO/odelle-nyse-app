part of 'app_database.dart';

mixin AgentOutputCrud on AppDatabaseBase {
  // ====================
  // Agent Outputs CRUD
  // ====================

  Future<int> insertAgentOutput(AgentOutput output) async {
    final db = await database;
    final id = await db.insert('agent_outputs', output.toMap());
    Logger.info('Inserted agent output: ${output.agentType.name}',
        tag: AppDatabase._tag);
    
    await queueSync(
      tableName: 'agent_outputs',
      rowId: id,
      operation: 'INSERT',
      data: output.toMap(),
    );
    
    return id;
  }

  Future<List<AgentOutput>> getAgentOutputs({
    AgentType? agentType,
    bool? reviewed,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (agentType != null) {
      whereClause += 'agent_type = ?';
      whereArgs.add(agentType.name);
    }
    if (reviewed != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'reviewed = ?';
      whereArgs.add(reviewed ? 1 : 0);
    }

    final maps = await db.query(
      'agent_outputs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AgentOutput.fromMap(map)).toList();
  }

  /// Get unreviewed Nano outputs for Chat to review
  Future<List<AgentOutput>> getUnreviewedNanoOutputs() async {
    return getAgentOutputs(agentType: AgentType.nano, reviewed: false);
  }

  /// Get recent outputs from last N minutes
  Future<List<AgentOutput>> getRecentOutputs(int minutes) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    final maps = await db.query(
      'agent_outputs',
      where: 'created_at >= ?',
      whereArgs: [cutoff.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => AgentOutput.fromMap(map)).toList();
  }

  Future<int> updateAgentOutput(AgentOutput output) async {
    final db = await database;
    final count = await db.update(
      'agent_outputs',
      output.toMap(),
      where: 'id = ?',
      whereArgs: [output.id],
    );
    
    if (count > 0 && output.id != null) {
      await queueSync(
        tableName: 'agent_outputs',
        rowId: output.id!,
        operation: 'UPDATE',
        data: output.toMap(),
      );
    }
    
    return count;
  }

  Future<int> markAsReviewed(int id, String reviewedBy, String? notes) async {
    final db = await database;
    final count = await db.update(
      'agent_outputs',
      {
        'reviewed': 1,
        'reviewed_by': reviewedBy,
        'review_notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'agent_outputs',
        rowId: id,
        operation: 'UPDATE',
        data: {'reviewed': 1, 'reviewed_by': reviewedBy, 'review_notes': notes},
      );
    }
    
    return count;
  }

  Future<int> deleteAgentOutput(int id) async {
    final db = await database;
    final count = await db.delete(
      'agent_outputs',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (count > 0) {
      await queueSync(
        tableName: 'agent_outputs',
        rowId: id,
        operation: 'DELETE',
      );
    }
    
    return count;
  }
}

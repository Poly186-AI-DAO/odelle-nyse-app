import 'base_tool.dart';

/// Tool for searching the knowledge graph
class KnowledgeGraphSearchTool implements BaseTool {
  @override
  String get type => 'function';

  @override
  String get name => 'search_knowledge_graph';

  @override
  String get description =>
      'Search the user\'s knowledge graph with the given query.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'strict': true,
        'properties': {
          'user_id': {
            'type': 'string',
            'description':
                'The ID of the user whose knowledge graph to search.',
          },
          'query': {
            'type': 'string',
            'description':
                'The search query to find relevant information in the knowledge graph.',
          },
        },
        'required': ['user_id', 'query'],
      };

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}

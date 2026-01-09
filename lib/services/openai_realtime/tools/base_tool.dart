/// Base interface for OpenAI function tools
abstract class BaseTool {
  /// Get the tool configuration as a Map
  Map<String, dynamic> toJson();

  /// The type of the tool (e.g., 'function')
  String get type;

  /// The name of the tool
  String get name;

  /// The description of the tool
  String get description;

  /// The parameters schema for the tool
  Map<String, dynamic> get parameters;
}

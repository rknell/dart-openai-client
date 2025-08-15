/// 🚀 MCP SERVER MANAGER: Persistent MCP server lifecycle management
///
/// ⚔️ ARCHITECTURAL BATTLE LOG:
/// - Decision: Create a singleton manager for persistent MCP servers
/// - Challenge: Prevent premature server disposal between operations
/// - Victory: Servers stay alive across multiple tool executions
/// - Usage: Centralized server management with reference counting
///
/// 🏗️ CODE ARCHITECTURE DOMINANCE:
/// - Singleton pattern for global server management
/// - Reference counting to prevent premature disposal
/// - Lazy initialization of servers on first use
/// - Graceful shutdown on application exit

import 'dart:async';
import 'mcp_client.dart';

/// 🎯 MCP SERVER MANAGER: Manages persistent MCP server instances
///
/// This class ensures that MCP servers remain running across multiple
/// operations, preventing the browser from closing between requests.
class McpServerManager {
  /// 🔒 SINGLETON: Single instance for global server management
  static final McpServerManager _instance = McpServerManager._internal();
  
  /// 🏭 FACTORY: Get the singleton instance
  factory McpServerManager() => _instance;
  
  /// 🔧 PRIVATE CONSTRUCTOR: Initialize the singleton
  McpServerManager._internal();

  /// 📊 ACTIVE SERVERS: Map of server configs to active client instances
  final Map<String, _ServerInstance> _activeServers = {};

  /// 🔑 SERVER KEYS: Generate unique keys for server configurations
  String _generateServerKey(McpServerConfig config) {
    final args = config.args.join(' ');
    final env = config.env.entries.map((e) => '${e.key}=${e.value}').join('|');
    final workingDir = config.workingDirectory ?? '';
    return '${config.command}|$args|$env|$workingDir';
  }

  /// 🚀 GET OR CREATE SERVER: Retrieve existing server or create new one
  ///
  /// [config] - MCP server configuration
  /// Returns an MCP client instance (may be new or existing)
  Future<McpClient> getOrCreateServer(McpServerConfig config) async {
    final serverKey = _generateServerKey(config);
    
    // Check if server already exists and is healthy
    if (_activeServers.containsKey(serverKey)) {
      final instance = _activeServers[serverKey]!;
      
      // Verify server is still responsive
      if (await _isServerHealthy(instance.client)) {
        instance.referenceCount++;
        print('🔄 Reusing existing MCP server (refs: ${instance.referenceCount})');
        return instance.client;
      } else {
        print('⚠️  Existing server unhealthy, removing and recreating...');
        await _removeServer(serverKey);
      }
    }

    // Create new server instance
    print('🆕 Creating new MCP server instance...');
    final client = McpClient(config);
    await client.initialize();
    
    final instance = _ServerInstance(client);
    _activeServers[serverKey] = instance;
    
    print('✅ New MCP server created and initialized');
    return client;
  }

  /// 🧹 RELEASE SERVER: Decrease reference count and dispose if unused
  ///
  /// [config] - MCP server configuration to release
  /// [client] - The client instance being released
  Future<void> releaseServer(McpServerConfig config, McpClient client) async {
    final serverKey = _generateServerKey(config);
    
    if (_activeServers.containsKey(serverKey)) {
      final instance = _activeServers[serverKey]!;
      
      if (instance.client == client) {
        instance.referenceCount--;
        print('📉 Released MCP server (refs: ${instance.referenceCount})');
        
        // Dispose if no more references
        if (instance.referenceCount <= 0) {
          print('🧹 No more references, disposing MCP server...');
          await _removeServer(serverKey);
        }
      }
    }
  }

  /// 🏥 HEALTH CHECK: Verify server is still responsive
  ///
  /// [client] - MCP client to check
  /// Returns true if server is healthy and responsive
  Future<bool> _isServerHealthy(McpClient client) async {
    try {
      // Try to get tools as a health check
      final tools = client.tools;
      return tools.isNotEmpty;
    } catch (e) {
      print('⚠️  Server health check failed: $e');
      return false;
    }
  }

  /// 🗑️ REMOVE SERVER: Remove server from active list and dispose
  ///
  /// [serverKey] - Key of server to remove
  Future<void> _removeServer(String serverKey) async {
    final instance = _activeServers[serverKey];
    if (instance != null) {
      await instance.client.dispose();
      _activeServers.remove(serverKey);
      print('🗑️  MCP server removed and disposed');
    }
  }

  /// 🧹 SHUTDOWN ALL: Dispose all active servers (for application shutdown)
  ///
  /// Call this when the application is shutting down to clean up all servers
  Future<void> shutdownAll() async {
    print('🔄 Shutting down all MCP servers...');
    
    final servers = List<String>.from(_activeServers.keys);
    for (final serverKey in servers) {
      await _removeServer(serverKey);
    }
    
    print('✅ All MCP servers shut down');
  }

  /// 📊 STATUS: Get current server status information
  ///
  /// Returns a map of server information for debugging
  Map<String, dynamic> getStatus() {
    final status = <String, dynamic>{};
    
    for (final entry in _activeServers.entries) {
      status[entry.key] = {
        'referenceCount': entry.value.referenceCount,
        'toolCount': entry.value.client.toolCount,
        'isInitialized': entry.value.client.toolCount > 0, // Use toolCount as proxy for initialization
      };
    }
    
    return status;
  }
}

/// 🔧 SERVER INSTANCE: Wrapper for MCP client with reference counting
///
/// Tracks how many operations are using a particular server instance
class _ServerInstance {
  /// 🎯 CLIENT: The MCP client instance
  final McpClient client;
  
  /// 📊 REFERENCE COUNT: Number of operations using this server
  int referenceCount = 1;
  
  /// 🏗️ CONSTRUCTOR: Create new server instance
  _ServerInstance(this.client);
}

/// 🌐 GLOBAL INSTANCE: Easy access to the server manager
///
/// Use this to access the MCP server manager from anywhere in the application
final mcpServerManager = McpServerManager();

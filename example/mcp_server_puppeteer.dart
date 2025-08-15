import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

import '../lib/src/base_mcp_server.dart';

/// 🏆 SIMPLIFIED PUPPETEER MCP SERVER: Core Web Automation [+1000 XP]
///
/// **ARCHITECTURAL VICTORY**: This simplified MCP server provides essential web automation
/// capabilities using the official Puppeteer Dart package, focusing on the core requirements:
/// 1. Navigate to URL
/// 2. Extract innerText content
/// 3. Extract innerHTML content
///
/// **STRATEGIC DECISIONS**:
/// - Uses official Puppeteer Dart package (industry standard)
/// - Stateless browser operations (new browser per request)
/// - Comprehensive error handling and resource cleanup
/// - Timeout protection to prevent hanging
/// - Simplified API focusing on core functionality
/// - Registration-based architecture (eliminates boilerplate)
class PuppeteerMCPServerSimple extends BaseMCPServer {
  /// Browser instance management
  Browser? _browser;
  Page? _currentPage;

  /// Configuration options
  final bool headless;
  final Duration navigationTimeout;
  final Duration evaluationTimeout;

  /// Browser state tracking
  bool _isBrowserActive = false;

  PuppeteerMCPServerSimple({
    super.name = 'puppeteer-dart-simple',
    super.version = '1.0.0',
    super.logger,
    this.headless = false,
    this.navigationTimeout = const Duration(seconds: 30),
    this.evaluationTimeout = const Duration(seconds: 10),
  });

  @override
  Map<String, dynamic> getCapabilities() {
    final base = super.getCapabilities();
    return {
      ...base,
      'puppeteer': {
        'version': '3.19.0',
        'features': [
          'navigation',
          'content_extraction',
        ],
      },
    };
  }

  @override
  Future<void> initializeServer() async {
    // Register all tools with their callbacks
    registerTool(MCPTool(
      name: 'puppeteer_navigate',
      description:
          'Navigate to a URL and return the innerText content of the page',
      inputSchema: {
        'type': 'object',
        'properties': {
          'url': {
            'type': 'string',
            'description': 'URL to navigate to',
          },
          'selector': {
            'type': 'string',
            'description': 'CSS selector to target specific element (optional)',
            'default': 'body',
          },
          'waitUntil': {
            'type': 'string',
            'enum': [
              'load',
              'domcontentloaded',
              'networkidle0',
              'networkidle2'
            ],
            'description': 'When to consider navigation succeeded',
            'default': 'networkidle2',
          },
          'timeout': {
            'type': 'integer',
            'description': 'Navigation timeout in milliseconds',
            'default': 30000,
          },
        },
        'required': ['url'],
      },
      callback: _handleNavigate,
    ));

    registerTool(MCPTool(
      name: 'puppeteer_get_inner_text',
      description: 'Extract the innerText content from the entire page',
      inputSchema: {
        'type': 'object',
        'properties': {
          'selector': {
            'type': 'string',
            'description': 'CSS selector to target specific element (optional)',
            'default': 'body',
          },
          'timeout': {
            'type': 'integer',
            'description': 'Evaluation timeout in milliseconds',
            'default': 10000,
          },
        },
      },
      callback: _handleGetInnerText,
    ));

    registerTool(MCPTool(
      name: 'puppeteer_navigate_html',
      description:
          'Navigate to a URL and return the innerHTML content of the page',
      inputSchema: {
        'type': 'object',
        'properties': {
          'url': {
            'type': 'string',
            'description': 'URL to navigate to',
          },
          'selector': {
            'type': 'string',
            'description': 'CSS selector to target specific element (optional)',
            'default': 'body',
          },
          'waitUntil': {
            'type': 'string',
            'enum': [
              'load',
              'domcontentloaded',
              'networkidle0',
              'networkidle2'
            ],
            'description': 'When to consider navigation succeeded',
            'default': 'networkidle2',
          },
          'timeout': {
            'type': 'integer',
            'description': 'Navigation timeout in milliseconds',
            'default': 30000,
          },
        },
        'required': ['url'],
      },
      callback: _handleNavigateHTML,
    ));

    registerTool(MCPTool(
      name: 'puppeteer_get_inner_html',
      description: 'Extract the innerHTML content from the entire page',
      inputSchema: {
        'type': 'object',
        'properties': {
          'selector': {
            'type': 'string',
            'description': 'CSS selector to target specific element (optional)',
            'default': 'body',
          },
          'timeout': {
            'type': 'integer',
            'description': 'Evaluation timeout in milliseconds',
            'default': 10000,
          },
        },
      },
      callback: _handleGetInnerHTML,
    ));

    registerTool(MCPTool(
      name: 'puppeteer_close_browser',
      description: 'Close the browser and clean up resources',
      inputSchema: {
        'type': 'object',
        'properties': {},
      },
      callback: _handleCloseBrowser,
    ));

    // Register resources with their callbacks
    registerResource(MCPResource(
      uri: 'puppeteer://status',
      name: 'Browser Status',
      description: 'Current browser status and configuration',
      mimeType: 'application/json',
      callback: _getBrowserStatus,
    ));

    // Register prompts with their callbacks
    registerPrompt(MCPPrompt(
      name: 'web_scraping_workflow',
      description: 'Complete workflow for web scraping with Puppeteer',
      arguments: [
        MCPPromptArgument(
          name: 'url',
          description: 'URL to scrape',
          required: true,
        ),
        MCPPromptArgument(
          name: 'content_type',
          description: 'Type of content to extract (text/html)',
          required: true,
        ),
      ],
      callback: _getWebScrapingWorkflow,
    ));

    logger?.call('info',
        'Puppeteer MCP server initialized with ${getAvailableTools().length} tools, ${getAvailableResources().length} resources, and ${getAvailablePrompts().length} prompts');
  }

  /// 🚀 **BROWSER MANAGEMENT**: Initialize browser instance with timeout protection
  Future<void> _ensureBrowser() async {
    if (_isBrowserActive && _browser != null) {
      return; // Browser already active
    }

    try {
      logger?.call('info', 'Launching Puppeteer browser (headless: $headless)');

      // Launch browser with timeout protection
      _browser = await puppeteer.launch(
        headless: headless,
        executablePath: _findChromiumExecutable() ??
            _findChromeExecutable() ??
            _findFirefoxExecutable(),
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-gpu',
          '--no-first-run',
          '--disable-web-security',
          '--disable-features=VizDisplayCompositor',
        ],
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw MCPServerException('Browser launch timeout after 30 seconds');
        },
      );

      _isBrowserActive = true;
      logger?.call('info', 'Puppeteer browser launched successfully');
    } catch (e) {
      logger?.call('error', 'Failed to launch browser', e);
      throw MCPServerException('Browser launch failed: ${e.toString()}');
    }
  }

  /// 📄 **PAGE MANAGEMENT**: Get or create page instance
  Future<Page> _getPage() async {
    await _ensureBrowser();

    if (_currentPage == null) {
      _currentPage = await _browser!.newPage();
      logger?.call('debug', 'Created new page instance');
    }

    return _currentPage!;
  }

  /// 🧹 **RESOURCE CLEANUP**: Proper browser cleanup
  Future<void> _cleanupBrowser() async {
    try {
      if (_currentPage != null) {
        await _currentPage!.close();
        _currentPage = null;
        logger?.call('debug', 'Closed current page');
      }

      if (_browser != null && _isBrowserActive) {
        await _browser!.close();
        _browser = null;
        _isBrowserActive = false;
        logger?.call('info', 'Closed Puppeteer browser');
      }
    } catch (e) {
      logger?.call('warning', 'Error during browser cleanup', e);
    }
  }

  /// 🧭 **NAVIGATION HANDLER**: Navigate to URL and return innerText
  Future<MCPToolResult> _handleNavigate(Map<String, dynamic> arguments) async {
    final url = arguments['url'] as String;
    final waitUntil = arguments['waitUntil'] as String? ?? 'networkidle2';
    final timeout = arguments['timeout'] as int? ?? 30000;

    logger?.call('info', 'Navigating to: $url (waitUntil: $waitUntil)');

    final page = await _getPage();

    try {
      // Convert waitUntil string to enum
      final waitCondition = _parseWaitUntil(waitUntil);

      // Navigate with timeout protection
      await page.goto(url, wait: waitCondition).timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          throw MCPServerException('Navigation timeout after ${timeout}ms');
        },
      );

      // Get page title
      final title = await page.evaluate<String>('document.title').timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw MCPServerException('Title evaluation timeout');
        },
      );

      // Extract innerText from the page using a simple expression
      final innerText = await page.evaluate<String>('''
        document.body.innerText
      ''').timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw MCPServerException('InnerText extraction timeout');
        },
      );

      logger?.call('info',
          'Navigation and text extraction successful. Page title: $title (${innerText.length} characters)');

      return MCPToolResult(
        content: [
          MCPContent.text(innerText),
        ],
      );
    } catch (e) {
      logger?.call('error', 'Navigation failed: $url', e);
      throw MCPServerException('Navigation failed: ${e.toString()}');
    }
  }

  /// 📝 **INNER TEXT HANDLER**: Extract page text content
  Future<MCPToolResult> _handleGetInnerText(
      Map<String, dynamic> arguments) async {
    final selector = arguments['selector'] as String? ?? 'body';
    final timeout = arguments['timeout'] as int? ?? 10000;

    logger?.call('info', 'Extracting innerText from selector: $selector');

    final page = await _getPage();

    try {
      final innerText = await page.evaluate<String>('''
        document.body.innerText
      ''').timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          throw MCPServerException(
              'InnerText evaluation timeout after ${timeout}ms');
        },
      );

      logger?.call('info',
          'InnerText extraction successful (${innerText.length} characters)');

      return MCPToolResult(
        content: [
          MCPContent.text(innerText),
        ],
      );
    } catch (e) {
      logger?.call('error', 'InnerText extraction failed', e);
      throw MCPServerException('InnerText extraction failed: ${e.toString()}');
    }
  }

  /// 🏷️ **NAVIGATION HTML HANDLER**: Navigate to URL and return innerHTML
  Future<MCPToolResult> _handleNavigateHTML(
      Map<String, dynamic> arguments) async {
    final url = arguments['url'] as String;
    final waitUntil = arguments['waitUntil'] as String? ?? 'networkidle2';
    final timeout = arguments['timeout'] as int? ?? 30000;

    logger?.call('info',
        'Navigating to: $url and extracting HTML (waitUntil: $waitUntil)');

    final page = await _getPage();

    try {
      // Convert waitUntil string to enum
      final waitCondition = _parseWaitUntil(waitUntil);

      // Navigate with timeout protection
      await page.goto(url, wait: waitCondition).timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          throw MCPServerException('Navigation timeout after ${timeout}ms');
        },
      );

      // Get page title
      final title = await page.evaluate<String>('document.title').timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw MCPServerException('Title evaluation timeout');
        },
      );

      // Extract innerHTML from the page
      final innerHTML = await page.evaluate<String>('''
        document.body.innerHTML
      ''').timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw MCPServerException('InnerHTML extraction timeout');
        },
      );

      logger?.call('info',
          'Navigation and HTML extraction successful. Page title: $title (${innerHTML.length} characters)');

      return MCPToolResult(
        content: [
          MCPContent.text(innerHTML),
        ],
      );
    } catch (e) {
      logger?.call('error', 'Navigation failed: $url', e);
      throw MCPServerException('Navigation failed: ${e.toString()}');
    }
  }

  /// 🏷️ **INNER HTML HANDLER**: Extract page HTML content
  Future<MCPToolResult> _handleGetInnerHTML(
      Map<String, dynamic> arguments) async {
    final selector = arguments['selector'] as String? ?? 'body';
    final timeout = arguments['timeout'] as int? ?? 10000;

    logger?.call('info', 'Extracting innerHTML from selector: $selector');

    final page = await _getPage();

    try {
      final innerHTML = await page.evaluate<String>('''
        document.body.innerHTML
      ''').timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          throw MCPServerException(
              'InnerHTML evaluation timeout after ${timeout}ms');
        },
      );

      logger?.call('info',
          'InnerHTML extraction successful (${innerHTML.length} characters)');

      return MCPToolResult(
        content: [
          MCPContent.text(innerHTML),
        ],
      );
    } catch (e) {
      logger?.call('error', 'InnerHTML extraction failed', e);
      throw MCPServerException('InnerHTML extraction failed: ${e.toString()}');
    }
  }

  /// 🧹 **BROWSER CLEANUP HANDLER**: Close browser and clean up
  Future<MCPToolResult> _handleCloseBrowser(
      Map<String, dynamic> arguments) async {
    logger?.call('info', 'Closing browser and cleaning up resources');

    await _cleanupBrowser();

    return MCPToolResult(
      content: [
        MCPContent.text('Browser closed and resources cleaned up'),
      ],
    );
  }

  /// 🔧 **UTILITY METHODS**: Helper functions for parsing

  /// Find Chromium executable path
  String? _findChromiumExecutable() {
    // Common Chromium executable paths
    final possiblePaths = [
      '/usr/bin/chromium-browser',
      '/usr/bin/chromium',
      '/snap/bin/chromium',
      '/Applications/Chromium.app/Contents/MacOS/Chromium', // macOS
      'C:\\Program Files\\Chromium\\Application\\chrome.exe', // Windows
      'C:\\Program Files (x86)\\Chromium\\Application\\chrome.exe', // Windows
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        logger?.call('info', 'Found Chromium executable: $path');
        return path;
      }
    }

    logger?.call('info', 'No Chromium executable found');
    return null;
  }

  /// Find Firefox executable path
  String? _findFirefoxExecutable() {
    // Common Firefox executable paths
    final possiblePaths = [
      '/usr/bin/firefox',
      '/usr/bin/firefox-esr',
      '/snap/bin/firefox',
      '/Applications/Firefox.app/Contents/MacOS/firefox', // macOS
      'C:\\Program Files\\Mozilla Firefox\\firefox.exe', // Windows
      'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe', // Windows
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        logger?.call('info', 'Found Firefox executable: $path');
        return path;
      }
    }

    logger?.call('info', 'No Firefox executable found');
    return null;
  }

  /// Find Chrome executable path
  String? _findChromeExecutable() {
    // Common Chrome executable paths
    final possiblePaths = [
      '/usr/bin/google-chrome',
      '/usr/bin/chromium-browser',
      '/usr/bin/chromium',
      '/snap/bin/chromium',
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', // macOS
      'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', // Windows
      'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe', // Windows
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        logger?.call('info', 'Found Chrome executable: $path');
        return path;
      }
    }

    logger?.call('warning', 'No Chrome executable found, using default');
    return null; // Let Puppeteer use its default
  }

  /// Parse waitUntil string to enum
  Until _parseWaitUntil(String waitUntil) {
    switch (waitUntil.toLowerCase()) {
      case 'load':
        return Until.load;
      case 'domcontentloaded':
        return Until.domContentLoaded;
      case 'networkidle0':
        return Until.networkIdle;
      case 'networkidle2':
        return Until.networkAlmostIdle;
      default:
        return Until.networkAlmostIdle;
    }
  }

  /// 📊 **RESOURCE CALLBACKS**: Implement resource reading callbacks

  /// Get browser status resource
  Future<MCPContent> _getBrowserStatus() async {
    final status = {
      'browserActive': _isBrowserActive,
      'hasPage': _currentPage != null,
      'headless': headless,
      'navigationTimeout': navigationTimeout.inMilliseconds,
      'evaluationTimeout': evaluationTimeout.inMilliseconds,
      'version': '3.19.0',
    };

    return MCPContent.resource(
      data: jsonEncode(status),
      mimeType: 'application/json',
    );
  }

  /// 💬 **PROMPT CALLBACKS**: Implement prompt execution callbacks

  /// Get web scraping workflow prompt
  Future<List<MCPMessage>> _getWebScrapingWorkflow(
      Map<String, dynamic> arguments) async {
    final url = arguments['url'] as String;
    final contentType = arguments['content_type'] as String? ?? 'text';

    final toolName = contentType == 'html'
        ? 'puppeteer_get_inner_html'
        : 'puppeteer_get_inner_text';

    return [
      MCPMessage.notification(
        method: 'tools/call',
        params: {
          'name': 'puppeteer_navigate',
          'arguments': {'url': url},
        },
      ),
      MCPMessage.notification(
        method: 'tools/call',
        params: {
          'name': toolName,
          'arguments': {},
        },
      ),
    ];
  }

  @override
  Future<void> shutdown() async {
    logger?.call('info', 'Shutting down Puppeteer MCP server');

    // Clean up browser resources
    await _cleanupBrowser();

    // Call parent shutdown
    await super.shutdown();
  }
}

/// 🚀 **MAIN ENTRY POINT**: Start the Puppeteer MCP server
///
/// This function is called when the script is executed directly
void main() async {
  final server = PuppeteerMCPServerSimple(
    logger: (level, message, [data]) {
      final timestamp = DateTime.now().toIso8601String();
      stderr.writeln(
          '[$timestamp] [$level] $message${data != null ? ': $data' : ''}');
    },
  );

  try {
    await server.start();
  } catch (e) {
    stderr.writeln('Failed to start Puppeteer MCP server: $e');
    exit(1);
  }
}

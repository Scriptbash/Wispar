import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../widgets/publication_card.dart';
import '../generated_l10n/app_localizations.dart';
import '../services/logs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String pdfPath;
  final PublicationCard publicationCard;

  const ChatScreen({
    Key? key,
    required this.pdfPath,
    required this.publicationCard,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoadingResponse = false;
  String? _base64Pdf;
  final logger = LogsService().logger;

  bool _didInitDependencies = false;

  List<Map<String, dynamic>> _conversationHistory = [];

  String _selectedAiProvider = '';
  List<String> _availableProviders = [];

  String _geminiApiKey = '';
  String _chatgptApiKey = '';
  // DeepSeek is not available yet
  String _deepseekApiKey = '';

  String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';
  String _chatgptBaseUrl = 'https://api.openai.com/v1/responses/';
  String _deepseekBaseUrl = 'https://api.deepseek.com/v1/chat/responses';

  String _geminiModelName = 'gemini-2.5-flash';
  String _chatgptModelName = 'gpt-4o';
  String _deepseekModelName = 'deepseek-chat';

  bool _useCustomGeminiBaseUrl = false;
  bool _useCustomChatgptBaseUrl = false;
  bool _useCustomDeepseekBaseUrl = false;

  @override
  void initState() {
    super.initState();
    _loadAndEncodePdf();
    _loadAiSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitDependencies) {
      _didInitDependencies = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAiSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final String loadedGeminiKey = prefs.getString('gemini_api_key') ?? '';
    final String loadedChatgptKey = prefs.getString('chatgpt_api_key') ?? '';
    final String loadedDeepseekKey = prefs.getString('deepseek_api_key') ?? '';

    final String loadedGeminiBaseUrl =
        prefs.getString('gemini_base_url') ?? _geminiBaseUrl;
    final String loadedChatgptBaseUrl =
        prefs.getString('chatgpt_base_url') ?? _chatgptBaseUrl;
    final String loadedDeepseekBaseUrl =
        prefs.getString('deepseek_base_url') ?? _deepseekBaseUrl;

    final String loadedGeminiModelName =
        prefs.getString('gemini_model_name') ?? _geminiModelName;
    final String loadedChatgptModelName =
        prefs.getString('chatgpt_model_name') ?? _chatgptModelName;
    final String loadedDeepseekModelName =
        prefs.getString('deepseek_model_name') ?? _deepseekModelName;

    final bool loadedUseCustomGeminiBaseUrl =
        prefs.getBool('use_custom_gemini_base_url') ?? false;
    final bool loadedUseCustomChatgptBaseUrl =
        prefs.getBool('use_custom_chatgpt_base_url') ?? false;
    final bool loadedUseCustomDeepseekBaseUrl =
        prefs.getBool('use_custom_deepseek_base_url') ?? false;

    List<String> currentAvailableProviders = [];
    if (loadedGeminiKey.isNotEmpty) {
      currentAvailableProviders.add('Gemini');
    }
    // if (loadedDeepseekKey.isNotEmpty) {
    //   currentAvailableProviders.add('DeepSeek');
    // }
    if (loadedChatgptKey.isNotEmpty) {
      currentAvailableProviders.add('ChatGPT');
    }

    String? savedSelectedProvider = prefs.getString('ai_provider');
    String initialSelectedProvider;

    if (savedSelectedProvider != null &&
        currentAvailableProviders.contains(savedSelectedProvider)) {
      initialSelectedProvider = savedSelectedProvider;
    } else if (currentAvailableProviders.isNotEmpty) {
      initialSelectedProvider = currentAvailableProviders.first;
    } else {
      initialSelectedProvider = '';
    }

    setState(() {
      _geminiApiKey = loadedGeminiKey;
      _chatgptApiKey = loadedChatgptKey;
      _deepseekApiKey = loadedDeepseekKey;

      _geminiBaseUrl = loadedGeminiBaseUrl;
      _chatgptBaseUrl = loadedChatgptBaseUrl;
      _deepseekBaseUrl = loadedDeepseekBaseUrl;

      _geminiModelName = loadedGeminiModelName;
      _chatgptModelName = loadedChatgptModelName;
      _deepseekModelName = loadedDeepseekModelName;

      _useCustomGeminiBaseUrl = loadedUseCustomGeminiBaseUrl;
      _useCustomChatgptBaseUrl = loadedUseCustomChatgptBaseUrl;
      _useCustomDeepseekBaseUrl = loadedUseCustomDeepseekBaseUrl;

      _availableProviders = currentAvailableProviders;
      _selectedAiProvider = initialSelectedProvider;

      if (_availableProviders.isEmpty) {
        _addMessage('ai', AppLocalizations.of(context)!.noAiApiKeySetError);
      } else if (_messages.isEmpty) {
        _addMessage('ai', AppLocalizations.of(context)!.askAboutPdf);
      }
    });
  }

  Future<void> _loadAndEncodePdf() async {
    try {
      final file = File(widget.pdfPath);
      if (await file.exists()) {
        List<int> bytes = await file.readAsBytes();
        setState(() {
          _base64Pdf = base64Encode(bytes);
        });
        logger.info('PDF loaded and base64 encoded successfully.');
      } else {
        logger.severe('PDF file not found at: ${widget.pdfPath}');
        _showErrorSnackBar(AppLocalizations.of(context)!.pdfNotFound);
      }
    } catch (e, st) {
      logger.severe('Error loading or encoding PDF: $e', e, st);
      _showErrorSnackBar(AppLocalizations.of(context)!.errorLoadingPdf);
    }
  }

  void _addMessage(String type, String content) {
    setState(() {
      _messages.add({'type': type, 'content': content});
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoadingResponse) {
      return;
    }

    if (_selectedAiProvider.isEmpty) {
      _addMessage('ai', AppLocalizations.of(context)!.noAiApiKeySetError);
      return;
    }

    final userMessage = _messageController.text;
    _addMessage('user', userMessage);
    _messageController.clear();

    setState(() {
      _isLoadingResponse = true;
    });

    try {
      String? apiKey;
      String? apiUrl;
      String? modelName;

      if (_selectedAiProvider == "Gemini") {
        apiKey = _geminiApiKey;
        modelName = _geminiModelName;
        apiUrl = _useCustomGeminiBaseUrl
            ? '${_geminiBaseUrl}${modelName}:generateContent?key=$apiKey'
            : 'https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=$apiKey';
      } else if (_selectedAiProvider == "ChatGPT") {
        apiKey = _chatgptApiKey;
        modelName = _chatgptModelName;
        apiUrl = _useCustomChatgptBaseUrl
            ? _chatgptBaseUrl
            : 'https://api.openai.com/v1/responses';
      } else {
        logger.warning(
            'Selected AI provider $_selectedAiProvider is not supported for PDF chat or has no API key.');
        return;
      }

      if (apiKey.isEmpty) {
        _addMessage('ai',
            AppLocalizations.of(context)!.apiTokenMissing(_selectedAiProvider));
        return;
      }

      dynamic body;

      if (_selectedAiProvider == "Gemini") {
        // Include PDF in the first request
        if (_conversationHistory.isEmpty && _base64Pdf != null) {
          body = jsonEncode({
            "contents": [
              {
                "parts": [
                  {
                    "inline_data": {
                      "mime_type": "application/pdf",
                      "data": _base64Pdf
                    }
                  },
                  {"text": userMessage}
                ]
              }
            ]
          });
        } else {
          // Only send the user message, without the PDF
          body = jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": userMessage}
                ]
              }
            ]
          });
        }
      } else if (_selectedAiProvider == "ChatGPT") {
        if (_conversationHistory.isEmpty && _base64Pdf != null) {
          body = jsonEncode({
            "model": modelName,
            "input": [
              {
                "role": "user",
                "content": [
                  {
                    "type": "input_file",
                    "filename": p.basename(widget.pdfPath),
                    "file_data": "data:application/pdf;base64,$_base64Pdf"
                  },
                  {"type": "input_text", "text": userMessage}
                ]
              }
            ]
          });
        } else {
          body = jsonEncode({
            "model": modelName,
            "input": [
              {
                "role": "user",
                "content": [
                  {"type": "input_text", "text": userMessage}
                ]
              }
            ]
          });
        }
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (_selectedAiProvider == "ChatGPT")
            'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        String aiResponseText = '';

        if (_selectedAiProvider == "Gemini") {
          aiResponseText = jsonResponse['candidates']?[0]?['content']?['parts']
                  ?[0]?['text'] ??
              AppLocalizations.of(context)!.noResponseFromAI;
        } else {
          aiResponseText = jsonResponse['output']?[0]?['content']?[0]
                  ?['text'] ??
              AppLocalizations.of(context)!.noResponseFromAI;

          _conversationHistory.add({
            "role": "assistant",
            "content": [
              {"type": "output_text", "text": aiResponseText}
            ]
          });
        }

        _addMessage('ai', aiResponseText);
      } else {
        logger.severe(
            'AI API call failed: ${response.statusCode} - ${response.body}');
        _addMessage(
            'ai',
            AppLocalizations.of(context)!
                .errorConnectingToAI(response.statusCode));
      }
    } catch (e, st) {
      logger.severe('Network or AI processing error: $e', e, st);
      _addMessage('ai', AppLocalizations.of(context)!.networkError);
    } finally {
      setState(() {
        _isLoadingResponse = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _availableProviders.isNotEmpty
            ? Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAiProvider.isNotEmpty
                          ? _selectedAiProvider
                          : null,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                      ),
                      items: _availableProviders.map((String provider) {
                        return DropdownMenuItem<String>(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAiProvider = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              )
            : null,
        actions: [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['type'] == 'user';

                  final bubbleColor = isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.tertiaryContainer;

                  final textColor = isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onTertiaryContainer;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: SelectionArea(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: isUser
                            ? Text(
                                message['content']!,
                                style: TextStyle(color: textColor),
                              )
                            : MarkdownBody(
                                data: message['content']!,
                                selectable: false,
                                shrinkWrap: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(color: textColor),
                                  code: TextStyle(color: textColor),
                                  blockquote: TextStyle(color: textColor),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoadingResponse)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
            if (_availableProviders.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.noAiApiKeySetError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: MediaQuery.of(context)
                  .viewInsets
                  .add(const EdgeInsets.all(8.0)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeYourMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled:
                          !_isLoadingResponse && _availableProviders.isNotEmpty,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).colorScheme.primary,
                    disabledColor: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

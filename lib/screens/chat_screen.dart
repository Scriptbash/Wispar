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
  final logger = LogsService().logger;

  String? _chatgptFileId;
  String? _geminiFileUri;

  bool _didInitDependencies = false;
  bool _isUploadingFile = false;

  List<Map<String, dynamic>> _conversationHistory = [];

  final ScrollController _scrollController = ScrollController();

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
  String _chatgptModelName = 'gpt-4.1-mini';
  String _deepseekModelName = 'deepseek-chat';

  bool _useCustomGeminiBaseUrl = false;
  bool _useCustomChatgptBaseUrl = false;
  bool _useCustomDeepseekBaseUrl = false;

  @override
  void initState() {
    super.initState();
    _loadAiSettings().then((_) {
      if (_selectedAiProvider == "ChatGPT" && _chatgptApiKey.isNotEmpty) {
        setState(() => _isUploadingFile = true);
        _uploadPdfToChatGPT().then((fileId) {
          if (fileId != null) {
            setState(() {
              _chatgptFileId = fileId;
              _isUploadingFile = false;
            });
          }
        });
      } else if (_selectedAiProvider == "Gemini" && _geminiApiKey.isNotEmpty) {
        setState(() => _isUploadingFile = true);
        _uploadPdfToGemini().then((uri) {
          if (uri != null) {
            setState(() {
              _geminiFileUri = uri;
              _isUploadingFile = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (_selectedAiProvider == "ChatGPT") {
      _deleteChatGptFile();
    } else if (_selectedAiProvider == "Gemini") {
      _deleteGeminiFile();
    }
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitDependencies) {
      _didInitDependencies = true;
    }
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

  Future<String?> _uploadPdfToGemini() async {
    try {
      final file = File(widget.pdfPath);
      if (!await file.exists()) {
        logger.severe('PDF file not found at: ${widget.pdfPath}');
        _showErrorSnackBar(AppLocalizations.of(context)!.pdfNotFound);
        return null;
      }

      final bytes = await file.readAsBytes();
      final numBytes = bytes.length;

      final startRes = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/upload/v1beta/files"),
        headers: {
          "x-goog-api-key": _geminiApiKey,
          "X-Goog-Upload-Protocol": "resumable",
          "X-Goog-Upload-Command": "start",
          "X-Goog-Upload-Header-Content-Length": "$numBytes",
          "X-Goog-Upload-Header-Content-Type": "application/pdf",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "file": {"display_name": p.basename(widget.pdfPath)}
        }),
      );

      if (startRes.statusCode != 200) {
        logger.severe(
            "Gemini upload init failed: ${startRes.statusCode} - ${startRes.body}");
        _addMessage(
            'ai',
            AppLocalizations.of(context)!
                .errorConnectingToAI(startRes.statusCode));
        return null;
      }

      final uploadUrl = startRes.headers["x-goog-upload-url"];
      if (uploadUrl == null) {
        logger.severe("Gemini upload URL missing in response headers");
        _addMessage('ai', AppLocalizations.of(context)!.errorOccured);
        return null;
      }

      final uploadRes = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          "x-goog-api-key": _geminiApiKey,
          "X-Goog-Upload-Command": "upload, finalize",
          "X-Goog-Upload-Offset": "0",
          "Content-Length": "$numBytes",
        },
        body: bytes,
      );

      if (uploadRes.statusCode == 200) {
        final jsonResponse = jsonDecode(uploadRes.body);
        final fileUri = jsonResponse['file']?['uri'];
        logger.info("Gemini PDF uploaded: $fileUri");
        return fileUri;
      } else {
        logger.severe(
            "Gemini file upload failed: ${uploadRes.statusCode} - ${uploadRes.body}");
        _addMessage('ai', AppLocalizations.of(context)!.errorOccured);
        return null;
      }
    } catch (e, st) {
      logger.severe("Error uploading PDF to Gemini: $e", e, st);
      return null;
    }
  }

  Future<String?> _uploadPdfToChatGPT() async {
    try {
      final file = File(widget.pdfPath);
      if (!await file.exists()) {
        logger.severe('PDF file not found at: ${widget.pdfPath}');
        _showErrorSnackBar(AppLocalizations.of(context)!.pdfNotFound);
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/files'),
      )
        ..headers['Authorization'] = 'Bearer $_chatgptApiKey'
        ..fields['purpose'] = 'user_data'
        ..files.add(await http.MultipartFile.fromPath('file', widget.pdfPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final fileId = jsonResponse['id'];
        logger.info('PDF uploaded successfully, file_id: $fileId');
        return fileId;
      } else {
        logger.severe(
            'File upload failed: ${response.statusCode} - ${response.body}');
        _addMessage(
            'ai',
            AppLocalizations.of(context)!
                .errorConnectingToAI(response.statusCode));

        return null;
      }
    } catch (e, st) {
      logger.severe('Error uploading PDF: $e', e, st);
      _addMessage('ai', AppLocalizations.of(context)!.errorOccured);
      return null;
    }
  }

  Future<void> _deleteGeminiFile() async {
    if (_geminiFileUri == null) return;

    try {
      final fileName = _geminiFileUri!.split('/').last;

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/files/$fileName',
      );

      final res = await http.delete(
        uri,
        headers: {"x-goog-api-key": _geminiApiKey},
      );

      if (res.statusCode == 200) {
        logger.info("Deleted Gemini file: $fileName");
      } else {
        logger.warning(
            "Failed to delete Gemini file $fileName: ${res.statusCode} - ${res.body}");
      }
    } catch (e, st) {
      logger.severe("Error deleting Gemini file: $e", e, st);
    }
  }

  Future<void> _deleteChatGptFile() async {
    if (_chatgptFileId == null) return;

    try {
      final response = await http.delete(
        Uri.parse('https://api.openai.com/v1/files/$_chatgptFileId'),
        headers: {'Authorization': 'Bearer $_chatgptApiKey'},
      );

      if (response.statusCode == 200) {
        logger.info('Deleted ChatGPT file: $_chatgptFileId');
      } else {
        logger.warning(
          'Failed to delete ChatGPT file $_chatgptFileId: '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, st) {
      logger.severe('Error deleting ChatGPT file: $e', e, st);
    }
  }

  void _addMessage(String type, String content) {
    setState(() {
      _messages.add({'type': type, 'content': content});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
        final contentParts = <Map<String, dynamic>>[
          {"text": userMessage}
        ];

        if (_geminiFileUri != null) {
          contentParts.add({
            "file_data": {
              "mime_type": "application/pdf",
              "file_uri": _geminiFileUri,
            }
          });
        }

        _conversationHistory.add({
          "role": "user",
          "content": contentParts,
        });

        body = jsonEncode({
          "contents": _conversationHistory.map((msg) {
            return {
              "role": msg['role'],
              "parts": msg['content'],
            };
          }).toList()
        });
      } else if (_selectedAiProvider == "ChatGPT") {
        if (_conversationHistory.isEmpty && _chatgptFileId != null) {
          _conversationHistory.add({
            "role": "user",
            "content": [
              {"type": "input_text", "text": userMessage},
              {"type": "input_file", "file_id": _chatgptFileId},
            ],
          });
        } else {
          _conversationHistory.add({
            "role": "user",
            "content": [
              {"type": "input_text", "text": userMessage},
            ],
          });
        }

        body = jsonEncode({
          "model": modelName,
          "input": _conversationHistory,
        });
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

          _conversationHistory.add({
            "role": "model",
            "content": [
              {"text": aiResponseText}
            ]
          });
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
                        onChanged: (String? newValue) async {
                          if (newValue != null &&
                              newValue != _selectedAiProvider) {
                            setState(() => _selectedAiProvider = newValue);
                            setState(() => _isUploadingFile = true);

                            if (newValue == "ChatGPT" &&
                                _chatgptApiKey.isNotEmpty) {
                              final fileId = await _uploadPdfToChatGPT();
                              if (_geminiFileUri != null &&
                                  _geminiFileUri!.isNotEmpty) {
                                _deleteGeminiFile();
                                _geminiFileUri = null;
                              }
                              setState(() => _chatgptFileId = fileId);
                            } else if (newValue == "Gemini" &&
                                _geminiApiKey.isNotEmpty) {
                              final uri = await _uploadPdfToGemini();
                              if (_chatgptFileId != null &&
                                  _chatgptFileId!.isNotEmpty) {
                                _deleteChatGptFile();
                                _chatgptFileId = null;
                              }
                              setState(() => _geminiFileUri = uri);
                            }

                            setState(() {
                              _conversationHistory.clear();
                              _isUploadingFile = false;
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
                  controller: _scrollController,
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
              if (_isUploadingFile || _isLoadingResponse)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.typeYourMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoadingResponse &&
                            !_isUploadingFile &&
                            _availableProviders.isNotEmpty,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: (!_isLoadingResponse &&
                              !_isUploadingFile &&
                              _availableProviders.isNotEmpty)
                          ? _sendMessage
                          : null,
                      color: Theme.of(context).colorScheme.primary,
                      disabledColor: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

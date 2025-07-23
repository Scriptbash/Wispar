import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/logs_helper.dart';

class ChatgptTranslationProvider {
  String? _apiKey;
  final _logger = LogsService().logger;

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  ChatgptTranslationProvider._privateConstructor();

  static final ChatgptTranslationProvider _instance =
      ChatgptTranslationProvider._privateConstructor();

  static ChatgptTranslationProvider get instance {
    if (_instance._apiKey == null) {
      _instance._loadApiKeyOnDemand();
    }
    return _instance;
  }

  Future<void> _loadApiKeyOnDemand() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('chatgpt_api_key');
  }

  void setApiKey(String? newKey) async {
    _apiKey = newKey;
    final prefs = await SharedPreferences.getInstance();
    if (newKey != null && newKey.isNotEmpty) {
      await prefs.setString('chatgpt_api_key', newKey);
    } else {
      await prefs.remove('chatgpt_api_key');
    }
  }

  Future<Stream<String>> translateStream({
    required String text,
    required String sourceLangName,
    required String targetLangName,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.warning('ChatGPT API key is not set. Cannot translate.');
      throw Exception('ChatGPT API key is not set.');
    }

    final controller = StreamController<String>();
    final prompt =
        'Translate the following text from $sourceLangName to $targetLangName. Do not enclosed the translation with quotes or other extra punctuation. Respond only with the translated text, no conversational filler:\n\n"$text"';

    //_logger.info(
    //    'ChatGPT Translation Request: Prompt Length=${prompt.length}, Text length=${text.length}');

    try {
      final uri = Uri.parse(_baseUrl);
      //_logger.info('ChatGPT API Request URL: $uri');

      final requestBody = jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": "You are a highly accurate translation assistant."
          },
          {"role": "user", "content": prompt}
        ],
        "stream": true,
        "temperature": 0.7,
        //"max_tokens": 2000,
      });

      final client = http.Client();
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..body = requestBody;

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        _logger.info(
            'ChatGPT API Stream Response: Status 200 OK. Starting to listen to stream for SSE data.');
        streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            //_logger.fine('ChatGPT Stream Raw Line: "$line"');
            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6);
              if (jsonString.trim() == '[DONE]') {
                //_logger.info('ChatGPT Stream: [DONE] received.');
                return;
              }
              try {
                final Map<String, dynamic> data = jsonDecode(jsonString);
                //_logger.fine('ChatGPT Stream JSON Data: $data');

                String translatedChunk = '';
                if (data.containsKey('choices') &&
                    data['choices'] is List &&
                    data['choices'].isNotEmpty) {
                  final choice = data['choices'][0];
                  if (choice.containsKey('delta') &&
                      choice['delta'].containsKey('content')) {
                    translatedChunk = choice['delta']['content'].toString();
                  }
                }

                if (translatedChunk.isNotEmpty) {
                  controller.add(translatedChunk);
                  //_logger.info(
                  //    'ChatGPT Stream: Added chunk to controller: "$translatedChunk"');
                } else {
                  _logger.warning(
                      'ChatGPT Stream: Received empty chunk or no text in delta for line: "$line"');
                }
              } catch (e, stackTrace) {
                _logger.severe(
                    'Error parsing ChatGPT stream JSON line: $e\nLine: "$line"',
                    e,
                    stackTrace);
              }
            } else if (line.isNotEmpty) {
              _logger.fine(
                  'ChatGPT Stream: Non-data line received or malformed SSE: "$line"');
            }
          },
          onDone: () {
            controller.close();
            client.close();
            _logger.info(
                'ChatGPT Stream: All data received, controller and client closed.');
          },
          onError: (error, stackTrace) {
            _logger.severe(
                'ChatGPT translation stream error', error, stackTrace);
            controller.addError(error);
            controller.close();
            client.close();
          },
        );
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        _logger.severe(
            'ChatGPT API Error: ${streamedResponse.statusCode} - $responseBody');
        throw Exception(
            'Failed to translate with ChatGPT: ${streamedResponse.statusCode} - $responseBody');
      }
    } catch (e, stackTrace) {
      _logger.severe(
          'Error initiating ChatGPT translation stream', e, stackTrace);
      controller.addError(e);
      controller.close();
      rethrow;
    }
    return controller.stream;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/logs_helper.dart';

class DeepSeekTranslationProvider {
  String? _apiKey;
  final _logger = LogsService().logger;

  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';

  DeepSeekTranslationProvider._privateConstructor();

  static final DeepSeekTranslationProvider _instance =
      DeepSeekTranslationProvider._privateConstructor();

  static DeepSeekTranslationProvider get instance {
    if (_instance._apiKey == null) {
      _instance._loadApiKey();
    }
    return _instance;
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('deepseek_api_key');
  }

  void setApiKey(String? newKey) async {
    _apiKey = newKey;
    final prefs = await SharedPreferences.getInstance();
    if (newKey != null && newKey.isNotEmpty) {
      await prefs.setString('deepseek_api_key', newKey);
    } else {
      await prefs.remove('deepseek_api_key');
    }
  }

  Future<Stream<String>> translateStream({
    required String text,
    required String sourceLangName,
    required String targetLangName,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.warning('DeepSeek API key is not set. Cannot translate.');
      throw Exception('DeepSeek API key is not set.');
    }

    final controller = StreamController<String>();

    final prompt =
        'Translate the following text from $sourceLangName to $targetLangName. Do not enclosed the translation with quotes or other extra punctuation. Respond only with the translated text, no conversational filler:\n\n"$text"';

    // _logger.info(
    //     'DeepSeek Translation Request: Prompt Length=${prompt.length}, Text length=${text.length}');

    try {
      final uri = Uri.parse(_baseUrl);
      //_logger.info('DeepSeek API Request URL: $uri');

      final requestBody = jsonEncode({
        "messages": [
          {
            "role": "system",
            "content": "You are a helpful translation assistant."
          },
          {"role": "user", "content": prompt}
        ],
        "model": "deepseek-chat",
        "stream": true,
        "temperature": 0.7,
        //"max_tokens": 4000,
      });

      final client = http.Client();
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..body = requestBody;

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        _logger.info(
            'DeepSeek API Stream Response: Status 200 OK. Starting to listen to stream for SSE data.');
        streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            //_logger.fine('DeepSeek Stream Raw Line: "$line"');
            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6);
              if (jsonString.trim() == '[DONE]') {
                //_logger.info('DeepSeek Stream: [DONE] received.');
                return;
              }
              try {
                final Map<String, dynamic> data = jsonDecode(jsonString);
                //_logger.fine('DeepSeek Stream JSON Data: $data');

                String translatedChunk = '';
                if (data.containsKey('choices') &&
                    data['choices'] is List &&
                    data['choices'].isNotEmpty) {
                  final choice = data['choices'][0];
                  if (choice.containsKey('delta') &&
                      choice['delta'].containsKey('content')) {
                    translatedChunk = choice['delta']['content'].toString();
                  }
                  if (choice.containsKey('delta') &&
                      choice['delta'].containsKey('reasoning_content') &&
                      data["model"] == "deepseek-reasoner") {}
                }

                if (translatedChunk.isNotEmpty) {
                  controller.add(translatedChunk);
                  //_logger.info(
                  //    'DeepSeek Stream: Added chunk to controller: "$translatedChunk"');
                } else {
                  //_logger.warning(
                  //   'DeepSeek Stream: Received empty chunk or no text in delta for line: "$line"');
                }
              } catch (e, stackTrace) {
                _logger.severe(
                    'Error parsing DeepSeek stream JSON line: $e\nLine: "$line"',
                    e,
                    stackTrace);
              }
            } else if (line.isNotEmpty) {
              _logger.fine(
                  'DeepSeek Stream: Non-data line received or malformed SSE: "$line"');
            }
          },
          onDone: () {
            controller.close();
            client.close();
            _logger.info(
                'DeepSeek Stream: All data received, controller and client closed.');
          },
          onError: (error, stackTrace) {
            _logger.severe(
                'DeepSeek translation stream error', error, stackTrace);
            controller.addError(error);
            controller.close();
            client.close();
          },
        );
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        _logger.severe(
            'DeepSeek API Error: ${streamedResponse.statusCode} - $responseBody');
        throw Exception(
            'Failed to translate with DeepSeek: ${streamedResponse.statusCode} - $responseBody');
      }
    } catch (e, stackTrace) {
      _logger.severe(
          'Error initiating DeepSeek translation stream', e, stackTrace);
      controller.addError(e);
      controller.close();
      rethrow;
    }
    return controller.stream;
  }
}

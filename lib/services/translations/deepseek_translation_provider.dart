import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/logs_helper.dart';

class DeepSeekTranslationProvider {
  String? _apiKey;
  final _logger = LogsService().logger;

  static const String _defaultBaseUrl = 'https://api.deepseek.com';
  static const String _chatCompletionsPath = '/chat/completions';

  String _currentBaseUrl = _defaultBaseUrl;
  bool _useCustomBaseUrl = false;
  String _modelName = 'deepseek-chat';
  double _temperature = 0.7;

  DeepSeekTranslationProvider._privateConstructor();

  static final DeepSeekTranslationProvider _instance =
      DeepSeekTranslationProvider._privateConstructor();

  static Future<DeepSeekTranslationProvider> get instance async {
    if (_instance._apiKey == null ||
        (_instance._currentBaseUrl == _defaultBaseUrl &&
            !_instance._useCustomBaseUrl) ||
        _instance._modelName == 'deepseek-chat') {
      await _instance._loadSettingsOnDemand();
    }
    return _instance;
  }

  Future<void> _loadSettingsOnDemand() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('deepseek_api_key');
    _useCustomBaseUrl = prefs.getBool('use_custom_deepseek_base_url') ?? false;
    final storedBaseUrl = prefs.getString('deepseek_base_url');
    _modelName = prefs.getString('deepseek_model_name') ?? 'deepseek-chat';
    _temperature = prefs.getDouble('deepseek_temperature') ?? 0.7;

    if (_useCustomBaseUrl &&
        storedBaseUrl != null &&
        storedBaseUrl.isNotEmpty) {
      _currentBaseUrl = storedBaseUrl;
    } else {
      _currentBaseUrl = _defaultBaseUrl;
    }
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

  void setBaseUrl(String baseUrl, bool useCustom) async {
    _useCustomBaseUrl = useCustom;
    if (useCustom && baseUrl.isNotEmpty) {
      _currentBaseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
    } else {
      _currentBaseUrl = _defaultBaseUrl;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_custom_deepseek_base_url', _useCustomBaseUrl);
    await prefs.setString('deepseek_base_url', baseUrl);
  }

  void setModelName(String newModelName) async {
    _modelName = newModelName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deepseek_model_name', newModelName);
  }

  void setTemperature(double newTemperature) async {
    _temperature = newTemperature;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('deepseek_temperature', newTemperature);
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

    try {
      final uri = Uri.parse('$_currentBaseUrl$_chatCompletionsPath');
      _logger.info('DeepSeek API Request URL: $uri');

      final requestBody = jsonEncode({
        "messages": [
          {
            "role": "system",
            "content": "You are a helpful translation assistant."
          },
          {"role": "user", "content": prompt}
        ],
        "model": _modelName,
        "stream": true,
        "temperature": _temperature,
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
            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6);
              if (jsonString.trim() == '[DONE]') {
                return;
              }
              try {
                final Map<String, dynamic> data = jsonDecode(jsonString);

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

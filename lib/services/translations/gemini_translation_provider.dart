import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/logs_helper.dart';

class GeminiTranslationProvider {
  String? _apiKey;
  final _logger = LogsService().logger;

  static const String _defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _streamGenerateContentPath = ':streamGenerateContent';

  String _currentBaseUrl = _defaultBaseUrl;
  bool _useCustomBaseUrl = false;
  String _modelName = 'gemini-2.5-flash';
  double _temperature = 1.0;

  GeminiTranslationProvider._privateConstructor();

  static final GeminiTranslationProvider _instance =
      GeminiTranslationProvider._privateConstructor();

  static Future<GeminiTranslationProvider> get instance async {
    if (_instance._apiKey == null ||
        (_instance._currentBaseUrl == _defaultBaseUrl &&
            !_instance._useCustomBaseUrl) ||
        _instance._modelName == 'gemini-2.5-flash') {
      await _instance._loadSettingsOnDemand();
    }
    return _instance;
  }

  Future<void> _loadSettingsOnDemand() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');
    _useCustomBaseUrl = prefs.getBool('use_custom_gemini_base_url') ?? false;
    final storedBaseUrl = prefs.getString('gemini_base_url');
    _modelName = prefs.getString('gemini_model_name') ?? 'gemini-2.5-flash';
    _temperature = prefs.getDouble('gemini_temperature') ?? 1.0;

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
      await prefs.setString('gemini_api_key', newKey);
    } else {
      await prefs.remove('gemini_api_key');
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
    await prefs.setBool('use_custom_gemini_base_url', _useCustomBaseUrl);
    await prefs.setString('gemini_base_url', baseUrl);
  }

  void setModelName(String newModelName) async {
    _modelName = newModelName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_model_name', newModelName);
  }

  void setTemperature(double newTemperature) async {
    _temperature = newTemperature;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gemini_temperature', newTemperature);
  }

  Future<Stream<String>> translateStream({
    required String text,
    required String sourceLangName,
    required String targetLangName,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.warning('Gemini API key is not set. Cannot translate.');
      throw Exception('Gemini API key is not set.');
    }

    final controller = StreamController<String>();

    final prompt =
        'Translate the following text from $sourceLangName to $targetLangName. Do not enclosed the translation with quotes or other extra punctuation. Respond only with the translated text, no conversational filler:\n\n"$text"';

    try {
      final uri = Uri.parse(
          '$_currentBaseUrl/$_modelName$_streamGenerateContentPath?alt=sse&key=$_apiKey');
      _logger.info('Gemini API Request URL: $uri');

      final requestBody = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "You are a helpful translation assistant."}
            ],
            "role": "user"
          },
          {
            "parts": [
              {"text": prompt}
            ],
            "role": "user"
          }
        ],
        "generationConfig": {
          "temperature": _temperature,
          "topK": 1,
          "topP": 1,
        },
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_NONE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_NONE"
          }
        ]
      });

      final client = http.Client();
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = requestBody;

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        _logger.info(
            'Gemini API Stream Response: Status 200 OK. Starting to listen to stream for SSE data.');
        streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.startsWith('data: ')) {
              final jsonString = line.substring(6);
              try {
                final Map<String, dynamic> data = jsonDecode(jsonString);

                String translatedChunk = '';
                if (data.containsKey('candidates') &&
                    data['candidates'] is List &&
                    data['candidates'].isNotEmpty) {
                  final candidate = data['candidates'][0];
                  if (candidate.containsKey('content') &&
                      candidate['content']['parts'] is List &&
                      candidate['content']['parts'].isNotEmpty) {
                    for (var part in candidate['content']['parts']) {
                      if (part.containsKey('text')) {
                        translatedChunk += part['text'].toString();
                      }
                    }
                  }
                }

                if (translatedChunk.isNotEmpty) {
                  controller.add(translatedChunk);
                }
              } catch (e, stackTrace) {
                _logger.severe(
                    'Error parsing Gemini stream JSON line: $e\nLine: "$line"',
                    e,
                    stackTrace);
              }
            } else if (line.isNotEmpty) {
              _logger.fine(
                  'Gemini Stream: Non-data line received or malformed SSE: "$line"');
            }
          },
          onDone: () {
            controller.close();
            client.close();
            _logger.info(
                'Gemini Stream: All data received, controller and client closed.');
          },
          onError: (error, stackTrace) {
            _logger.severe(
                'Gemini translation stream error', error, stackTrace);
            controller.addError(error);
            controller.close();
            client.close();
          },
        );
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        _logger.severe(
            'Gemini API Error: ${streamedResponse.statusCode} - $responseBody');
        throw Exception(
            'Failed to translate with Gemini: ${streamedResponse.statusCode} - $responseBody');
      }
    } catch (e, stackTrace) {
      _logger.severe(
          'Error initiating Gemini translation stream', e, stackTrace);
      controller.addError(e);
      controller.close();
      rethrow;
    }
    return controller.stream;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsReader extends StatefulWidget {
  final String text;
  final String title;
  const TtsReader({super.key, required this.title, required this.text});

  @override
  State<TtsReader> createState() => _TtsReaderState();
}

class _TtsReaderState extends State<TtsReader> {
  final FlutterTts tts = FlutterTts();
  late List<String> sentences;
  int currentIndex = 0;
  bool isPlaying = false;
  bool _manuallyStopped = false;
  bool _isSkipping = false;

  final List<GlobalKey> _keys = [];
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> voices = [];
  List<String> languagesList = [];
  String selectedLanguage = '';
  String selectedVoiceName = '';
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    sentences = RegExp(r'([^.！？。?!]+[.！？。?!]|\n|$)')
        .allMatches(widget.text)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _keys.addAll(List.generate(sentences.length, (_) => GlobalKey()));

    tts.setCompletionHandler(() {
      if (!_manuallyStopped && !_isSkipping) {
        if (currentIndex < sentences.length - 1) {
          setState(() => currentIndex++);
          _scrollToCurrent();
          _speakCurrent();
        } else {
          setState(() => isPlaying = false);
        }
      } else {
        _manuallyStopped = false;
        _isSkipping = false;
      }
    });

    _loadLanguagesAndVoices();
  }

  Future<void> _loadLanguagesAndVoices() async {
    List<dynamic> rawVoices = await tts.getVoices;
    voices = rawVoices
        .map<Map<String, String>>((v) => Map<String, String>.from(v))
        .toList();

    Set<String> langs = voices.map((v) {
      final locale = v['locale'] ?? '';
      return locale.split('-').first;
    }).toSet();

    languagesList = langs.toList();

    if (voices.isNotEmpty) {
      selectedVoiceName = voices.first['name']!;
      selectedLanguage = voices.first['locale']!.split('-').first;
      await _applySettings();
    }

    setState(() {});
  }

  Future<void> _applySettings() async {
    if (selectedVoiceName.isNotEmpty) {
      final voice = voices.firstWhere(
        (v) => v['name'] == selectedVoiceName,
        orElse: () => voices.first,
      );
      await tts.setVoice(voice);
    }
    await tts.setPitch(pitch);
    await tts.setSpeechRate(rate);
  }

  Future<void> _speakCurrent() async {
    _manuallyStopped = false;
    await tts.stop();
    await _applySettings();
    await tts.speak(sentences[currentIndex]);
    setState(() => isPlaying = true);
    _scrollToCurrent();
    _isSkipping = false;
  }

  void _scrollToCurrent() {
    final context = _keys[currentIndex].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  void _togglePlayPause() async {
    if (isPlaying) {
      _manuallyStopped = true;
      await tts.stop();
      setState(() => isPlaying = false);
    } else {
      _speakCurrent();
    }
  }

  Future<void> _skipPrevious() async {
    if (currentIndex > 0) {
      _manuallyStopped = true;
      _isSkipping = true;
      await tts.stop();
      setState(() => currentIndex--);
      _speakCurrent();
    }
  }

  Future<void> _skipNext() async {
    if (currentIndex < sentences.length - 1) {
      _manuallyStopped = true;
      _isSkipping = true;
      await tts.stop();
      setState(() => currentIndex++);
      _speakCurrent();
    }
  }

  String friendlyVoiceName(Map<String, dynamic> voice) {
    String name = voice['name'] ?? voice['identifier'] ?? 'Voice';

    if (voice.containsKey('gender') && (voice['gender']?.isNotEmpty ?? false)) {
      name += ' (${voice['gender']})';
    }

    if (voice.containsKey('quality') &&
        (voice['quality']?.isNotEmpty ?? false)) {
      name += ' [${voice['quality']}]';
    }

    if (voice.containsKey('identifier') &&
        (voice['identifier']?.isNotEmpty ?? false)) {
      final parts = (voice['identifier'] as String).split('.');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        if (!name.contains(lastPart)) name += ' <$lastPart>';
      }
    }

    return name;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Highlighted sentence
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: sentences.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      key: _keys[index],
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        sentences[index],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: index == currentIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: index == currentIndex
                              ? colorScheme.primary
                              : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              // Seek bar
              Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (sentences.length - 1).toDouble(),
                divisions: sentences.length - 1,
                label: "Sentence ${currentIndex + 1}",
                onChanged: (value) {
                  setState(() => currentIndex = value.toInt());
                },
                onChangeStart: (value) async {
                  _manuallyStopped = true;
                  _isSkipping = true;
                  await tts.stop();
                },
                onChangeEnd: (value) async {
                  _manuallyStopped = true;
                  _isSkipping = true;
                  await tts.stop();
                  _speakCurrent();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Language chip
                  ActionChip(
                    label: Text(selectedLanguage.toUpperCase()),
                    onPressed: () async {
                      String? chosenLang = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => ListView(
                          shrinkWrap: true,
                          children: languagesList.map((lang) {
                            return ListTile(
                              title: Text(lang.toUpperCase()),
                              onTap: () => Navigator.pop(context, lang),
                            );
                          }).toList(),
                        ),
                      );

                      if (chosenLang != null) {
                        setState(() => selectedLanguage = chosenLang);
                        List<Map<String, String>> voicesInLang = voices
                            .where((v) => v['locale']!.startsWith(chosenLang))
                            .toList();
                        if (voicesInLang.isNotEmpty) {
                          setState(() =>
                              selectedVoiceName = voicesInLang.first['name']!);
                          await _applySettings();
                        }
                      }
                    },
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(color: colorScheme.primary),
                  ),

                  const SizedBox(width: 8),

                  // Voice chip
                  ActionChip(
                    label: Text(selectedVoiceName),
                    onPressed: () async {
                      List<Map<String, String>> voicesInLang = voices
                          .where(
                              (v) => v['locale']!.startsWith(selectedLanguage))
                          .toList();

                      String? chosenVoice = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => ListView(
                          shrinkWrap: true,
                          children: voicesInLang.map((v) {
                            final displayName = friendlyVoiceName(v);
                            return ListTile(
                              title: Text(displayName),
                              onTap: () => Navigator.pop(context, v['name']),
                            );
                          }).toList(),
                        ),
                      );

                      if (chosenVoice != null) {
                        setState(() => selectedVoiceName = chosenVoice);
                        await _applySettings();
                      }
                    },
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(color: colorScheme.primary),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Pitch"),
                        // Pitch slider
                        Slider(
                          value: pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          label: pitch.toStringAsFixed(1),
                          onChanged: (v) {
                            setState(() => pitch = v);
                            _applySettings();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Speed"),
                        // Speed slider
                        Slider(
                          value: rate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: rate.toStringAsFixed(1),
                          onChanged: (v) {
                            setState(() => rate = v);
                            _applySettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    color: colorScheme.primary,
                    iconSize: 36,
                    onPressed: _skipPrevious,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 42,
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    color: colorScheme.primary,
                    iconSize: 36,
                    onPressed: _skipNext,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

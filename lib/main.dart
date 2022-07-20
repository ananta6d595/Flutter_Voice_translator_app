import 'dart:async';
import 'dart:math';
import 'package:marquee/marquee.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_to_text/recognizeWords.dart';
import 'translated_text/tarnslated.dart';

void main() => runApp(SpeechSampleApp());

class SpeechSampleApp extends StatefulWidget {
  @override
  _SpeechSampleAppState createState() => _SpeechSampleAppState();
}

/// An example that demonstrates the basic functionality of the
/// SpeechToText plugin for using the speech recognition capability
/// of the underlying platform.
class _SpeechSampleAppState extends State<SpeechSampleApp> {
  bool _hasSpeech = false;
  bool _logEvents = false;
  final TextEditingController _pauseForController =
      TextEditingController(text: '5');
  final TextEditingController _listenForController =
      TextEditingController(text: '30');
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  String _forTranslationLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  @override
  void initState() {
    super.initState();
  }

  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
        _forTranslationLocaleId = 'en';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Translator '),
        ),
        body: Column(
          children: [
            if (lastError.isNotEmpty) HeaderWidget(),
            // if (lastError.isNotEmpty)
            //   Expanded(
            //     flex: 1,
            //     child: ErrorWidget(lastError: lastError),
            //   ),
            Expanded(
              flex: 1,
              child:
                  RecognitionResultsWidget(lastWords: lastWords, level: level),
            ),
            Expanded(
              flex: 1,
              child: TranslationWidget(
                  lastWords: lastWords,
                  sourceLanguage: _currentLocaleId,
                  targetedLanguage: 'en'),
            ),
            Container(
              child: Column(
                children: <Widget>[
                  SessionOptionsWidget(
                    _currentLocaleId,
                    _forTranslationLocaleId,
                    _switchSpeechLang,
                    _switchTargetLang,
                    _localeNames,
                    _logEvents,
                    _switchLogging,
                    _pauseForController,
                    _listenForController,
                    _languageNames,
                  ),
                  InitSpeechWidget(_hasSpeech, initSpeechState),
                  SpeechControlWidget(_hasSpeech, speech.isListening,
                      startListening, stopListening, cancelListening),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            SpeechStatusWidget(speech: speech),
          ],
        ),
      ),
    );
  }

  // This is called each time the users wants to start a new speech
  // recognition session
  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';
    final pauseFor = int.tryParse(_pauseForController.text);
    final listenFor = int.tryParse(_listenForController.text);
    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: listenFor ?? 30),
        pauseFor: Duration(seconds: pauseFor ?? 5),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = '${result.recognizedWords} - ${result.finalResult}';
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchSpeechLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }

  void _switchTargetLang(selectedVal) {
    setState(() {
      _forTranslationLocaleId = selectedVal;
    });
    print(selectedVal);
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      print('$eventTime $eventDescription');
    }
  }

  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 40,
        child: Marquee(
            text:
                '* Please 1. Give Google app microphone access permission.  2.Press initialize or start Button to continue',
            blankSpace: 30),
      ),
    );
  }
}

/// Display the current error status from the speech
/// recognizer
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    Key? key,
    required this.lastError,
  }) : super(key: key);

  final String lastError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: Text(
            'Error Status',
            style: TextStyle(fontSize: 22.0),
          ),
        ),
        Center(
          child: Text(lastError),
        ),
      ],
    );
  }
}

/// Controls to start and stop speech recognition
class SpeechControlWidget extends StatelessWidget {
  const SpeechControlWidget(this.hasSpeech, this.isListening,
      this.startListening, this.stopListening, this.cancelListening,
      {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        //start of speech
        ElevatedButton.icon(
          onPressed: !hasSpeech || isListening ? null : startListening,
          icon: Icon(Icons.play_arrow),
          label: Text('Start'),
        ),
        //stop speech
        ElevatedButton.icon(
          onPressed: isListening ? stopListening : null,
          icon: Icon(Icons.stop),
          label: Text(
            'Stop',
          ),
        ),
        // cancel speech
        ElevatedButton.icon(
          onPressed: isListening ? cancelListening : null,
          icon: Icon(Icons.cancel_rounded),
          label: Text('Cancel'),
        )
      ],
    );
  }
}

var _languageNames = {'English': 'en', 'Bengali': 'bn'};

class SessionOptionsWidget extends StatelessWidget {
  const SessionOptionsWidget(
    this.currentLocaleId,
    this.forTranslationLocaleId,
    this.switchSpeechLang,
    this.switchTargetLang,
    this.localeNames,
    this.logEvents,
    this.switchLogging,
    this.pauseForController,
    this.listenForController,
    this.languageNames, {
    Key? key,
  }) : super(key: key);

  final String currentLocaleId;
  final String forTranslationLocaleId;
  final void Function(String?) switchSpeechLang;
  final void Function(String?) switchTargetLang;
  final void Function(bool?) switchLogging;
  final TextEditingController pauseForController;
  final TextEditingController listenForController;
  final List<LocaleName> localeNames;
  final languageNames;
  final bool logEvents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              Text('SpeechLanguage: '),
              DropdownButton<String>(
                onChanged: (selectedVal) => switchSpeechLang(selectedVal),
                value: currentLocaleId,
                items: localeNames
                    .map(
                      (localeName) => DropdownMenuItem(
                        value: localeName.localeId,
                        child: Text(localeName.name),
                      ),
                    )
                    .toList(),
                dropdownColor: Color.fromARGB(255, 199, 232, 255),
              ),
            ],
          ),
          // Row(
          //   children: [
          //     Text('TranslationLanguage: '),
          //     DropdownButton<String>(
          //       onChanged: (selectedVal) => switchTargetLang(selectedVal),
          //       value: forTranslationLocaleId,
          //       items: languageNames.map((languageNames, keys) {
          //         return MapEntry(
          //             languageNames,
          //             DropdownMenuItem<String>(
          //               value: keys,
          //               child: Text(languageNames),
          //             ));
          //       }).values.toList(),
          //       dropdownColor: Color.fromARGB(255, 199, 232, 255),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Text('waitFor: '),
              Container(
                padding: EdgeInsets.only(left: 8),
                width: 80,
                child: TextFormField(
                  controller: pauseForController,
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 16),
                child: Text('listenFor: '),
              ),
              Container(
                  padding: EdgeInsets.only(left: 8),
                  width: 80,
                  child: TextFormField(
                    controller: listenForController,
                  )),
            ],
          ),
          SizedBox(
            height: 8.0,
          )
          // Row(
          //   children: [
          //     Text('Log events: '),
          //     Checkbox(
          //       value: logEvents,
          //       onChanged: switchLogging,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: hasSpeech ? null : initSpeechState,
          icon: Icon(Icons.bolt_rounded),
          label: Text('Initialize'),
        ),
      ],
    );
  }
}

/// Display the current status of the listener
class SpeechStatusWidget extends StatelessWidget {
  const SpeechStatusWidget({
    Key? key,
    required this.speech,
  }) : super(key: key);

  final SpeechToText speech;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      color: Theme.of(context).backgroundColor,
      child: Center(
        child: speech.isListening
            ? Text(
                "I'm listening...",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : Text(
                'Not listening',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

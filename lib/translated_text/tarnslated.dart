import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simplytranslate/simplytranslate.dart';

/// Displays the most recently recognized words and the sound level.
class TranslationWidget extends StatefulWidget {
  const TranslationWidget({
    Key? key,
    required this.lastWords,
    required this.sourceLanguage,
    required this.targetedLanguage,
  }) : super(key: key);

  final String lastWords;
  final String sourceLanguage;
  final String targetedLanguage;

  @override
  State<TranslationWidget> createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Center(
          child: Text(
            'Translated Speech',
            style: TextStyle(fontSize: 22.0),
          ),
        ),
        Expanded(
          child: Stack(
            children: <Widget>[
              Container(
                color: Theme.of(context).selectedRowColor,
                child: Center(
                  child: _buildFutureBuilder(widget.lastWords,
                      widget.sourceLanguage, widget.targetedLanguage),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String> _translateFunction(
      String lastWord, String sourceLang, String targetLang) async {
    ///use Google Translate
    final gt = SimplyTranslator(EngineType.google);

    ///if you do not specify the source language it is automatically selecting it depending on the text
    ///if you do not specify the target language it is automatically English

    ///change instance (defaut is simplytranslate.org)
    List<String> link = gt.getInstances;

    gt.setInstance = link[Random().nextInt(link.length)];

    ///using Googletranslate:
    ///short form to only get translated text as String, also shorter code:
    String textResult = await gt.trSimply(
        lastWord.isEmpty ? 'waiting...' : lastWord, sourceLang, targetLang);

    print(textResult);
    //He walks fast.
    return textResult;
  }

  Widget _buildFutureBuilder(
      String lastWords, String sourceLanguage, String targetedLanguage) {
    return Center(
      child: FutureBuilder<String>(
        future: _translateFunction(lastWords, sourceLanguage, targetedLanguage),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done)
            return Text("${snapshot.data}");

          return CircularProgressIndicator();
        },
      ),
    );
  }
}

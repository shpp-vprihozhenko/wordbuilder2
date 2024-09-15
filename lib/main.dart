import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:word_builder2/About.dart';
import 'wordsLst.dart';

enum TtsState { playing, stopped, paused, continued }
double letterPlaceSize = 60.0;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Строим слоги и слова',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Строим слоги и слова'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List <String> centralLetters = [];

  String targetWord = '';
  int numCentralLetters = 3;
  int numHotLetters = 5, numColdLetters = 5, counter = 0;
  List <String> listHotLetters=[], listColdLetters=[];
  final allHotLetters = 'АЕОУИЫЭЮЯЁ';
  final allColdLetters = 'НТСРВЛКМДПГЗБЧХЖШЦЩФЬЪЙ';
  final specialLetters = '-';
  String targetText = '';
  List<String> wordsList = [];
  List<String> filteredWordsList = [];

  List<Widget> listColdLetterWidgets = [];
  List<Widget> listHotLetterWidgets = [];

  bool speakMode = false;

  late FlutterTts flutterTts;
  dynamic languages;
  String language='';
  double volume = 1;
  double pitch = 1;
  double rate = 0.34;

  bool isFirstRun = true;

  @override
  void initState() {
    super.initState();
    wordsList =  WordsList.getList();
    initTtsAndStartLoop();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  void startLoop() async {
    filteredWordsList = wordsList.where((el) => el.length == numCentralLetters).toList();
    formTargetWord();
    print('got targetWord $targetWord');
    formHotColdLettersLists();
    targetText = "Построй ${targetWord.length == 2? 'слог':'слово'}";
    setState(() {});
    print('targetWord $targetWord');
    if (isFirstRun) {
      isFirstRun = false;
      flutterTts.speak('Привет');
      await Future.delayed(const Duration(seconds: 1));
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(seconds: 1));
        await flutterTts.speak('Давай строить слова! Я назову слово, а ты - перетягивай буковки в середину, чтобы получилось загаданное слово.');
      } else {
        await _speak('Давай строить слова! Я назову слово, а ты - перетягивай буковки в середину, чтоб получилось загаданное слово.');
      }
    }
    await _speakSync(targetText);
    await _speakSync(targetWord);
  }
  
  void formTargetWord() {
    var rng = Random();
    targetWord = filteredWordsList[rng.nextInt(filteredWordsList.length)].toUpperCase();
  }

  List shuffle(List items) {
    var random = Random();
    for (var i = items.length - 1; i > 0; i--) {
      var n = random.nextInt(i + 1);
      var temp = items[i];
      items[i] = items[n];
      items[n] = temp;
    }
    return items;
  }

  String anyLetter(var rng, String allLetters, List<String> listUsedLetters) {
    String letter = '';
    do {
      int pos = rng.nextInt(allLetters.length);
      letter = allLetters.substring(pos, pos+1);
      if (listUsedLetters.contains(letter)) {
        letter = '';
      }
    } while (letter == '');
    return letter;
  }

  void formHotColdLettersLists() {
    listHotLetters = []; listColdLetters = [];
    listHotLetterWidgets = []; listColdLetterWidgets = [];

    var rng = Random();

    for (int i = 0; i < numHotLetters; i++) {
      String selectedLetter = '';
      if (i < targetWord.length) {
        String ch = targetWord.substring(i, i+1);
        if (allHotLetters.contains(ch)) {
          selectedLetter = ch;
        }
      }
      if (selectedLetter == '') {
        selectedLetter = anyLetter(rng, allHotLetters, listHotLetters); //allHotLetters[rng.nextInt(hTotal)];
      }
      listHotLetters.add(selectedLetter);
    }

    shuffle(listHotLetters);
    formWidgetsList(listHotLetters, listHotLetterWidgets);

    for (int i = 0; i < numColdLetters; i++) {
      String selectedLetter = '';
      if (i < targetWord.length) {
        String ch = targetWord.substring(i, i+1);
        if (allColdLetters.contains(ch)) {
          selectedLetter = ch;
        }
      }
      if (selectedLetter == '') {
        selectedLetter = anyLetter(rng, allColdLetters, listColdLetters); //allHotLetters[rng.nextInt(hTotal)];
      }
      listColdLetters.add(selectedLetter);
    }

    shuffle(listColdLetters);
    formWidgetsList(listColdLetters, listColdLetterWidgets);
  }

  void formWidgetsList(List<String> lettersList, List<Widget> lw) {
    for(int i=0; i<lettersList.length; i++) {
      lw.add(ContWithDLetter(letter: lettersList[i], key: null,));
    }
  }

  initTtsAndStartLoop() async {
    flutterTts = FlutterTts();
    if (Platform.isIOS) {
      print('ios');
      await flutterTts.setSharedInstance(true);
      await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.defaultMode
      );
    } else {
      String defEng = await flutterTts.getDefaultEngine;
      if (!defEng.contains('google')) {
        var engines = await flutterTts.getEngines;
        int gIdx = engines.indexWhere((element) => element.toString().contains('google'));
        await flutterTts.setEngine(engines[gIdx]);
      }
    }
    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('ru-RU');
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.awaitSpeakCompletion(true);
    startLoop();
  }

  //_speak(String text, [String text2='']) async {
  Future _speak(String text) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    await flutterTts.speak(text);
  }

  _speakSync(String text) async {
    await _speak(text);
    return;

    final c = Completer();
    flutterTts.setCompletionHandler(() {
      c.complete("ok");
    });
    flutterTts.speak(text);
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: buildMainContainer(),
      bottomNavigationBar:
        Container(
          color: Colors.blue[100],
          child: buildBottomRow(),
        )
    );
  }

  Widget buildBottomRow() {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: 'about',
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const About()),);
                },
                child: const Text('?', style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),)
            ),
            // GestureDetector(
            //   onTap: difDown,
            //   child: Container(
            //     decoration: const BoxDecoration(
            //       color: Colors.blue,
            //       shape: BoxShape.circle,
            //     ),
            //     width: 55, height: 55,
            //     child: const Center(
            //         child: Icon(Icons.arrow_back_ios_new_rounded, size: 40, color: Colors.white,)
            //     ),
            //   ),
            // ),
            FloatingActionButton(
              heroTag: 'down',
                onPressed: difDown,
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 40, color: Colors.white,)
            ),
            FloatingActionButton(
              heroTag: 'up',
                onPressed: difUp,
                child: const Icon(Icons.arrow_forward_ios_outlined, size: 40, color: Colors.white,)
            ),
            FloatingActionButton(
              heroTag: 'repeat',
                onPressed: _repeatCurSyl,
                child: const Icon(Icons.volume_up, size: 40, color: Colors.white,)
            ),
          ],
        );
  }

  Container buildMainContainer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child:
        Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: hotLettersBlock(),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: CupertinoColors.activeOrange,
              //width: double.infinity,
              //height: 80,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: listOfDrags(),
              ),
            ),
            Expanded(
              flex: 2,
              child: coldLettersBlock(),
            ),
          ],
        ),
    );
  }

  Widget coldLettersBlock() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: listColdLetterWidgets,
          ),
        ],
      ),
    );
  }

  Widget hotLettersBlock() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: listHotLetterWidgets,
          ),
        ],
      ),
    );
  }

  List<Widget> listOfDrags() {
    List<Widget> lw = [];
    for (var i=0; i<numCentralLetters; i++) {
      if (centralLetters.length <= i){
        centralLetters.add('');
      }
      lw.add(DragTarget(
        builder: (context, candidateData, rejectedData) =>
            Container(width: letterPlaceSize, height: letterPlaceSize,
              decoration: BoxDecoration(color: Colors.yellow[200], shape: BoxShape.circle,),
              child: Center(child: Text(centralLetters[i], textScaleFactor: 3,
                style: const TextStyle(
                    color: Colors.blue,
                  fontWeight: FontWeight.bold
                ), textAlign: TextAlign.center,)),
            ),
        onAccept: (String data){
          setState(() {
            centralLetters[i] = data;
          });
          Future.delayed(Duration.zero, () => speakCentralLettersAndStartNewLoop(context));
        },
      ));
    }
    return lw;

  }

  void _repeatCurSyl() async {
    await _speak(targetText);
    await _speak(targetWord);
  }

  speakCentralLettersAndStartNewLoop(BuildContext context) async {
    if (speakMode) {
      return;
    }
    speakMode = true;
    String res = '';
    bool allLettersCompleted = true;
    for (int i=0; i<numCentralLetters; i++) {
      if (centralLetters[i]=='') {
        allLettersCompleted = false;
        break;
      }
      res += centralLetters[i];
    }
    if (allLettersCompleted) {
      if (res == targetWord) {
        await _speakSync('Правильно!');
        await _speakSync('Получилось ${res.toLowerCase()} !');
        await Future.delayed(const Duration(milliseconds: 500));
        nextLoop();
      } else {
        await _speakSync('Неправильно. Получилось ${res.toLowerCase()}, а надо ${targetWord.toLowerCase()} !');
        await Future.delayed(const Duration(milliseconds: 500));
        await _speakSync('Попробуй ещё раз.');
        setState(() {
          clearCentralLetters();
        });
        await _speakSync(targetWord.toLowerCase());
      }
    }
    speakMode = false;
  }

  void clearCentralLetters() {
    for (int i=0; i<numCentralLetters; i++) {
      centralLetters[i]='';
    }
  }

  void nextLoop() {
    setState(() {
      print('clear in next loop');
      clearCentralLetters();
    });
    counter++;
    if (counter%20 == 0) {
      if (numColdLetters < 6) {
        numCentralLetters++;
      }
    }
    if (counter%10 == 0) {
      if (numHotLetters < allHotLetters.length) {
        numHotLetters++;
      }
      if (numColdLetters < allColdLetters.length) {
        numColdLetters++;
      }
    }
    startLoop();
  }

  void restart() {
    setState(() {
      numCentralLetters = 3; numHotLetters = 5; numColdLetters = 5; counter = 0;
      startLoop();
    });
  }

  void difUp() {
    setState(() {
      if (numCentralLetters < 7) {
        numCentralLetters++;
        if (numCentralLetters>4) {
          numColdLetters++;
          numHotLetters++;
        }
      } else {
        if (numHotLetters < allHotLetters.length) {
          numHotLetters++;
        }
        if (numColdLetters < allColdLetters.length) {
          numColdLetters++;
        }
      }
    });
    startLoop();
  }

  void difDown() {
    setState(() {
      if (numCentralLetters > 2) {
        numCentralLetters--;
      } else {
        numHotLetters = 5;
        numColdLetters = 5;
      }
    });
    startLoop();
  }
}

class CircleButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String letter;

  const CircleButton({required Key key, required this.onTap, required this.letter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: ContWithDLetter(letter: letter),
    );
  }
}

class ContWithDLetter extends StatelessWidget {
  const ContWithDLetter({
    Key? key,
    required this.letter,
  }) : super(key: key);

  final String letter;

  @override
  Widget build(BuildContext context) {
    Color fColor = !'АЕЁОУИЫЭЮЯ'.contains(letter) ? Colors.green:Colors.red;
    return Container(
      width: letterPlaceSize,
      height: letterPlaceSize,
      //decoration: new BoxDecoration(
        //color: Colors.white,
        //shape: BoxShape.circle,
      //),
      child: Draggable(
        feedback: Text(letter,
          textAlign: TextAlign.center,
          textScaleFactor: 1,
          style: const TextStyle(color: Colors.blueAccent),),
        data: letter,
        child: Container(
            width: letterPlaceSize, height: letterPlaceSize, color: Colors.lightGreen[100],
            child: Center(
                child: Text(letter,
                  textAlign: TextAlign.center,
                  textScaleFactor: 3,
                  style: TextStyle(
                      color: fColor,
                    fontWeight: FontWeight.bold
                  ),
                )
            )
        ),
      )
    );
  }
}


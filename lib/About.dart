import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  runApp(const MediaQuery(data: MediaQueryData(),
      child: MaterialApp(home: About())
  ));
}

class About extends StatefulWidget {
  const About({Key? key}) : super(key: key);

  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("О програме..."),
        ),
        body: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
          child: Center(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  const SizedBox(height: 20,),
                  const Text('Предложите ребёнку поиграть - собрать услышанное слово из буковок на экране, перетаскивая их в центральные окошки.',
                    textAlign: TextAlign.center, textScaleFactor: 1.5,),
                  const SizedBox(height: 20,),
                  const Text('Автор идеи и разработчик - Прихоженко Владимир',
                    textAlign: TextAlign.center, textScaleFactor: 1.5, style: TextStyle(color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 12,),
                  Image.asset('assets/v1.jpg', height: 309,),
                  const SizedBox(height: 12,),
                  const Text('Все вопросы и пожелания прошу слать на е-мейл',
                    textAlign: TextAlign.center, textScaleFactor: 1.5, style: TextStyle(color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 12,),
                  GestureDetector(
                    onTap: (){
                      launchUrl(Uri.parse('mailto:vprihogenko@gmail.com'));
                    },
                    child: Container(
                      color: Colors.yellow[100],
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('vprihogenko@gmail.com', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, ),),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80,),
                ]
              )
          ),
        ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'La Rodobotonera'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CustomSound> _soundList;
  List<CustomSound> _defSounds = [
    new CustomSound("AhiLaTeni", "sounds", "Ahí la tení"),
    new CustomSound("Hienas", "sounds", "Matensé, hienas"),
    new CustomSound("RikaChikita", "sounds", "Rika Chikita"),
    new CustomSound("YChi", "sounds", "Y Chi"),
    new CustomSound("YEia", "sounds", "Y eia? Como esta eia?"),
  ];

  Duration duration;
  Duration position;

  AudioPlayer audioPlayer;

  String localFilePath;
  String audioName = '';

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';
  get positionText =>
      position != null ? position.toString().split('.').first : '';

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  void initAudioPlayer() {
    audioPlayer = new AudioPlayer();

    audioPlayer.setDurationHandler((d) => setState(() {
          duration = d;
        }));

    audioPlayer.setPositionHandler((p) => setState(() {
          position = p;
        }));

    audioPlayer.setCompletionHandler(() {
      onComplete();
      setState(() {
        position = duration;
      });
    });

    audioPlayer.setErrorHandler((msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });
  }

  Future _playLocal() async{
    final result = await audioPlayer.play(localFilePath, isLocal: true);
    if (result == 1) setState(() => playerState = PlayerState.playing);
  }

  Future pause() async {
    final result = await audioPlayer.pause();
    if (result == 1) setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    final result = await audioPlayer.stop();
    if (result == 1)
      setState(() {
        playerState = PlayerState.stopped;
        position = new Duration();
      });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
    /* @TODO clean temporary folder */
  }

  Future<ByteData> loadAsset() async {
    return await rootBundle.load('sounds/$audioName.ogg');
  }
  void playFile() async {
    final file = new File('${(await getTemporaryDirectory()).path}/music.mp3');
    await file.writeAsBytes((await loadAsset()).buffer.asUint8List());
    if(isPlaying) {
      stop(); //Before play the next, stop actual
    }
    localFilePath = file.path;
    _playLocal();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        centerTitle: true,
        title: new Text(widget.title),
      ),
      body: new GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          new Card(
            child: new Stack(
              children: <Widget>[
                new Image(
                  image: new AssetImage("images/AriDante.jpeg"),
                  fit: BoxFit.cover,
                ),
                new Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        new Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Text(
                              _defSounds[0].name,
                              textAlign: TextAlign.center,
                            ),
                            new Text(
                              _defSounds[0].desc,
                              textAlign: TextAlign.center,
                            )
                          ],
                        )
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new IconButton(
                          icon: new Icon(Icons.play_circle_filled),
                          onPressed: dummy,
                        ),
                        new IconButton(
                          icon: new Icon(Icons.share),
                          onPressed: dummy,
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          new Card(
            child: new Image.asset("images/CloudSword.jpeg"),
          ),
        ],
      ),
    );
  }

  void dummy()
  {

  }
}

class CustomSound {
  String name;
  String desc;
  String fileName;
  String filePath;

  CustomSound(this.fileName, this.filePath, [this.name = "", this.desc = ""]);
}

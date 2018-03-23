import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

typedef void OnError(Exception exception);

typedef void CompletedState(CustomSound sound);

enum PlayerState { stopped, playing, paused }

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'La Rodobotonera'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CustomSound> _defSounds = [
    new CustomSound("AhiLaTeni", "sounds", null, "Ahí la tení"),
    new CustomSound("Hienas", "sounds", null, "Matensé, hienas"),
    new CustomSound("RikaChikita", "sounds", null, "Rika Chikita"),
    new CustomSound("YChi", "sounds", null, "Y Chi"),
    new CustomSound("YEia", "sounds", null, "Y eia? Como esta eia?"),
  ];

  CustomAudioPlayer audioPlayer = new CustomAudioPlayer();

  @override
  void initState() {
    super.initState();
    audioPlayer.initAudioPlayer();
  }

  void onAudioPlayCompletion(CustomSound sound) {
    setState(() => sound.currentStatus = PlayerState.stopped);
  }
/* TODO move this to another file */


/* End of TODO */
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        centerTitle: true,
        title: new Text(widget.title),
      ),
      body: new GridView.count(
        crossAxisCount: 2,
        children: _buildGridViewCards(_defSounds),
      ),
    );
  }

  void dummy() {}

  void requestPlay(CustomSound sound) {
    setState(() {
      sound.currentStatus = PlayerState.playing;
      sound.completedState = onAudioPlayCompletion;
      audioPlayer.playAudio(sound);
    });
  }

  void requestStop(CustomSound sound) {
    // TODO Try Catch
    setState(() {
      sound.currentStatus = PlayerState.stopped;
      sound.completedState = onAudioPlayCompletion;
      audioPlayer.stopAudio();
    });
  }

  void requestShare(CustomSound sound) {
  }

  List<Widget> _buildGridViewCards(List<CustomSound> sound) {
    List<Widget> ret = new List<Widget>();

    /* Previous check */
    if (sound.isEmpty) {
      ret.add(new Text(
        "Lista vacía!",
        style: new TextStyle(
            fontSize: 48.0,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent),
      ));

      return ret;
    }
    for (var s in sound) {
      ret.add(_cardBuild(s));
    }

    return ret;
  }

  Icon _getAudioIconByPlayerState(PlayerState status) {
    switch (status) {
      case PlayerState.playing:
      case PlayerState.paused:
        return new Icon(Icons.stop);
        break;
      case PlayerState.stopped:
        return new Icon(Icons.play_circle_filled);
    }

    return new Icon(Icons.play_circle_filled);
  }

  Card _cardBuild(CustomSound sound) {
    return new Card(
        child: new Stack(
      children: <Widget>[
/*          new Image(
            image: sound.cover.image,
            fit: BoxFit.cover,
          ),*/
        new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    new Text(
                      sound.name,
                      textAlign: TextAlign.center,
                    ),
                    new Text(
                      sound.desc,
                      textAlign: TextAlign.center,
                    )
                  ],
                )
              ],
            ),
            new Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new IconButton(
                  icon: new Icon(
                    Icons.share,
                  ),
                  onPressed: dummy,
                ),
                new IconButton(
                  icon: _getAudioIconByPlayerState(sound.currentStatus),
                  onPressed: () {
                    if (sound.currentStatus != PlayerState.stopped) {
                      requestStop(sound);
                    } else {
                      requestPlay(sound);
                    }
                  },
                )
              ],
            )
          ],
        )
      ],
    ));
  }
}

class CustomSound extends AudioPlayer {
  String name;
  String desc;
  String fileName;
  String filePath;
  PlayerState currentStatus;
  CompletedState completedState;

  CustomSound(this.fileName, this.filePath, this.completedState,
      [this.name = "",
      this.desc = "",
      this.currentStatus = PlayerState.stopped]);
}

class CustomAudioPlayer extends AudioPlayer {
  Duration _duration;
  Duration _position;
  AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  CustomSound _localSound;

/* Getters */
  get isPlaying => _playerState == PlayerState.playing;
  get isPaused => _playerState == PlayerState.paused;
  get isStopped => _playerState == PlayerState.stopped;

  get durationText =>
      _duration != null ? _duration.toString().split('.').first : '';
  get positionText =>
      _position != null ? _position.toString().split('.').first : '';

  void initAudioPlayer() {
    _audioPlayer = new AudioPlayer();

    _audioPlayer.setDurationHandler((d) => _duration = d);

    _audioPlayer.setPositionHandler((p) => _position = p);

    _audioPlayer.setCompletionHandler(() {
      _onComplete();
      _position = _duration;
    });

    _audioPlayer.setErrorHandler((msg) {
      _playerState = PlayerState.stopped;
      _duration = new Duration(seconds: 0);
      _position = new Duration(seconds: 0);
    });
  }

  void _onComplete() {
    _playerState = PlayerState.stopped;
    /* Callback to completedState */
    _localSound.completedState(_localSound);
  }

  Future<ByteData> _loadAsset(CustomSound sound) async {
    return await rootBundle.load('sounds/${sound.fileName}.ogg');
  }

  Future _playLocal(String filePath) async {
    final result = await _audioPlayer.play(filePath, isLocal: true);
    if (result == 1) _playerState = PlayerState.playing;
  }

  Future _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1) _playerState = PlayerState.paused;
  }

  Future _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      _playerState = PlayerState.stopped;
      _position = new Duration();
    }
  }

  void stopAudio() async {
    _localSound = null;
    _stop();
  }

  void pauseAudio() async {
    _pause();
  }

  void playAudio(CustomSound sound) async {
    final file = new File(
        '${(await getTemporaryDirectory()).path}/${sound.fileName}.mp3');
    await file.writeAsBytes((await _loadAsset(sound)).buffer.asUint8List());

    if (sound == _localSound && isPlaying) {
      _stop();
    } else if (isPlaying) {
      _stop();
    }
    _localSound = sound;

    _playLocal(file.path);
  }
}

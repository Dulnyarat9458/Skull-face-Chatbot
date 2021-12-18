import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:dialogflow_grpc/dialogflow_grpc.dart';
import 'package:dialogflow_grpc/generated/google/cloud/dialogflow/v2beta1/session.pb.dart';

DialogflowGrpcV2Beta1? dialogflow;

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();

  bool _isRecording = false;
  bool _isComposing = false;
  final RecorderStream _recorder = RecorderStream();
  late StreamSubscription _recorderStatus;
  late StreamSubscription<List<int>> _audioStreamSubscription;
  late BehaviorSubject<List<int>> _audioStream;

  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  @override
  void dispose() {
    _recorderStatus.cancel();
    _audioStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted) {
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
      }
    });

    await Future.wait([_recorder.initialize()]);

    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/credentials.json'))}');

    dialogflow = DialogflowGrpcV2Beta1.viaServiceAccount(serviceAccount);
  }

  void stopStream() async {
    await _recorder.stop();
    await _audioStreamSubscription.cancel();
    await _audioStream.close();
  }

  void handleSubmitted(text) async {
    print(text);
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    ChatMessage message = ChatMessage(
      text: text,
      name: "You",
      type: true,
    );

    setState(() {
      _messages.insert(0, message);
    });

    DetectIntentResponse data = await dialogflow!.detectIntent(text, 'en-US');
    String fulfillmentText = data.queryResult.fulfillmentText;
    if (fulfillmentText.isNotEmpty) {
      ChatMessage botMessage = ChatMessage(
        text: fulfillmentText,
        name: "Bot",
        type: false,
      );

      setState(() {
        _messages.insert(0, botMessage);
      });
    }
  }

  void handleStream() async {
    _recorder.start();

    _audioStream = BehaviorSubject<List<int>>();
    _audioStreamSubscription = _recorder.audioStream.listen((data) {
      print(data);
      _audioStream.add(data);
    });

    
    var biasList = SpeechContextV2Beta1(phrases: [
      'Dialogflow CX',
      'Dialogflow Essentials',
      'Action Builder',
      'HIPAA'
    ], boost: 20.0);

    // See: https://cloud.google.com/dialogflow/es/docs/reference/rpc/google.cloud.dialogflow.v2#google.cloud.dialogflow.v2.InputAudioConfig
    var config = InputConfigV2beta1(
        encoding: 'AUDIO_ENCODING_LINEAR_16',
        languageCode: 'en-US',
        sampleRateHertz: 16000,
        singleUtterance: false,
        speechContexts: [biasList]);

    final responseStream =
        dialogflow!.streamingDetectIntent(config, _audioStream);
   
    responseStream.listen((data) {
    
      setState(() {
        
        String transcript = data.recognitionResult.transcript;
        String queryText = data.queryResult.queryText;
        String fulfillmentText = data.queryResult.fulfillmentText;

        if (fulfillmentText.isNotEmpty) {
          ChatMessage message = ChatMessage(
            text: queryText,
            name: "You",
            type: true,
          );

          ChatMessage botMessage = ChatMessage(
            text: fulfillmentText,
            name: "Bot",
            type: false,
          );

          _messages.insert(0, message);
          _textController.clear();
          _messages.insert(0, botMessage);
        }
        if (transcript.isNotEmpty) {
          _textController.text = transcript;
        }
      });
    }, onError: (e) {
      //print(e);
    }, onDone: () {
      //print('done');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b1b1b),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xffb59a57)),
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Skull Face",
              style: GoogleFonts.marcellus(),
            ),
            if (_isRecording)
              Text(
                "Recording",
                style: GoogleFonts.marcellus(color: Color(0xffb59a57)),
              ),
          ],
        ),
      ),
      body: Column(children: <Widget>[
        Flexible(
            child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          reverse: true,
          itemBuilder: (_, int index) => _messages[index],
          itemCount: _messages.length,
        )),
        const Divider(height: 1.0),
        Container(
            decoration: BoxDecoration(
              color: const Color(0xff242323),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.1),
                  offset: const Offset(-1, -1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.only(
                          left: 12, right: 8, top: 12, bottom: 12),
                      margin: const EdgeInsets.only(
                          left: 12, right: 8, top: 8, bottom: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xff181818),
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: handleSubmitted,
                        onChanged: (String text) {
                          setState(() {
                            _isComposing = text.isNotEmpty; //new
                          });
                        },
                        decoration: InputDecoration.collapsed(
                            hintStyle: GoogleFonts.marcellus(
                                fontSize: 16.0, color: const Color(0xff5b5b5b)),
                            hintText: "Send a message"),
                        style: const TextStyle(
                            fontSize: 16.0, color: Colors.white70),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: IconButton(
                      color: const Color(0xffb59a57),
                      icon: const Icon(Icons.send),
                      onPressed: _isComposing
                          ? () => {
                                handleSubmitted(_textController.text),
                                print("object")
                              }
                          : null,
                    ),
                  ),
                  GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(1000),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xff161616).withOpacity(0.5),
                            offset: Offset(2, 2),
                            spreadRadius: 4,
                            blurRadius: 2,
                          ),
                          BoxShadow(
                            color: Color(0xff3b3a3a).withOpacity(0.3),
                            offset: Offset(-1.5, -1.5),
                            spreadRadius: 4,
                            blurRadius: 2,
                          )
                        ],
                      ),
                      margin: EdgeInsets.all(4),
                      padding: EdgeInsets.all(14),
                      child: const Icon(
                        Icons.mic,
                        color: Color(0xffb59a57),
                      ),
                    ),
                    onLongPressStart: (_) {
                      print("กด");
                      handleStream();
                    },
                    onLongPressCancel: () {
                      //r      print("ปล่อย");
                    },
                    onLongPressEnd: (_) {
                      print("ปล่อย");
                      stopStream();
                    },
                  ),
                ],
              ),
            )),
      ]),
    );
  }
}

class ChatMessage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ChatMessage(
      {required this.text, required this.name, required this.type});

  final String text;
  final String name;
  final bool type;

  List<Widget> otherMessage(context) {
    return <Widget>[
      Container(
        margin: const EdgeInsets.only(right: 4.0),
        padding: const EdgeInsets.only(top: 12.0),
        child: CircleAvatar(
          child: ClipOval(
            child: Image.asset(
              'assets/skull.jpg',
              alignment: Alignment.center,
            ),
          ),
          backgroundColor: Colors.black54,
        ),
      ),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(5.0),
              child: Text(
                text,
                style: GoogleFonts.marcellus(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> myMessage(context) {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(
                color: Color(0xffb49957),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Text(
                text,
                style:
                    GoogleFonts.marcellus(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: type ? myMessage(context) : otherMessage(context),
      ),
    );
  }
}

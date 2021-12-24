//@dart=2.9
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key key,
    @required this.title,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final uploader = FlutterUploader();
  int _progress = 0;
  StreamSubscription<UploadTaskProgress> _progressSub;
  StreamSubscription<UploadTaskResponse> _resultSub;

  void _setProgress(int progress) {
    setState(() {
      _progress = progress;
    });
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('Progress $_progress'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          FilePickerResult result = await FilePicker.platform.pickFiles();
          if (result == null) {
            return;
          }

          final file = result.files[0];
          final filename = file.name;
          final savedDir = file.path;

          final splited = savedDir.split('/');
          final filtered = splited.take(splited.length - 1).join('/');
          print('Filename $filename, dir $savedDir');

          final url =
              "https://quittercheck.blob.core.windows.net/quittercheck/$filename?sp=racwd&st=2021-12-24T10:34:17Z&se=2021-12-31T18:34:17Z&sv=2020-08-04&sr=c&sig=nMCBpUgZ5Y5SYF4sGdpEhWeI4DXnz%2B6p5sgMCCadKnE%3D";
          final client = HttpClient();
          await client.putUrl(Uri.parse(url)).then((req) {
            req.headers.add("x-ms-version", "2020-04-08");
            req.headers.add("x-ms-blob-type", "AppendBlob");
            req.headers.add("Content-Length", "0");
            req.headers.add('Content-Type', "image/jpeg");

            return req.close();
          }).then((response) => print('Response ${response.statusCode}'));

          final taskId = uploader.enqueue(
            url: '$url&comp=appendblock',
            files: [
              FileItem(
                filename: filename,
                savedDir: filtered,
                fieldname: "file",
              )
            ],
            method: UploadMethod.PUT,
            headers: {
              "x-ms-version": "2020-04-08",
              "x-ms-blob-type": "AppendBlob",
              'Content-Type': 'image/jpeg',
            },
            showNotification: false,
            tag: "upload 1",
          );
          _progressSub = uploader.progress.listen((event) {
            print('Progress ${event.progress}');
            _setProgress(event.progress);
          });

          _resultSub = uploader.result.listen((event) {
            print('Result ${event.status.value}');
          });
        },
      ),
    );
  }
}

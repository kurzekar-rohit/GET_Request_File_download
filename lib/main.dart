import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:simple_permissions/simple_permissions.dart';
import 'package:file_utils/file_utils.dart';
import 'dart:math';

class Album {
  Album({
    this.value,
    this.message,
    this.data,
  });

  String value;
  String message;
  List<String> data;

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        value: json["value"],
        message: json["message"],
        data: List<String>.from(json["data"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "value": value,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x)),
      };
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Future<Album> futureAlbum;
  List usersData;
  var imgUrl;
  var filename;
  bool downloading = false;
  var progress = "";
  var path = "No Data";
  var platformVersion = "Unknown";
  Permission permission1 = Permission.WriteExternalStorage;
  static final Random random = Random();

  @override
  void initState() {
    super.initState();
    // futureAlbum =
    fetchAlbum();
  }

  Future<Album> fetchAlbum() async {
    final response = await http.get(
        'https://goodmove.cloud/flutter_android_medical/api_getdownloadfile.php?action=DOWNLOAD_FILES');
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body)['data'];
      print('This is data value: $data');
      // print("This is Response: ${response.body}");
      setState(() {
        usersData = data;
      });
      return Album.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load album');
    }
  }

  Future<void> downloadFile() async {
    Dio dio = Dio();
    bool checkPermission1 =
        await SimplePermissions.checkPermission(permission1);
    // print(checkPermission1);
    if (checkPermission1 == false) {
      await SimplePermissions.requestPermission(permission1);
      checkPermission1 = await SimplePermissions.checkPermission(permission1);
    }
    if (checkPermission1 == true) {
      String dirloc = "";
      if (Platform.isAndroid) {
        dirloc = "/sdcard/download/";
      } else {
        dirloc = (await getApplicationDocumentsDirectory()).path;
      }

      var randid = random.nextInt(10000);

      try {
        FileUtils.mkdir([dirloc]);
        await dio.download(imgUrl, dirloc + filename,
            onReceiveProgress: (receivedBytes, totalBytes) {
          // setState(() {
          //   downloading = true;
          //   progress =
          //       ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
          // });
        });
      } catch (e) {
        print(e);
      }

      // setState(() {
      //   downloading = false;
      //   progress = "Download Completed.";
      //   path = dirloc + randid.toString() + ".jpg";
      // });
    } else {
      // setState(() {
      //   progress = "Permission Denied!";
      //   // _onPressed = () {
      //   //   downloadFile();
      //   // };
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Fetch Data Example'),
        ),
        body: Center(
          child: Container(
            child: usersData != null
                ? ListView.builder(
                    itemCount: usersData.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(usersData[index]['filename']),
                          trailing: Icon(Icons.download_rounded),
                          onTap: () {
                            imgUrl = usersData[index]['url'];
                            filename = usersData[index]['filename'];
                            print('This is variable URL $imgUrl');
                            downloadFile();
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),

        //     Center(
        //   child: FutureBuilder<Album>(
        //     future: futureAlbum,
        //     builder: (context, snapshot) {
        //       if (snapshot.hasData) {
        //         return Text(snapshot.data.data[1]);
        //       } else if (snapshot.hasError) {
        //         return Text("${snapshot.error}");
        //       }

        //       // By default, show a loading spinner.
        //       return CircularProgressIndicator();
        //     },
        //   ),
        // ),
      ),
    );
  }
}

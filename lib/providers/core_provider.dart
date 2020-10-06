import 'package:crm/util/consts.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crm/database/CallLogsModel.dart';
import 'package:crm/database/RecordingsModel.dart';
import 'package:crm/database/database.dart';
import 'package:http/http.dart' as http;
import 'package:crm/util/file_utils.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as pathlib;
import 'package:call_log/call_log.dart';
import 'package:http_parser/http_parser.dart';

import 'dart:io';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CoreProvider extends ChangeNotifier {
  bool loading = false;
  bool globalLoader = false;

  // check sync status
  bool recordingSyncing = false;
  bool callsSyncing = false;

  //recording var
  List<FileSystemEntity> audio = List();
  List<Recordings> dbFiles = List();

  // call logs var
  // Iterable<CallLogEntry> _callLogEntries = [];
  List<CallLogs> dbLogs = List();

  void setLoading(value) {
    loading = value;
    notifyListeners();
  }

  void setGlobalLoading(value) {
    globalLoader = value;
    notifyListeners();
  }

  void showToast(value) {
    Fluttertoast.showToast(
      msg: value,
      toastLength: Toast.LENGTH_SHORT,
      timeInSecForIos: 1,
    );
    notifyListeners();
  }

  Future<dynamic> isCurrentUser() async {
    Map<String, dynamic> userData = new Map();

    final prefs = await SharedPreferences.getInstance();
    var user = prefs.getString('currentUser');
    if (user == null) {
      return false;
    } else {
      userData = jsonDecode(user);
      return userData;
    }
  }

  syncRecordings() async {
    if (recordingSyncing == true) {
      return;
    }
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    recordingSyncing = true;
    await getNewFiles();
    List<Recordings> recordings =
        await DBProvider.db.listRecordings(unsynced: true);

    // List list = List();

    // recordings.forEach((e) {
    //   list.add(recordingsToJson(e));
    // });
    print('are we here');

    for (var file in recordings) {
      print(file);
      var item = jsonDecode(recordingsToJson(file));
      var request = http.MultipartRequest(
          "POST", new Uri.http(Constants.apiUrl, "/sync/audios"));

      request.headers['Content-Encoding'] = "audio/mpeg";
      request.headers['Authorization'] = 'Bearer ${user['token']}';
      request.fields["data"] = jsonEncode(item);
      request.files.add(http.MultipartFile.fromBytes(
          'file', new File(item['path']).readAsBytesSync(),
          contentType: MediaType('audio', 'mp3'), filename: item['id']));
      var response = await request.send();
      // print(response);
      if (response.statusCode == 200) {
        print('Uploaded!');
        var dataResponse = await http.post(
            new Uri.http(Constants.apiUrl, "/sync/recordings"),
            body: jsonEncode({'arr': item}),
            headers: {
              "Content-Type": "application/json",
              "Authorization": 'Bearer ${user['token']}'
            });

        if (dataResponse.statusCode == 200) {
          var data = jsonDecode(dataResponse.body)['data'] as List;
          List<Recordings> ids =
              data.map((json) => new Recordings(id: json['id'])).toList();

          DBProvider.db.setRecordingsSync(ids);
        }
      }
    }
    recordingSyncing = false;
  }

  syncCallLogs() async {
    if (callsSyncing == true) {
      return;
    }
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    callsSyncing = true;
    await getLogs();
    List<CallLogs> callLogs = List();
    List list = List();
    var isEmpty = false;
    while (isEmpty == false) {
      callLogs = await DBProvider.db.listCallLogs(unsynced: true);
      if (callLogs.isEmpty == true) {
        isEmpty = true;
      }
      list.clear();
      callLogs.forEach((e) {
        list.add(callLogsToJson(e));
      });
      var body = jsonEncode({"arr": list});

      var response = await http.post(
          new Uri.http(Constants.apiUrl, "/sync/callLogs"),
          body: body,
          headers: {
            "Content-Type": "application/json",
            "Authorization": 'Bearer ${user['token']}'
          });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body)['data'] as List;
        List<CallLogs> ids =
            data.map((json) => new CallLogs(id: json['id'])).toList();

        DBProvider.db.setCallLogsSync(ids);
      } else {}
    }
    callsSyncing = false;
  }

  getAudios(String type, user) async {
    List<String> Allowed = ["mp3", "amr"];

    setLoading(true);
    // var user = await isCurrentUser();
    // if (user == false) {
    // return;
    // }

    audio.clear();
    List<Directory> storages = await FileUtils.getStorageList();
    storages.forEach((dir) {
      String path = dir.path +
          (user['recordingPath'] == null ? "Call" : user['recordingPath']);
      if (Directory(path).existsSync()) {
        List<FileSystemEntity> files =
            FileUtils.getAllFilesInPath(path, showHidden: false);

        files.forEach((file) {
          try {
            String ext = file.path.split("/")[file.path.split("/").length - 1];
            ext = ext.split('.')[ext.split(".").length - 1];

            if (Allowed.contains(ext)) {
              audio.add(file);
            }
          } catch (e) {}

          /* if (mimeType != null) {
            if (mimeType.split("/")[0] == type) {
              audio.add(file);
            } else {
              print('file is not our type');
            }
          } else {
            print('mimetyoe is null');
          }*/
        });
      } else {
        print(user['recordingPath'] + " folder doesnt exists");
      }
    });
    setLoading(false);
  }

  getNewFiles() async {
    // Directory dir = Directory('${path}/Download');
    // setLoading(true);
    dbFiles.clear();
    var user = await isCurrentUser();
    if (user == false) {
      return;
    }
    await getAudios('audio', user);

    for (FileSystemEntity file in audio) {
      var title = pathlib.basename(file.path);
      var time = new File(file.path).lastModifiedSync();
      debugPrint('${time}');
      dbFiles.add(recordingsFromJson({
        'title': title,
        'path': file.path,
        'isSynced': false,
        'createdAt': time,
        'size': FileUtils.formatBytes(
            file == null ? 678476 : File(file.path).lengthSync(), 2),
        'formatedTime': file == null
            ? "Test"
            : FileUtils.formatTime(
                File(file.path).lastModifiedSync().toIso8601String()),
        'roNumber': user['mobileNo']
      }));
    }
    try {
      await DBProvider.db.addRecordings(dbFiles);
    } catch (exception) {
      print("");
    }
  }

  getLogs() async {
    var latestRecord = await DBProvider.db.getlatestDateCallLog();
    // dynamic tt = DateTime.parse(latestRecord.createAt);
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> userData = new Map();

    var user = prefs.getString('currentUser');
    if (user == null) {
      return false;
    } else {
      userData = jsonDecode(user);
    }
    dbLogs.clear();
    var now = latestRecord == null
        ? DateTime.now().subtract(Duration(days: 7))
        : latestRecord.createdAt;
    // tt = tt.millisecondsSinceEpoch;
    int from = now.millisecondsSinceEpoch;
    var result = await CallLog.query(dateFrom: from);
    result.forEach((element) {
      dbLogs.add(callLogsFromJson({
        'dialedNumber': element.number,
        'formatedDialedNumber': element.formattedNumber,
        'isSynced': false,
        'duration': element.duration,
        'roNumber': userData['mobileNo'],
        'callType': userData['callType'],
        'callingTime':
            new DateTime.fromMillisecondsSinceEpoch(element.timestamp),
        'createdAt': new DateTime.now()
      }));
    });
    try {
      await DBProvider.db.addCallLogs(dbLogs);
    } catch (e) {}

    return 0;
  }
}

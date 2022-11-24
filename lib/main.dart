// ignore_for_file: deprecated_member_use, package_api_docs, public_member_api_docs
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
// import 'dart:io' show Platform;
import 'dart:io';
import 'package:http/http.dart' as http;

const String STA_DEFAULT_SSID = "STA_SSID";

void main() => runApp(FlutterWifiIoT());

class FlutterWifiIoT extends StatefulWidget {
  @override
  _FlutterWifiIoTState createState() => _FlutterWifiIoTState();
}

class _FlutterWifiIoTState extends State<FlutterWifiIoT> {
  bool _isEnabled = false;
  bool _isConnected = false;

  final TextStyle textStyle = TextStyle(color: Colors.white);

  @override
  initState() {
    WiFiForIoTPlugin.isEnabled().then((val) {
      _isEnabled = val;
    });

    WiFiForIoTPlugin.isConnected().then((val) {
      _isConnected = val;
    });

    super.initState();
  }

  // isRegisteredWifiNetwork(String ssid) async {
  //   bool bIsRegistered;
  //
  //   try {
  //     bIsRegistered = await WiFiForIoTPlugin.isRegisteredWifiNetwork(ssid);
  //   } on PlatformException {
  //     bIsRegistered = false;
  //   }
  //
  //   setState(() {
  //     _htIsNetworkRegistered![ssid] = bIsRegistered;
  //   });
  // }

  Widget getWidgets() {
    WiFiForIoTPlugin.isConnected().then((val) {
      setState(() {
        _isConnected = val;
      });
    });

    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          children: getButtonWidgets(),
        ),
      ),
    );
    //}
  }

  List<Widget> getButtonWidgets() {
    final List<Widget> htPrimaryWidgets = <Widget>[];

    WiFiForIoTPlugin.isEnabled().then((val) {
      setState(() {
        _isEnabled = val;
      });
    });

    if (_isEnabled) {
      htPrimaryWidgets.add(Text("Wifi Enabled"));
      htPrimaryWidgets.addAll([
        MaterialButton(
          color: Colors.blue,
          child: Text("Connect to IPCAP", style: textStyle),
          onPressed: () {
            connectWifiByName('IPCAP_Z2TM07Z2211123456', '1234321');
          },
        ),
      ]);

      WiFiForIoTPlugin.isConnected().then((val) {
        setState(() {
          _isConnected = val;
        });
      });

      if (_isConnected) {
        htPrimaryWidgets.addAll(<Widget>[
          Text("Connected"),
          FutureBuilder(
              future: WiFiForIoTPlugin.getSSID(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String?> ssid) {
                return Text("SSID: ${ssid.data}");
              }),
          FutureBuilder(
              future: WiFiForIoTPlugin.getIP(),
              initialData: "Loading..",
              builder: (BuildContext context, AsyncSnapshot<String?> ip) {
                return Text("IP : ${ip.data}");
              }),
          MaterialButton(
            color: Colors.blue,
            child: Text("Disconnect", style: textStyle),
            onPressed: () {
              WiFiForIoTPlugin.disconnect();
            },
          ),
          Divider(
            height: 32.0,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('ping camera '),
            onPressed: () {
              // pingCam('172.24.18.190');//R2D2   //172.24.18.175
              pingCam('192.168.10.1');
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.access_time),
            label: const Text('set net @camera to R2D2'),
            onPressed: () => setNetwork('R2D2', 'Rd6k3D0rRt'),
          ),
        ]);
      } else {
        htPrimaryWidgets.addAll(<Widget>[
          Text("Disconnected"),
        ]);
      }
    }

    htPrimaryWidgets.add(Divider(
      height: 32.0,
    ));

    return htPrimaryWidgets;
  }

  @override
  Widget build(BuildContext poContext) {
    return MaterialApp(
      title: "WifiFlutter",
      home: Scaffold(
        appBar: AppBar(
          title: Text('WifiFlutter Example'),
        ),
        body: Column(
          children: [
            getWidgets(),
          ],
        ),
      ),
    );
  }

  // Connect wifi by name(SSID)
  static Future<bool> connectWifiByName(
      String wifiName, String password) async {
    bool _isConnected = false;
    _isConnected = await WiFiForIoTPlugin.connect(wifiName,
        password: password, security: NetworkSecurity.WPA,
        // timeoutInSeconds: 5, withInternet: true
        joinOnce: true);

    if (_isConnected) {
      WiFiForIoTPlugin.forceWifiUsage(true);
      print("Connected");
      return Future.value(true);
    } else {
      print("Failed to connect");
      return Future.value(false);
    }
  }
}

void pingCam(String pingUrl) {
  Socket.connect(pingUrl, 80, timeout: Duration(seconds: 5)).then((socket) {
    print("ping:80 $pingUrl ok = Success");
    socket.destroy();
  }).catchError((error) {
    print("ping:80 $pingUrl timeout = Exception on Socket " + error.toString());
  });
}

void setNetwork(String netName, String netPwd) async { //Future<String>
  // адрес который настроен в камере из коробки либо после сброса
  String urlSet = 'http://192.168.10.1/action/set?subject=wifi';
  final bodyXml =
      '<?xml version="1.0" encoding="utf-8"?><request><wifi><essid>$netName</essid><auth>3</auth><alg>3</alg><password>$netPwd</password></wifi></request>';
  String basicAuth =
      'Basic ' + base64.encode(utf8.encode('admin:admin'));
  final response = await http.post(
    Uri.parse(urlSet),
    headers: <String, String>{'authorization': basicAuth},
    body: bodyXml,
  );
  // Установка новой сети + перезагрузка = по замерам где-то 20 +/- секунд

  // Не ожидается ответа от камеры.
  // if (response.statusCode == 201) {
  //   print(response.body);
  // } else {
  //   throw Exception('Failed to set new wi-fi');
  // }
}

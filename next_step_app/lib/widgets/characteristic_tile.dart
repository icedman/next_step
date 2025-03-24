import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import "../utils/snackbar.dart";

import "descriptor_tile.dart";

class CharacteristicTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;

  const CharacteristicTile(
      {Key? key, required this.characteristic, required this.descriptorTiles})
      : super(key: key);

  @override
  State<CharacteristicTile> createState() => _CharacteristicTileState();
}

class _CharacteristicTileState extends State<CharacteristicTile> {
  List<int> _value = [];

  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();
    _lastValueSubscription =
        widget.characteristic.lastValueStream.listen((value) {
      _value = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _lastValueSubscription.cancel();
    super.dispose();
  }

  BluetoothCharacteristic get c => widget.characteristic;

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  Future onReadPressed() async {
    try {
      await c.read();
      Snackbar.show(ABC.c, "Read: Success", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Read Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }

  Future onWritePressed() async {
    try {
      await c.write(_getRandomBytes(),
          withoutResponse: c.properties.writeWithoutResponse);
      Snackbar.show(ABC.c, "Write: Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }

  Future onSubscribePressed() async {
    try {
      // String op = c.isNotifying == false ? "Subscribe" : "Unubscribe";
      String op = c.isNotifying == false ? "Start" : "Stop";
      await c.setNotifyValue(c.isNotifying == false);
      Snackbar.show(ABC.c, "$op : Success", success: true);
      if (c.properties.read) {
        await c.read();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Subscribe Error:", e),
          success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }

  Widget buildUuid(BuildContext context) {
    String uuid = '0x${widget.characteristic.uuid.str.toUpperCase()}';
    return Text(uuid, style: TextStyle(fontSize: 13));
  }

  Widget buildValue(BuildContext context) {
    // String data = _value.toString();
    String data = new String.fromCharCodes(_value);
    return Text(data, style: TextStyle(fontSize: 13, color: Colors.grey));
  }

  Widget buildColor(BuildContext context) {
    // String data = _value.toString();
    String data = new String.fromCharCodes(_value);
    List<String> items = data.replaceAll('cm', '').split('|');

    Widget widget = Container(color: Colors.pink);

    if (items.length == 2) {
      double? c1 = double.tryParse(items[0]);
      double? c2 = double.tryParse(items[1]);

      if (c1 != null && c2 != null && c1 > 0 && c2 > 0) {
        if (c1 > 10 && c2 < 10) {
          print('red');
          widget = Container(color: Colors.red);
        } else if (c1 < 10 && c2 < 10) {
          print('green');
          widget = Container(color: Colors.green);
        } else if (c2 > 10) {
          print('yellow');
          widget = Container(color: Colors.yellow);
        }
      }
    }

    // return Text(data, style: TextStyle(fontSize: 13, color: Colors.grey));
    // return Container(color: Colors.pink);
    const double sz = 200;

    return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: sz,
          minHeight: sz,
          maxWidth: sz,
          maxHeight: sz,
        ),
        child: widget);
  }

  Widget buildReadButton(BuildContext context) {
    return TextButton(
        child: Text("Read"),
        onPressed: () async {
          await onReadPressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Widget buildWriteButton(BuildContext context) {
    bool withoutResp = widget.characteristic.properties.writeWithoutResponse;
    return TextButton(
        child: Text(withoutResp ? "WriteNoResp" : "Write"),
        onPressed: () async {
          await onWritePressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Widget buildSubscribeButton(BuildContext context) {
    bool isNotifying = widget.characteristic.isNotifying;
    return TextButton(
        // child: Text(isNotifying ? "Unsubscribe" : "Subscribe"),
        child: Text(isNotifying ? "Stop" : "Start"),
        onPressed: () async {
          await onSubscribePressed();
          if (mounted) {
            setState(() {});
          }
        });
  }

  Widget buildButtonRow(BuildContext context) {
    bool read = widget.characteristic.properties.read;
    bool write = widget.characteristic.properties.write;
    bool notify = widget.characteristic.properties.notify;
    bool indicate = widget.characteristic.properties.indicate;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (read) buildReadButton(context),
        if (write) buildWriteButton(context),
        if (notify || indicate) buildSubscribeButton(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isNotifying = widget.characteristic.isNotifying;
    return ExpansionTile(
      title: ListTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // const Text('Characteristic'),
            // buildUuid(context),
            buildValue(context),
            if (isNotifying) buildColor(context),
          ],
        ),
        subtitle: buildButtonRow(context),
        contentPadding: const EdgeInsets.all(0.0),
      ),
      children: widget.descriptorTiles,
    );
  }
}

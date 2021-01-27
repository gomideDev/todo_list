import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final todoController = TextEditingController();
  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> saveData() async {
    String data = json.encode(_todoList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();

      newTodo['title'] = todoController.text;
      todoController.text = '';
      newTodo['ok'] = false;
      _todoList.add(newTodo);
      saveData();
    });
  }

  @override
  void initState() {
    readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 1),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: todoController,
                  decoration: InputDecoration(
                      labelText: 'Nova tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                )),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10),
                    itemCount: _todoList.length,
                    itemBuilder: bildItem,
                  ),
                  onRefresh: refresh))
        ],
      ),
    );
  }

  Future<Null> refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });
      saveData();
    });
    return null;
  }

  Widget bildItem(context, index) {
    return Dismissible(
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);
          saveData();
        });
        final snack = SnackBar(
          content: Text('Tarefa \"${_lastRemoved['title']}\" removida!'),
          action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);
                  saveData();
                });
              }),
          duration: Duration(seconds: 2),
        );

        Scaffold.of(context).showSnackBar(snack);
      },
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
          alignment: Alignment(-0.9, 0),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (value) {
          setState(() {
            _todoList[index]['ok'] = value;
            saveData();
          });
        },
        value: _todoList[index]['ok'],
        title: Text(_todoList[index]['title']),
        secondary: CircleAvatar(
          child: Icon(
            _todoList[index]['ok'] ? Icons.check : Icons.error,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(Todo());
}

class Todo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TodoList());
  }
}

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  // save data
  final Map<String, bool> _todoList = {};
  // text field
  final TextEditingController _textFieldController = TextEditingController();

  late SharedPreferences prefs;

  /// on state initialization read the current todo list values from shared_preferences
  /// which are localStorage on the web.
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      this.prefs = prefs;
      final todos = this.prefs.getKeys();

      // read the values from shared_preferences and update the state,
      // TODO: I'm sure there's a more effective way to update the state all at once instead of for each item.
      for (String title in todos) {
        setState(() {
          _todoList.putIfAbsent(title, () => prefs.getBool(title) as bool);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List')),
      body: ListView(children: _getItems()),
      // add items to the to-do list
      floatingActionButton: FloatingActionButton(
          onPressed: () => _displayDialog(context),
          tooltip: 'Add Item',
          child: const Icon(Icons.add)),
    );
  }

  void _addTodoItem(String title) async {
    // Wrapping it inside a set state will notify
    // the app that the state has changed
    await prefs.setBool(title, false);
    setState(() {
      _todoList.putIfAbsent(title, () => false);
    });
    _textFieldController.clear();
  }

  // this Generate list of item widgets
  Widget _buildTodoItem(String title, bool complete) {
    return Card(
        child: ListTile(
            leading: IconButton(
              icon: !complete
                  ? const Icon(Icons.check_box_outline_blank)
                  : const Icon(Icons.check_box),
              onPressed: () async {
                // null check, use the value in the map if it isn't null, false otherwise
                final currentComplete = _todoList[title] ?? false;
                // update the state with the opposite to allow checking and unchecking tasks
                await prefs.setBool(title, !currentComplete);

                // update state to trigger re-draw
                setState(() {
                  _todoList.update(title, (value) => !value);
                });
              },
            ),
            title: SelectableText(title,
                style: complete
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // delete the item from storage
                await prefs.remove(title);
                // update state to trigger re-draw
                setState(() {
                  _todoList.remove(title);
                });
              },
            )));
  }

  // display a dialog for the user to enter items
  Future<void> _displayDialog(BuildContext context) async {
    // alter the app state to show a dialog
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a task to your list'),
            content: TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: 'Enter task here'),
              // allow pressing enter to add a new item
              onSubmitted: (title) {
                Navigator.of(context).pop();
                _addTodoItem(title);
              },
            ),
            actions: <Widget>[
              // add button
              TextButton(
                child: const Text('ADD'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _addTodoItem(_textFieldController.text);
                },
              ),
              // Cancel button
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  // iterates through our todo list title
  List<Widget> _getItems() {
    final List<Widget> _todoWidgets = <Widget>[];
    _todoList.forEach((title, complete) {
      _todoWidgets.add(_buildTodoItem(title, complete));
    });
    return _todoWidgets;
  }
}

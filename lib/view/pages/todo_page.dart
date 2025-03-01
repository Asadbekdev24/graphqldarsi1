import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  final String getTodosQuery = '''
    query Todos {
      todos {
        id
        title
        description
        completed
      }
    }
  ''';

  final String deleteTodoMutation = '''
    mutation DeleteTodo(\$id: ID!) {
      deleteTodo(id: \$id)
    }
  ''';

  final String addTodoMutation = '''
    mutation AddTodo(\$title: String!, \$description: String!) {
      addTodo(title: \$title, description: \$description) {
        id
        title
        description
      }
    }
  ''';

  final String updateTodoMutation = '''
    mutation UpdateTodo(\$id: ID!, \$title: String, \$description: String, \$completed: Boolean) {
      updateTodo(id: \$id, title: \$title, description: \$description, completed: \$completed) {
        id
        title
        description
        completed
      }
    }
  ''';

  void _showAddTodoDialog(BuildContext context, VoidCallback refetch,
      {Map? todo}) {
    titleController.text = todo?['title'] ?? "";
    descriptionController.text = todo?['description'] ?? "";
    bool isEditing = todo != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? "Todo'ni tahrirlash" : "Yangi Todo qo'shish"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Sarlavha"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Tavsif"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Bekor qilish"),
            ),
            Mutation(
              options: MutationOptions(
                document: gql(isEditing ? updateTodoMutation : addTodoMutation),
                onCompleted: (dynamic resultData) {
                  refetch();
                  Navigator.pop(context);
                },
              ),
              builder: (RunMutation runMutation, QueryResult? result) {
                return TextButton(
                  onPressed: () {
                    runMutation({
                      'id': todo?['id'],
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'completed': todo?['completed'] ?? false,
                    });
                  },
                  child: Text(isEditing ? "Yangilash" : "Qo'shish"),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(getTodosQuery)),
      builder: (QueryResult result, {fetchMore, refetch}) {
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(title: Text("Xatolik")),
            body: Center(
              child: Text("Xatolik: ${result.exception.toString()}"),
            ),
          );
        }

        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text("Yuklanmoqda...")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List todos = result.data?['todos'] ?? [];
        log("Todos: $todos");
        

        return Scaffold(
          appBar: AppBar(title: Text("📋 Todo Ro'yxati")),
          body: ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];

              return Card(
                child: ListTile(
                  leading: Mutation(
                    options: MutationOptions(
                      document: gql(updateTodoMutation),
                      onCompleted: (dynamic resultData) {
                        refetch?.call();
                      },
                    ),
                    builder: (RunMutation runMutation, QueryResult? result) {
                      return Checkbox(
                        value: todo["completed"],
                        onChanged: (value) {
                          runMutation({
                            'id': todo['id'],
                            'completed': value,
                          });
                        },
                      );
                    },
                  ),
                  title: Text(todo['title'], style: TextStyle(fontSize: 18)),
                  subtitle: Text(todo['description']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAddTodoDialog(context, refetch!, todo: todo),
                      ),
                      Mutation(
                        options: MutationOptions(
                          document: gql(deleteTodoMutation),
                          onCompleted: (dynamic resultData) {
                            refetch?.call();
                          },
                        ),
                        builder:
                            (RunMutation runMutation, QueryResult? result) {
                          return IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              runMutation({'id': todo['id']});
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              _showAddTodoDialog(context, refetch!);
            },
          ),
        );
      },
    );
  }
}

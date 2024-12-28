import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:todo/model/todo_model.dart';
import 'package:todo/services/database_service.dart';

class CompletedWidget extends StatefulWidget {
  const CompletedWidget({super.key});

  @override
  State<CompletedWidget> createState() => _CompletedWidgetState();
}

class _CompletedWidgetState extends State<CompletedWidget> {
  User? user = FirebaseAuth.instance.currentUser;
  late String uid;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
      stream: _databaseService.completedtodos,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Todo> todos = snapshot.data!;
          return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todos.length,
              itemBuilder: (context, index) {
                Todo todo = todos[index];
                final DateTime dt = todo.due.toDate();
                return Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Slidable(
                      key: ValueKey(todo.id),
                      startActionPane:
                          ActionPane(motion: DrawerMotion(), children: [
                        SlidableAction(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            // label: 'Delete',
                            onPressed: (context) async {
                              _databaseService.deleteTodoTask(
                                todo.id,
                              );
                            })
                      ]),
                      child: ListTile(
                          title: Text(
                            todo.title,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            todo.description,
                            // style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            "Due ${formatRelativeTime(dt)}",
                            // style: TextStyle(fontWeight: FontWeight.bold),
                          ))),
                );
              });
        } else {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }
      },
    );
  }
}

String formatRelativeTime(DateTime date) {
  final difference = date.difference(DateTime.now());

  if (difference.inDays > 1) {
    return 'in ${difference.inDays} days';
  } else if (difference.inDays == 1) {
    return 'tomorrow';
  } else if (difference.inHours > 1) {
    return 'in ${difference.inHours} hours';
  } else if (difference.inHours == 1) {
    return 'in an hour';
  } else if (difference.inMinutes > 1) {
    return 'in ${difference.inMinutes} minutes';
  } else if (difference.inMinutes == 1) {
    return 'in a minute';
  } else if (difference.isNegative) {
    // Past time
    final pastDifference = DateTime.now().difference(date);
    if (pastDifference.inDays > 1) {
      return '${pastDifference.inDays} days ago';
    } else if (pastDifference.inHours > 1) {
      return '${pastDifference.inHours} hours ago';
    } else if (pastDifference.inMinutes > 1) {
      return '${pastDifference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  } else {
    return 'just now';
  }
}

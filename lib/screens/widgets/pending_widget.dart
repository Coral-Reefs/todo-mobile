import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:todo/model/todo_model.dart';
import 'package:todo/notifications/notification_service.dart';
import 'package:todo/services/database_service.dart';

class PendingWidget extends StatefulWidget {
  const PendingWidget({super.key});

  @override
  State<PendingWidget> createState() => _PendingWidgetState();
}

class _PendingWidgetState extends State<PendingWidget> {
  User? user = FirebaseAuth.instance.currentUser;
  late String uid;
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _scheduleNotification(String taskTitle, DateTime dueDate) async {
    await _notificationService.scheduleNotification(dueDate, taskTitle);
  }

  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
      stream: _databaseService.todos,
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
                      endActionPane:
                          ActionPane(motion: DrawerMotion(), children: [
                        SlidableAction(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            icon: Icons.done,
                            label: 'Mark',
                            onPressed: (context) {
                              _databaseService.updateTodoStatus(todo.id, true);
                            })
                      ]),
                      startActionPane:
                          ActionPane(motion: DrawerMotion(), children: [
                        SlidableAction(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            // label: 'Edit',
                            onPressed: (context) {
                              _showTaskDialog(context, todo: todo);
                            }),
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
                            'Due ${formatRelativeTime(dt)}',
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

  void _showTaskDialog(BuildContext context, {Todo? todo}) {
    final TextEditingController _titleController =
        TextEditingController(text: todo?.title);
    final TextEditingController _descriptionController =
        TextEditingController(text: todo?.description);
    final TextEditingController _dueController = TextEditingController(
        text: todo?.due != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(todo!.due.toDate())
            : '');
    final DatabaseService _databaseService = DatabaseService();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            todo == null ? 'Add Task' : 'Edit Task',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                        labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // Due Date with Calendar Icon
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dueController,
                          decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder()),
                          readOnly: true, // Make the TextField read-only
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());

                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );

                            if (selectedDate != null) {
                              TimeOfDay? selectedTime = await showTimePicker(
                                context: context,
                                initialTime:
                                    TimeOfDay.fromDateTime(DateTime.now()),
                              );

                              if (selectedTime != null) {
                                final DateTime combinedDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );

                                _dueController.text =
                                    DateFormat('yyyy-MM-dd HH:mm').format(
                                        combinedDateTime); // Format date
                              }
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          // Trigger the same date picker dialog when icon is tapped
                          FocusScope.of(context).requestFocus(FocusNode());

                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );

                          if (selectedDate != null) {
                            TimeOfDay? selectedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(DateTime.now()),
                            );

                            if (selectedTime != null) {
                              final DateTime combinedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              _dueController.text =
                                  DateFormat('yyyy-MM-dd HH:mm')
                                      .format(combinedDateTime); // Format date
                            }
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white),
              onPressed: () async {
                final dueDate = _dueController.text.isNotEmpty
                    ? Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm')
                        .parse(_dueController.text))
                    : null;
                if (todo == null) {
                  await _databaseService.addTodoItem(
                    _titleController.text,
                    _descriptionController.text,
                    dueDate!,
                  );
                  _scheduleNotification(
                    _titleController.text,
                    dueDate.toDate(),
                  );
                } else {
                  await _databaseService.updateTodo(
                    todo.id,
                    _titleController.text,
                    _descriptionController.text,
                    dueDate!,
                  );
                  _scheduleNotification(
                    _titleController.text,
                    dueDate.toDate(),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(todo == null ? 'Add' : 'Update'),
            ),
          ],
        );
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

import 'package:cloud_firestore_platform_interface/src/timestamp.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo/model/todo_model.dart';
import 'package:todo/notifications/notification_service.dart';
import 'package:todo/screens/login_screen.dart';
import 'package:todo/screens/widgets/completed_widget.dart';
import 'package:todo/screens/widgets/pending_widget.dart';
import 'package:todo/services/auth_service.dart';
import 'package:todo/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _buttonIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final List<Widget> _widgets = [
    PendingWidget(),
    CompletedWidget(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  Future<void> _scheduleNotification(String taskTitle, DateTime dueDate) async {
    await _notificationService.scheduleNotification(dueDate, taskTitle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d2630),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2630),
        foregroundColor: Colors.white,
        title: const Text('My Todo List'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () async {
                await AuthService().signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton('Pending', 0),
              _buildTabButton('Completed', 1),
            ],
          ),
          const SizedBox(height: 30),
          _widgets[_buttonIndex],
        ]),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          child: const Icon(Icons.add),
          onPressed: () {
            _showTaskDialog(context);
          }),
    );
  }

  Widget _buildTabButton(String label, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          _buttonIndex = index;
        });
      },
      child: Container(
        height: 50,
        width: MediaQuery.of(context).size.width / 2.2,
        decoration: BoxDecoration(
          color: _buttonIndex == index ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: _buttonIndex == index ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: _buttonIndex == index ? Colors.white : Colors.black38,
            ),
          ),
        ),
      ),
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
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Title', _titleController),
                const SizedBox(height: 10),
                _buildTextField('Description', _descriptionController),
                const SizedBox(height: 10),
                _buildDatePicker(_dueController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                  final id = await _databaseService.addTodoItem(
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
                      dueDate!);
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDatePicker(TextEditingController dueController) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: dueController,
            decoration: const InputDecoration(
              labelText: 'Due Date',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              await _selectDateAndTime(dueController);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            await _selectDateAndTime(dueController);
          },
        )
      ],
    );
  }

  Future<void> _selectDateAndTime(TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (selectedTime != null) {
        final DateTime combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        controller.text =
            DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
      }
    }
  }
}

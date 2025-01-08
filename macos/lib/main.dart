import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lksksahijmbyntclyvfq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxrc2tzYWhpam1ieW50Y2x5dmZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQwNzkxODMsImV4cCI6MjA0OTY1NTE4M30.sHyPxZdipjArUrJ2xQvEVy_GZklZ6Kjyp-e44oC28b0',
  );

  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskTrackerHomePage(),
    );
  }
}

class TaskTrackerHomePage extends StatefulWidget {
  const TaskTrackerHomePage({super.key});

  @override
  _TaskTrackerHomePageState createState() => _TaskTrackerHomePageState();
}

class _TaskTrackerHomePageState extends State<TaskTrackerHomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final data = await supabase.from('Tasks').select('*');
    setState(() {
      tasks = data;
    });
  }

  Future<void> addOrEditTask({int? taskId}) async {
    String title = '';
    String priority = 'Medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));

    if (taskId != null) {
      // Fetch existing task details for editing
      final task = tasks.firstWhere((task) => task['id'] == taskId);
      title = task['title'];
      priority = task['priority'];
      dueDate = DateTime.parse(task['due_date']);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(taskId == null ? 'Add Task' : 'Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Task Title'),
                onChanged: (value) => title = value,
                controller: TextEditingController(text: title),
              ),
              DropdownButton<String>(
                value: priority,
                onChanged: (String? newValue) {
                  setState(() {
                    priority = newValue!;
                  });
                },
                items: <String>['Low', 'Medium', 'High']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                onChanged: (value) {
                  dueDate = DateTime.tryParse(value) ?? dueDate;
                },
                controller: TextEditingController(
                    text: dueDate.toIso8601String().split('T')[0]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (taskId == null) {
                  await supabase.from('Tasks').insert({
                    'title': title,
                    'priority': priority,
                    'due_date': dueDate.toIso8601String(),
                    'completed': false,
                  });
                } else {
                  await supabase.from('Tasks').update({
                    'title': title,
                    'priority': priority,
                    'due_date': dueDate.toIso8601String(),
                  }).eq('id', taskId);
                }
                fetchTasks();
                Navigator.of(context).pop();
              },
              child: Text(taskId == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteTask(int taskId) async {
    await supabase.from('Tasks').delete().eq('id', taskId);
    fetchTasks();
  }

  Future<void> toggleCompletion(int taskId, bool value) async {
    await supabase.from('Tasks').update({'completed': value}).eq('id', taskId);
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Tracker"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: tasks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
                    taskId: task['id'],
                    task: task['title'],
                    priority: task['priority'],
                    dueDate: task['due_date'],
                    completed: task['completed'],
                    onToggleCompletion: toggleCompletion,
                    onEdit: addOrEditTask,
                    onDelete: deleteTask,
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final int taskId;
  final String task;
  final String priority;
  final String dueDate;
  final bool completed;
  final Function(int taskId, bool value) onToggleCompletion;
  final Function({int? taskId}) onEdit;
  final Function(int taskId) onDelete;

  const TaskCard({
    super.key,
    required this.taskId,
    required this.task,
    required this.priority,
    required this.dueDate,
    required this.completed,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: (bool? value) {
            if (value != null) {
              onToggleCompletion(taskId, value);
            }
          },
        ),
        title: Text(task),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(priority, style: const TextStyle(color: Colors.red)),
            Text("Due: $dueDate", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => onEdit(taskId: taskId),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                onDelete(taskId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

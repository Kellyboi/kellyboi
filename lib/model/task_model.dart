class Task {
  final int id;
  final String title;
  final String priority;
  final DateTime dueDate;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.completed,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      dueDate: DateTime.parse(json['due_date']),
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'due_date': dueDate.toIso8601String(),
      'completed': completed,
    };
  }
}

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/tasks_cubit.dart';
import 'package:frontend/features/home/pages/home_page.dart';
import 'package:frontend/models/task_model.dart';
import 'package:intl/intl.dart';

class EditTaskPage extends StatefulWidget {
  final TaskModel task;

  const EditTaskPage({super.key, required this.task});

  static MaterialPageRoute route(TaskModel task) =>
      MaterialPageRoute(builder: (context) => EditTaskPage(task: task));

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late Color selectedColor;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(
      text: widget.task.description,
    );
    selectedDate = widget.task.dueAt;
    selectedTime = TimeOfDay(
      hour: widget.task.dueAt.hour,
      minute: widget.task.dueAt.minute,
    );
    selectedColor = widget.task.color;
  }

  // TODO: make it work later
  Future<void> updateTask() async {
    if (formKey.currentState!.validate()) {
      AuthLoggedIn user = context.read<AuthCubit>().state as AuthLoggedIn;

      final DateTime updatedDueAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await context.read<TasksCubit>().updateTask(
        taskId: widget.task.id,
        uid: user.user.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        color: selectedColor,
        token: user.user.token,
        dueAt: updatedDueAt,
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Task"),
        actions: [
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(DateFormat("MM-d-y").format(selectedDate)),
            ),
          ),
        ],
      ),
      body: BlocConsumer<TasksCubit, TasksState>(
        listener: (context, state) {
          if (state is TasksError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is UpdateTaskSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Task updated successfully!")),
            );
            Navigator.pushAndRemoveUntil(
              context,
              HomePage.route(),
              (_) => false,
            );
          }
        },
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: "Title"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Title cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Description",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Description cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ColorPicker(
                      heading: const Text("Select color"),
                      subheading: const Text("Choose shade"),
                      onColorChanged: (Color color) {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      color: selectedColor,
                      pickersEnabled: const {ColorPickerType.wheel: true},
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: Text("Pick Time: ${selectedTime.format(context)}"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await updateTask();
                      },
                      child: const Text(
                        "Update",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repository.dart';
import 'package:frontend/features/home/repository/task_remote_repository.dart';
import 'package:frontend/models/task_model.dart';

part 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit() : super(TasksInitial());
  final taskRemoteRepository = TaskRemoteRepository();
  final taskLocalRepository = TaskLocalRepository();

  Future<void> createNewTask({
    required String title,
    required String description,
    required Color color,
    required String token,
    required String uid,
    required DateTime dueAt,
  }) async {
    try {
      emit(TasksLoading());
      final taskModel = await taskRemoteRepository.createTask(
        uid: uid,
        title: title,
        description: description,
        hexColor: rgbToHex(color),
        token: token,
        dueAt: dueAt,
      );
      await taskLocalRepository.insertTask(taskModel);

      // await scheduleTaskNotification(taskModel);
      // Step 3: Try scheduling the notification separately
      try {
        await scheduleTaskNotification(taskModel);
      } catch (notificationError) {
        debugPrint("Failed to schedule notification: $notificationError");
        // Optionally show a non-blocking snackbar or toast
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text(
              "Task added, but notification couldn't be scheduled.",
            ),
          ),
        );
      }

      emit(AddNewTaskSuccess(taskModel));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> getAllTasks({required String token}) async {
    try {
      emit(TasksLoading());
      final tasks = await taskRemoteRepository.getTasks(token: token);
      emit(GetTasksSuccess(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> syncTasks(String token) async {
    // get all unsynced tasks from our sqlite db
    final unsyncedTasks = await taskLocalRepository.getUnsyncedTasks();
    if (unsyncedTasks.isEmpty) {
      return;
    }

    // talk to our postgresql db to add the new task
    final isSynced = await taskRemoteRepository.syncTasks(
      token: token,
      tasks: unsyncedTasks,
    );
    // change the tasks that were added to the db from 0 to 1
    if (isSynced) {
      for (final task in unsyncedTasks) {
        taskLocalRepository.updateRowValue(task.id, 1);
      }
    }
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required Color color,
    required String token,
    required String uid,
    required DateTime dueAt,
  }) async {
    try {
      emit(TasksLoading());

      final updatedTask = await taskRemoteRepository.updateTask(
        taskId: taskId,
        uid: uid,
        title: title,
        description: description,
        hexColor: rgbToHex(color),
        token: token,
        dueAt: dueAt,
      );

      await taskLocalRepository.updateTask(updatedTask);

      // await scheduleTaskNotification(updatedTask);
      try {
        await scheduleTaskNotification(updatedTask);
      } catch (notificationError) {
        debugPrint("Failed to schedule notification: $notificationError");
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text(
              "Task Updated, but notification couldn't be scheduled.",
            ),
          ),
        );
      }

      emit(UpdateTaskSuccess(updatedTask));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> deleteTask({
    required String taskId,
    required String token,
  }) async {
    try {
      emit(TasksLoading());
      await taskRemoteRepository.deleteTask(taskID: taskId, token: token);
      await taskLocalRepository.deleteTask(taskId);

      // Get the updated list after deletion
      final updatedTasks = await taskRemoteRepository.getTasks(token: token);

      // Emit updated task list
      emit(GetTasksSuccess(updatedTasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}

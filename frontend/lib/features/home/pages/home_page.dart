import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/tasks_cubit.dart';
import 'package:frontend/features/home/pages/add_new_task_page.dart';
import 'package:frontend/features/home/pages/edit_task_page.dart'; // <-- Make sure this is imported
import 'package:frontend/features/home/pages/profile_page.dart';
import 'package:frontend/features/home/widgets/date_selector.dart';
import 'package:frontend/features/home/widgets/task_card.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const HomePage());
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;

      if (authState is AuthLoggedIn) {
        final user = authState.user;

        context.read<TasksCubit>().getAllTasks(token: user.token);

        Connectivity().onConnectivityChanged.listen((data) async {
          if (data.contains(ConnectivityResult.wifi)) {
            await context.read<TasksCubit>().syncTasks(user.token);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(left: 50),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, ProfilePage.route());
                  },
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoggedIn) {
                        return CircleAvatar(
                          radius: 19,
                          backgroundImage:
                              state.user.profileImage != null &&
                                      state.user.profileImage!.isNotEmpty
                                  ? NetworkImage(state.user.profileImage!)
                                  : const AssetImage(
                                        "assets/imgs/default_avatar.jpg",
                                      )
                                      as ImageProvider,
                        );
                      }
                      return const CircleAvatar(
                        radius: 19,
                        backgroundImage: AssetImage(
                          "assets/imgs/default_avatar.jpg",
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthCubit>().logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasksError) {
            return Center(child: Text(state.error));
          }

          if (state is GetTasksSuccess) {
            final tasks =
                state.tasks
                    .where(
                      (task) =>
                          DateFormat("d").format(task.dueAt) ==
                              DateFormat("d").format(selectedDate) &&
                          selectedDate.month == task.dueAt.month &&
                          selectedDate.year == task.dueAt.year,
                    )
                    .toList();

            return Column(
              children: [
                DateSelector(
                  selectedDate: selectedDate,
                  onTap: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Dismissible(
                        key: Key(
                          task.id,
                        ), // Make sure each task has a unique id
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          final authState = context.read<AuthCubit>().state;
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          ); // capture before await

                          if (authState is AuthLoggedIn) {
                            await context.read<TasksCubit>().deleteTask(
                              taskId: task.id,
                              token: authState.user.token,
                            );

                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Task Completed!')),
                            );
                          }
                        },

                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    EditTaskPage.route(task),
                                  );
                                },
                                child: TaskCard(
                                  color: task.color,
                                  headerText: task.title,
                                  descriptionText: task.description,
                                ),
                              ),
                            ),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: strengthenColor(task.color, 0.69),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                DateFormat.jm().format(task.dueAt),
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, AddNewTaskPage.route());
        },
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

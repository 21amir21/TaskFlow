import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const ProfilePage());
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              // CircleAvatar(
              //   radius: 50,
              //   backgroundImage: AssetImage(
              //     "assets/imgs/Amir.jpeg", // (optional) If user profile picture path comes later, replace this with NetworkImage(user.image)
              //   ),
              // ),
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : AssetImage("assets/imgs/default_avatar.jpg")
                            as ImageProvider,
              ),
              const SizedBox(height: 10),

              // User Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Email
              Text(
                user.email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  // Handle Edit Profile action
                },
                child: const Text("Edit Profile"),
              ),
              const SizedBox(height: 30),
              const Divider(),
              _buildProfileOption(
                icon: Icons.lock,
                text: "Change Password",
                onTap: () {},
              ),
              _buildProfileOption(
                icon: Icons.logout,
                text: "Logout",
                onTap: () {
                  context.read<AuthCubit>().logout(context);
                },
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black),
      title: Text(text, style: TextStyle(color: color ?? Colors.black)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}

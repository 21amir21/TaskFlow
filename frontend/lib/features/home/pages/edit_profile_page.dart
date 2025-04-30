import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const EditProfilePage());

  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;
  UserModel? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthCubit>().state;

    if (authState is AuthLoggedIn) {
      _user = authState.user;
      _nameController.text = _user!.name;
      _emailController.text = _user!.email;
    }
  }

  // Function to handle image removal
  void _removeImage() async {
    setState(() {
      _pickedImage = null; // Remove the image
    });

    try {
      await context.read<AuthCubit>().removeProfileImage();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to remove image: $e")));
    }
  }

  // Function to handle the profile update
  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedName = _nameController.text;
      final updatedEmail = _emailController.text;

      try {
        // Call the AuthCubit to update the user profile
        await context.read<AuthCubit>().updateProfile(
          updatedName,
          updatedEmail,
        );
      } catch (e) {
        // Handle any error in the profile update process
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );

          // Navigate to profile page after successful update
          Navigator.pop(context);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Avatar (Profile Image)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (_user != null &&
                                            _user!.profileImage != null &&
                                            _user!.profileImage!.isNotEmpty
                                        ? NetworkImage(_user!.profileImage!)
                                        : const AssetImage(
                                          "assets/imgs/default_avatar.jpg",
                                        ))
                                    as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Simple email validation
                    final emailRegex = RegExp(r'\S+@\S+\.\S+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Save changes button
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateProfile();
                    },
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

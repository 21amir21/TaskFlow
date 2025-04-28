import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch current user data and set it to the controllers
    final authState = context.read<AuthCubit>().state;

    if (authState is AuthLoggedIn) {
      final user = authState.user;
      _nameController.text = user.name;
      _emailController.text = user.email;

      // TODO: If there's an image, set it
      if (user.profileImage != null) {
        setState(() {
          _pickedImage = File(user.profileImage!);
        });
      }
    }
  }

  // Function to handle image removal
  void _removeImage() {
    setState(() {
      _pickedImage = null; // Remove the image
    });

    // Optionally, update the backend to reflect the removed image
    // context.read<AuthCubit>().removeProfileImage();
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
                                : const AssetImage(
                                      "assets/imgs/default_avatar.jpg",
                                    )
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

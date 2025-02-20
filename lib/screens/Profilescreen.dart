import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatting_application/api/Api.dart';
import 'package:chatting_application/helper/littlething.dart';
import 'package:chatting_application/model/ChatUser.dart';
import 'package:chatting_application/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formkey = GlobalKey<FormState>();
  String? _image;
  bool _isChanged = false;
String? _initialName;
String? _initialAbout;
String? _initialImage;

  final SupabaseClient supabase = Supabase.instance.client;
  @override
void initState() {
  super.initState();
  _initialName = widget.user.name;
  _initialAbout = widget.user.about;
  _initialImage = widget.user.image;
}


  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return WillPopScope(
     onWillPop: () async {
    bool imageChanged = _initialImage != widget.user.image;
    bool nameChanged = _initialName != APIs.me.name;
    bool aboutChanged = _initialAbout != APIs.me.about;

    if (_isChanged || imageChanged || nameChanged || aboutChanged) {
      _showExitDialog(); // Show dialog if any change detected
      return false;
    }
    return true; // Exit normally if no change
  },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          title: Text(
            "We Chat",
            style: GoogleFonts.nunito(
                letterSpacing: 2,
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0, right: 10),
          child: FloatingActionButton.extended(
            onPressed: () async {
              Loading.showLoadingIndicator(context);
              await Future.delayed(const Duration(milliseconds: 2000));
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then(
                  (value) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const Login()));
                  },
                );
              });
            },
            elevation: 1,
            backgroundColor: const Color.fromARGB(255, 253, 93, 93),
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            label: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formkey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: mq.width,
                      height: mq.height * .03,
                    ),
                    Stack(
                      children: [
                        _image != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(mq.height * .3),
                                child: Image.file(
                                  File(_image!),
                                  width: mq.height * .2,
                                  height: mq.height * .2,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(mq.height * .3),
                                child: CachedNetworkImage(
                                  width: mq.height * .2,
                                  height: mq.height * .2,
                                  fit: BoxFit.cover,
                                  imageUrl: widget.user.image.toString(),
                                  errorWidget: (context, url, error) =>
                                      const CircleAvatar(
                                    child: Icon(CupertinoIcons.person),
                                  ),
                                ),
                              ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: ElevatedButton(
                            onPressed: () {
                              _bottomsheet();
                            },
                            style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(), elevation: 1),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: mq.height * .03,
                    ),
                    Text(
                      widget.user.email.toString(),
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    TextFormField(
                      onSaved: (newValue) => APIs.me.name = newValue,
                      onChanged: (value) => _isChanged=true,
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : 'Required Field',
                      initialValue: widget.user.name,
                      decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person_2_outlined,
                            color: Colors.black,
                          ),
                          hintText: 'eg. Ubaid',
                          hintStyle: const TextStyle(color: Colors.black45),
                          labelText: 'Name',
                          labelStyle: const TextStyle(fontSize: 18),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      onChanged: (value) => _isChanged=true,
                      onSaved: (newValue) => APIs.me.about = newValue,
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : 'Required Field',
                      initialValue: widget.user.about,
                      decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.info_outline,
                            color: Colors.black,
                          ),
                          hintText: 'eg. Feelings',
                          hintStyle: const TextStyle(color: Colors.black45),
                          labelText: 'About',
                          labelStyle: const TextStyle(fontSize: 18),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        APIs.updateProfilePic();
                        if (_formkey.currentState!.validate()) {
                          _formkey.currentState!.save();
                          APIs.updateUserinfo().then(
                            (value) {
                              Floatingwidget(
                                      title: 'Updated', subtitle: 'Success')
                                  .showAchievement(context);
                            },
                          );
                        } else {
                          Floatingwidget(
                                  title: 'Error', subtitle: 'In updating')
                              .showAchievement(context);
                        }
                      },
                      label: Text(
                        'UPDATE',
                        style: GoogleFonts.poppins(),
                      ),
                      icon: const Icon(Icons.edit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[300],
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _bottomsheet() {
    final mq = MediaQuery.of(context).size;
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Text(
                    'Pick Profile Picture From ',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        final XFile? image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          print('sucees ${image.path}');
                          Navigator.pop(context);
                          setState(() {
                            _image = image.path;
                          });
                          await _uploadImage(image);
                        } else {
                          print('failed');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          backgroundColor: Colors.white,
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      child: SizedBox(
                          height: 80,
                          width: 80,
                          child: Image.asset('assets/images/gallery.png'))),
                  ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        final XFile? image =
                            await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          print('sucees ${image.path}');
                          Navigator.pop(context);
                          setState(() {
                            _image = image.path;
                          });
                          await _uploadImage(image);
                        } else {
                          print('failed');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          backgroundColor: Colors.white,
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      child: SizedBox(
                          height: 80,
                          width: 80,
                          child: Image.asset('assets/images/camera.png'))),
                ],
              ),
              const SizedBox(
                height: 40,
              )
            ],
          );
        });
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'profile-pictures/$fileName';

      // Upload image to Supabase storage
      await supabase.storage.from('profile-pictures').upload(filePath, file);

      // Get the public URL of the uploaded image
      final imageUrl =
          supabase.storage.from('profile-pictures').getPublicUrl(filePath);
      print('Uploaded Image URL: $imageUrl'); // Debugging URL output

      // Update user profile in Firestore
      await APIs.updateProfilePic(imageUrl);

      // Update UI
      setState(() {
        _isChanged = true;
        widget.user.image = imageUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

// Function to show the exit confirmation dialog
 void _showExitDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save changes or discard them?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); 
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              _saveChanges();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

// Function to save changes (profile picture, name, about)
  void _saveChanges() {
    APIs.updateProfilePic();
    if (_formkey.currentState!.validate()) {
      _formkey.currentState!.save();
      APIs.updateUserinfo().then((value) {
        Floatingwidget(title: 'Updated', subtitle: 'Success')
            .showAchievement(context);
      });
    } else {
      Floatingwidget(title: 'Error', subtitle: 'In updating')
          .showAchievement(context);
    }
  }
}

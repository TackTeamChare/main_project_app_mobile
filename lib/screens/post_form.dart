import 'dart:io';

import 'package:flutter/material.dart';

import 'package:test_blog_app_project/constant.dart';
import 'package:test_blog_app_project/models/api_response.dart';
import 'package:test_blog_app_project/models/post.dart';
import 'package:test_blog_app_project/serveices/post_service.dart';
import 'package:test_blog_app_project/serveices/user_service.dart';
import 'login.dart';

class PostForm extends StatefulWidget {
  final Post? post;
  final String? title;

  PostForm({this.post, this.title});

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtControllerBody = TextEditingController();
  final TextEditingController _txtControllerTitle = TextEditingController();
  final TextEditingController _txtControllerimage = TextEditingController();
  // final TextEditingController _txtControllerCategory = TextEditingController();
  bool _loading = false;
  File? _imageFile;
  String? selectedCategory;
  List<String> selectedCategories = [];

  List<String> categories = [
    "ศาสนา",
    "การศึกษา",
    "การท่องเที่ยว",
    "กีฬา",
    "เกมส์",
    "การเมือง",
    "โซเชียล"
  ];

  void _createPost() async {
    ApiResponse response = await createPost(
      // _txtControllerTitle.text, // Send title
      // _txtControllerCategory.text, // Send category
      // _txtControllerBody.text,
      // image,
      _txtControllerTitle.text,
      selectedCategories,
      _txtControllerBody.text,
      _txtControllerimage.text,
    );

    if (response.error == null) {
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   QuickAlert.show(
      //     // แสดง QuickAlert ทันทีเมื่อล็อคอินสำเร็จ
      //     context: context,
      //     type: QuickAlertType.info,
      //     title: 'บทความถูกโพสต์',
      //   );
      // });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บทความถูกโพสต์สำเร็จ'),
        ),
      );
      Navigator.of(context).pop();
    } else if (response.error == unauthorized) {
      logout().then((value) => {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false)
          });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${response.error}')));
      setState(() {
        _loading = !_loading;
      });
    }
  }

  void _editPost(int postId) async {
    ApiResponse response = await editPost(
      postId,
      _txtControllerTitle.text,
      selectedCategories,
      _txtControllerBody.text,
      _txtControllerimage.text,
    );
    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('โพสต์ถูกแก้ไข'),
        ),
      );
      Navigator.of(context).pop();
    } else if (response.error == unauthorized) {
      logout().then((value) => {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false)
          });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${response.error}')));
      setState(() {
        _loading = !_loading;
      });
    }
  }

  @override
  void initState() {
    if (widget.post != null) {
      _txtControllerBody.text = widget.post!.body ?? '';
      _txtControllerTitle.text =
          widget.post!.title ?? ''; // Set title if available
      // _txtControllerCategory.text =
      //     widget.post!.category ?? ''; // Set category if available
      selectedCategory = widget.post!.category;
      selectedCategories = List.from(widget.post!.categories);

      _txtControllerimage.text = widget.post!.image ?? '';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}'),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              children: [
                widget.post != null
                    ? SizedBox()
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        decoration: BoxDecoration(
                            image: _imageFile == null
                                ? null
                                : DecorationImage(
                                    image: FileImage(_imageFile ?? File('')),
                                    fit: BoxFit.cover)),
                      ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          //enabled: false,
                          controller: _txtControllerimage,
                          decoration: InputDecoration(
                              hintText: "insert image URL here",
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 1, color: Colors.black38))),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: TextFormField(
                          controller: _txtControllerTitle,
                          validator: (val) =>
                              val!.isEmpty ? 'Title is required' : null,
                          decoration: InputDecoration(
                            hintText: "Title...",
                            labelText: "Title",
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 1,
                                color: Colors.black38,
                              ),
                            ),
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                      ),
                      Wrap(
                        children: [
                          Center(
                            child: Text(
                              'หมวดหมู่',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...categories.map((category) {
                            bool isSelected =
                                selectedCategories.contains(category);
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: InputChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedCategories.add(category);
                                    } else {
                                      selectedCategories.remove(category);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: TextFormField(
                          controller: _txtControllerBody,
                          keyboardType: TextInputType.multiline,
                          maxLines: 9,
                          validator: (val) =>
                              val!.isEmpty ? 'Post body is required' : null,
                          decoration: InputDecoration(
                            hintText: "Post body...",
                            labelText: "Post Body",
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.black38),
                            ),
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // _getImageFromGallery();
                              },
                              child: Text('เลือกรูปภาพ'),
                            ),
                            if (_imageFile != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  _imageFile!,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _loading = !_loading;
                        });
                        if (widget.post == null) {
                          _createPost();
                        } else {
                          _editPost(widget.post!.id ?? 0);
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      primary: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.post_add),
                        Text('Post'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

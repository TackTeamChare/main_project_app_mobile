import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_blog_app_project/constant.dart';
import 'package:test_blog_app_project/models/api_response.dart';
import 'package:test_blog_app_project/models/post.dart';
import 'package:test_blog_app_project/screens/comment_screen.dart';
import 'package:test_blog_app_project/screens/post_form.dart';
import 'package:test_blog_app_project/serveices/post_service.dart';
import 'package:test_blog_app_project/serveices/user_service.dart';

import 'login.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  List<dynamic> _postList = [];
  List<dynamic> _filteredPostList = [];
  int userId = 0;
  bool _loading = true;
  bool _noSearchResults = false;
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
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocus = FocusNode();

  // Style
  TextStyle noSearchResultsTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );

  @override
  void initState() {
    retrievePosts();
    super.initState();
  }

  Future<void> retrievePosts() async {
    userId = await getUserId();
    ApiResponse response;

    if (_searchController.text.isNotEmpty) {
      response = await getPostsByCategory(_searchController.text);
    } else if (selectedCategories.isNotEmpty) {
      // If selectedCategories is not empty, filter by category
      String category = selectedCategories.join(',');
      response = await getPostsByCategory(category);
    } else {
      response = await getPosts();
    }

    if (response.error == null) {
      setState(() {
        _postList = response.data as List<dynamic>;
        _filteredPostList = List.from(_postList);
        _loading = _loading ? !_loading : _loading;
      });
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Login()), (route) => false);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  void filterPostsByCategory(String category) {
    if (category.isEmpty) {
      setState(() {
        _filteredPostList = List.from(_postList);
        _noSearchResults = false;
      });
    } else {
      setState(() {
        _filteredPostList = _postList
            .where(
                (post) => post.category.toLowerCase() == category.toLowerCase())
            .toList();
        _noSearchResults = _filteredPostList.isEmpty;
      });
    }
  }

  void _handleDeletePost(int postId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      ApiResponse response = await deletePost(postId);
      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บทความถูกลบเเล้ว'),
          ),
        );
        retrievePosts();
      } else if (response.error == unauthorized) {
        logout().then((value) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Login()),
              (route) => false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบไม่สำเร็จ'),
          ),
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${response.error}')));
      }
    }
  }

  void _handlePostLikeDislike(int postId) async {
    ApiResponse response = await likeUnlikePost(postId);

    if (response.error == null) {
      retrievePosts();
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Login()), (route) => false);
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${response.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () {
              return retrievePosts();
            },
            child: Column(
              children: [
                // Container(
                //                   width: 48,
                //                   height: 48,
                //                   decoration: BoxDecoration(
                //                     shape: BoxShape.circle,
                //                     image: post.user!.image != null
                //                         ? DecorationImage(
                //                             image: NetworkImage(
                //                                 '${post.user!.image}'),
                //                             fit: BoxFit.cover,
                //                           )
                //                         : null,
                //                     color: Colors.amber,
                //                   ),
                //                 ),
                //                 SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search posts...',
                      labelText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          filterPosts('');
                        },
                      ),
                    ),
                    onChanged: (value) {
                      filterPosts(value);
                    },
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
                      bool isSelected = selectedCategories.contains(category);
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
                              // Filter posts by selected categories
                              filterPostsByCategory(category);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
                Expanded(
                  child: _noSearchResults
                      ? Center(
                          child: Text(
                            'No search results found.',
                            style: noSearchResultsTextStyle,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredPostList.length,
                          itemBuilder: (BuildContext context, int index) {
                            Post post = _filteredPostList[index];
                            return Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: post.user!.image != null
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                            '${post.user!.image}'),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.person,
                                                        color: Colors
                                                            .black), // เพิ่มไอคอน Person
                                                    Text(
                                                      'User : ${post.user!.name}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.email,
                                                        color: Colors.black),
                                                    Text(
                                                      'Email : ${post.user!.email}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.title,
                                                      color: Colors.black),
                                                  // Text(
                                                  //   'Title : ',
                                                  //   style: TextStyle(
                                                  //     color: Colors.black,
                                                  //     fontWeight:
                                                  //         FontWeight.bold,
                                                  //     fontSize: 22,
                                                  //   ),
                                                  // ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      '${post.title}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 26,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Icon(Icons.category,
                                                        color: Colors.black),
                                                  ),
                                                  // Text(
                                                  //   'Category : ',
                                                  //   style: TextStyle(
                                                  //     color: Colors.black,
                                                  //     fontSize: 20,
                                                  //     fontWeight:
                                                  //         FontWeight.bold,
                                                  //   ),
                                                  // ),
                                                  Text(
                                                    '${post.category}',
                                                    style: TextStyle(
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 0, 0, 0),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (post.user!.id == userId)
                                        PopupMenuButton(
                                          child: Icon(
                                            Icons.more_vert,
                                            color: Colors.black,
                                          ),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit,
                                                      size: 20), // ไอคอน Edit
                                                  SizedBox(
                                                      width:
                                                          8), // ระยะห่างระหว่างไอคอนและข้อความ 'Edit'
                                                  Text('Edit'),
                                                ],
                                                mainAxisSize: MainAxisSize.min,
                                              ),
                                              value: 'edit',
                                            ),
                                            PopupMenuItem(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      size: 20), // ไอคอน Delete
                                                  SizedBox(
                                                      width:
                                                          8), // ระยะห่างระหว่างไอคอนและข้อความ 'Delete'
                                                  Text('Delete'),
                                                ],
                                                mainAxisSize: MainAxisSize.min,
                                              ),
                                              value: 'delete',
                                            )
                                          ],
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                builder: (context) => PostForm(
                                                  title: 'Edit Post',
                                                  post: post,
                                                ),
                                              ));
                                            } else {
                                              _handleDeletePost(post.id ?? 0);
                                            }
                                          },
                                        )
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Icon(Icons.content_paste, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          '${post.body}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (post.image != null)
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: 180,
                                      margin: EdgeInsets.only(top: 12),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage('${post.image}'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      kLikeAndComment(
                                        post.likesCount ?? 0,
                                        post.selfLiked == true
                                            ? Icons.favorite
                                            : Icons.favorite_outline,
                                        post.selfLiked == true
                                            ? Colors.red
                                            : Colors.black54,
                                        () {
                                          _handlePostLikeDislike(post.id ?? 0);
                                        },
                                      ),
                                      Container(
                                        height: 25,
                                        width: 0.5,
                                        color: Colors.black38,
                                      ),
                                      kLikeAndComment(
                                        post.commentsCount ?? 0,
                                        Icons.sms_outlined,
                                        Colors.black54,
                                        () {
                                          Navigator.of(context)
                                              .push(MaterialPageRoute(
                                            builder: (context) => CommentScreen(
                                              postId: post.id,
                                            ),
                                          ));
                                        },
                                      ),
                                      kShareButton(
                                        () {
                                          Share.share(
                                              'Check out this post: ${post.title}');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Shared post: ${post.title}\n${post.category}\n${post.body}'),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 0.5,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
  }

  void filterPosts(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        _filteredPostList = List.from(_postList);
        _noSearchResults = false; // รีเซ็ตเพื่อไม่แสดงข้อความ
      });
    } else {
      setState(() {
        _filteredPostList = _postList
            .where((post) =>
                post.title.toLowerCase().contains(searchText.toLowerCase()) ||
                post.body.toLowerCase().contains(searchText.toLowerCase()) ||
                post.category.toLowerCase().contains(searchText.toLowerCase()))
            .toList();
        _noSearchResults = _filteredPostList.isEmpty;
      });
    }
  }
}

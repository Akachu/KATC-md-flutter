import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class Post {
  final String writer;
  final int id;
  final String title;
  final String text;

  Post({this.writer, this.id, this.title, this.text});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      writer: json['writer'],
      id: json['id'],
      title: json['title'],
      text: json['text'],
    );
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["writer"] = writer;
    map["title"] = title;
    map["text"] = text;

    return map;
  }
}

void main() {
  runApp(App());
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'katc-md-ft',
        theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColorBrightness: Brightness.light),
        home: HomePage(title: '편지 보내기'),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ));
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String url = '__API_URL__';

  bool _autoValidate = false;
  FocusNode _focus;
  FocusNode _focus_2;
  TextEditingController nameControler = new TextEditingController();
  TextEditingController titleControler = new TextEditingController();
  TextEditingController bodyControler = new TextEditingController();

  OverlayEntry overlayEntry;

  OverlayEntry makeLoadingOverlay() {
    return OverlayEntry(
        builder: (BuildContext context) => Stack(
              children: <Widget>[
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(color: Colors.black54),
                  ),
                ),
                Center(
                  child: CircularProgressIndicator(),
                )
              ],
            ));
  }

  void makeToast(message, {isError = false}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: isError ? Colors.red : null,
        textColor: isError ? Colors.white : null,
        fontSize: 16.0);
  }

  void _validateInputs() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Post newPost = new Post(
          writer: nameControler.text,
          title: titleControler.text,
          text: bodyControler.text);
      await createPost(url, body: newPost.toMap());
    } else {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  @override
  void initState() {
    _focus = FocusNode();
    _focus_2 = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _focus.dispose();
    _focus_2.dispose();

    super.dispose();
  }

  Future<Post> createPost(String url, {Map body}) async {
    this.overlayEntry = makeLoadingOverlay();
    Overlay.of(context).insert(this.overlayEntry);
    return http.post(url, body: body).then((http.Response response) {
      final int statusCode = response.statusCode;
      var jsonResponse = convert.jsonDecode(response.body);
      this.overlayEntry.remove();
      if (statusCode < 200 || statusCode > 400 || jsonResponse == null) {
        makeToast('발송하지못하였습니다.', isError: true);
        throw new Exception("Error while fetching data");
      }
      makeToast('발송하였습니다.');
      this._formKey.currentState?.reset();
      return Post.fromJson(jsonResponse);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
      ),
      body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: Stack(
            children: <Widget>[
              Form(
                key: _formKey,
                autovalidate: _autoValidate,
                child: ListView(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: nameControler,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(), labelText: '작성자'),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (v) {
                              FocusScope.of(context).requestFocus(_focus);
                            },
                            validator: (String str) {
                              return str.length > 3
                                  ? '이름은 3자 까지 가능합니다'
                                  : str.length == 0 ? '이름을 적어주세요' : null;
                            },
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          TextFormField(
                            controller: titleControler,
                            focusNode: _focus,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(), labelText: '제목'),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_focus_2);
                            },
                            validator: (String str) {
                              return str.length < 5
                                  ? '제목은 최소 5자는 적어야 합니다'
                                  : str.length > 20
                                      ? '제목은 최대 20자까지 가능합니다'
                                      : null;
                            },
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          TextFormField(
                            controller: bodyControler,
                            focusNode: _focus_2,
                            maxLines: 40,
                            minLines: 4,
                            maxLength: 800,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(), labelText: '내용'),
                            validator: (String str) {
                              return str.length < 20
                                  ? '내용은 최소 20자는 적어야 합니다'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          )),
      bottomNavigationBar: BottomAppBar(
        child: FlatButton(
          color: Theme.of(context).accentColor,
          padding: EdgeInsets.all(18),
          child: Text(
            '발송',
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.black),
          ),
          onPressed: _validateInputs,
        ),
      ),
    );
  }
}

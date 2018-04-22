import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opengl_texture/opengl_texture.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _controller = new OpenGLTextureController();
  final _width = 200.0;
  final _height = 200.0;

  @override
  initState() {
    super.initState();

    initializeController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('OpenGL via Texture widget example'),
        ),
        body: new Center(
          child: new Container(
            width: _width,
            height: _height,
            child: _controller.isInitialized
                ? new Texture(textureId: _controller.textureId)
                : null,
          ),
        ),
      ),
    );
  }

  Future<Null> initializeController() async {
    await _controller.initialize(_width, _height);
    setState(() {});
  }
}

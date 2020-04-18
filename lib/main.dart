import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {runApp(MyApp());}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "App",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageCapture(),

    );
  }

}
class ImageCapture extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ImageCapture();
  }
}

class _ImageCapture extends State<ImageCapture>{
  File _imageFile;
  Future<void> _pickImage(ImageSource source) async
  {
    File selected = await ImagePicker.pickImage(source: source);
    setState(() {
      _imageFile = selected;
    });
  }

  Future<void> _cropImage() async
  {
    File cropped = await ImageCropper.cropImage(
      sourcePath: _imageFile.path,
      toolbarColor: Colors.blue,
      toolbarWidgetColor: Colors.white,
      toolbarTitle: 'crop this'
    );
    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }
  void _clear() {
    setState(() => _imageFile = null);
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        bottomNavigationBar: BottomAppBar(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.photo_camera,size: 30,),
                  onPressed: ()=>_pickImage(ImageSource.camera),
                  color:Colors.blue,
              ),
              IconButton(
                icon: Icon(Icons.photo_library,size: 30,),
                onPressed: ()=>_pickImage(ImageSource.gallery),
                color: Colors.blue,
              ),
            ],
          ),
        ),
      body: ListView(
        children: <Widget>[
          if (_imageFile != null) ...[
            Container(
                padding: EdgeInsets.all(32), child: Image.file(_imageFile)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FlatButton(
                  color: Colors.blue,
                  child: Icon(Icons.crop),
                  onPressed: _cropImage,
                ),
                FlatButton(
                  color: Colors.blue,
                  child: Icon(Icons.refresh),
                  onPressed: _clear,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: uploader(
                file: _imageFile,
              ),
            )
          ]
        ],
      ),
    );
  }
}
class uploader extends StatefulWidget
{
  final File file;
  uploader({Key key,this.file}) : super (key : key);

  createState() => _uploaderState();
  }

class _uploaderState extends State<uploader>{
  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://belogapp.appspot.com');
  final DatabaseReference database = FirebaseDatabase.instance.reference().child("Imgs_path");
  StorageUploadTask _uploadTask;
  void _startUpload()
  {
    String filpath = 'images/${DateTime.now()}.png';

    setState(() {
      _uploadTask = _storage.ref().child(filpath).putFile(widget.file);
      database.push().set(filpath);
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_uploadTask != null)
      {
        return StreamBuilder<StorageTaskEvent>(
          stream: _uploadTask.events,
          builder: (context, snapshot) {
            var event = snapshot?.data?.snapshot;
            double progressPercent = event != null?
                event.bytesTransferred / event.totalByteCount : 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(_uploadTask.isComplete) Text("image uploaded sucessfully!",style: TextStyle(color: Colors.greenAccent,
                    height: 2,
                    fontSize: 30),),
                LinearProgressIndicator(value: progressPercent,),
              ],
            );
          },
        );
      }
    else
      {
        return FlatButton.icon(onPressed: _startUpload, icon: Icon(Icons.cloud_upload), label: Text('upload to Firebase'),color: Colors.blue,);
      }
  }
}


import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo picker',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Photo picker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: Text('Pick a photo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print("Go and pick a Photo");

          var result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PhotoPicker(),
              fullscreenDialog: true,
            ),
          );
          if (result != null) {
            print("Done picking: $result");
          } else {
            print("Canceled the picking");
          }
        },
        child: Icon(Icons.collections),
      ),
    );
  }
}

class PhotoPicker extends StatefulWidget {
  @override
  _PhotoPickerState createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  List<Widget> _photoList = [];
  List<AssetEntity> _selectedList = [];
  int currentPage = 0;
  int lastPage;

  int maxSelection = 2;

  _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchPhotos();
      }
    }
  }

  _fetchPhotos() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermission();
    if (result) {
      //load the album list
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          onlyAll: true, type: RequestType.image);
      print(albums);
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(currentPage, 60);
      print(media);
      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          PhotoPickerItem(
              asset: asset,
              onSelect: (AssetEntity asset, bool selected) {
                // selected is the current selection state, so be for touch
                if (selected) {
                  _selectedList.remove(asset);
                  return !selected;
                } else if (_selectedList.length < maxSelection) {
                  _selectedList.add(asset);
                  return !selected;
                }
                return selected;
              }),
        );
      }
      setState(() {
        _photoList.addAll(temp);
        currentPage++;
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Photo picker"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                print("Done picking images");
                Navigator.of(context).pop(_selectedList);
              },
              child: Text('Done'),
              textColor: Colors.white,
            )
          ],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scroll) {
            _handleScrollEvent(scroll);
            return;
          },
          child: GridView.builder(
              itemCount: _photoList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemBuilder: (BuildContext context, int index) {
                return _photoList[index];
              }),
        ));
  }
}

class PhotoPickerItem extends StatefulWidget {
  final Key key;
  final AssetEntity asset;
  final bool Function(AssetEntity asset, bool isSelected) onSelect;

  const PhotoPickerItem({this.asset, this.onSelect, this.key});

  @override
  _PhotoPickerItemState createState() => _PhotoPickerItemState();
}

class _PhotoPickerItemState extends State<PhotoPickerItem> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.asset.thumbDataWithSize(200, 200),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done)
          return GestureDetector(
            onTap: () {
              setState(() {
                // isSelected = !isSelected;
                isSelected = widget.onSelect(widget.asset, isSelected);
              });
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.memory(
                    snapshot.data,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                if (isSelected)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5, bottom: 5),
                      child: Icon(
                        Icons.fiber_manual_record,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                if (isSelected)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5, bottom: 5),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        return Container();
      },
    );
  }
}

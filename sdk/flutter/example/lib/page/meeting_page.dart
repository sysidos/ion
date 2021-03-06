import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:flutter_icons/flutter_icons.dart';
import '../widget/video_render_adapter.dart';
import '../provider/client_provider.dart';
import '../router/application.dart';

class MeetingPage extends StatefulWidget {
  @override
  _MeetingPageState createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  SharedPreferences prefs;
  bool _inCalling = false;
  List<VideoRendererAdapter> _videoRendererAdapters = List();
  VideoRendererAdapter _localVideoAdapter = null;
  bool _cameraOff = false;
  bool _microphoneOff = false;

  final double LOCAL_VIDEO_WIDTH = 114.0;
  final double LOCAL_VIDEO_HEIGHT = 72.0;

  @override
  initState() {
    super.initState();
    init();
  }

  init() async {
    prefs = await SharedPreferences.getInstance();
  }

  handleLeave() async {
    await Provider.of<ClientProvider>(context).cleanUp();
    Application.router.navigateTo(context, "/login");
  }

  Widget buildVideoView(VideoRendererAdapter adapter) {
    return Container(
      alignment: Alignment.center,
      child: RTCVideoView(adapter.renderer),
      color: Colors.black,
    );
  }

  Widget _buildMainVideo() {
    if (_videoRendererAdapters.length == 0)
      return Image.asset(
        'assets/images/loading.jpeg',
        fit: BoxFit.cover,
      );

    var adapter = _videoRendererAdapters[0];
    return GestureDetector(
        onDoubleTap: () {
          adapter.switchObjFit();
        },
        child: RTCVideoView(adapter.renderer));
  }

  Widget _buildLocalVideo(Orientation orientation) {
    if (_localVideoAdapter != null) {
      return SizedBox(
          width: (orientation == Orientation.portrait)
              ? LOCAL_VIDEO_HEIGHT
              : LOCAL_VIDEO_WIDTH,
          height: (orientation == Orientation.portrait)
              ? LOCAL_VIDEO_WIDTH
              : LOCAL_VIDEO_HEIGHT,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(
                //边框颜色
                color: Colors.white,
                //边框粗细
                width: 0.5,
              ),
            ),
            child: GestureDetector(
                onTap: () {
                  _switchCamera();
                },
                onDoubleTap: () {
                  _localVideoAdapter.switchObjFit();
                },
                child: RTCVideoView(_localVideoAdapter.renderer)),
          ));
    }
    return Container();
  }

  List<Widget> _buildVideoViews() {
    List<Widget> views = new List<Widget>();
    if (_videoRendererAdapters.length > 1)
      _videoRendererAdapters
          .getRange(1, _videoRendererAdapters.length)
          .forEach((adapter) {
        views.add(_buildVideo(adapter));
      });
    return views;
  }

  swapVideoPostion(int x, int y) {
    var src = _videoRendererAdapters[x];
    var dest = _videoRendererAdapters[y];
    var srcStream = src.stream;
    src.setSrcObject(null);
    dest.setSrcObject(srcStream);
  }

  Widget _buildVideo(VideoRendererAdapter adapter) {
    return SizedBox(
      width: 120,
      height: 90,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
        ),
        child: GestureDetector(
            onTap: () async {
              var mainVideoAdapter = _videoRendererAdapters[0];
              var mainStream = mainVideoAdapter.stream;
              await mainVideoAdapter.setSrcObject(adapter.stream);
              await adapter.setSrcObject(mainStream);
            },
            onDoubleTap: () {
              adapter.switchObjFit();
            },
            child: RTCVideoView(adapter.renderer)),
      ),
    );
  }

  //Switch local camera
  _switchCamera() {}

  //Open or close local video
  _turnCamera() {
    var muted = !_cameraOff;
    setState(() {
      _cameraOff = muted;
    });
  }

  //Open or close local audio
  _turnMicrophone() {
    var muted = !_microphoneOff;
    setState(() {
      _microphoneOff = muted;
    });
  }

  _hangUp() {}

  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            'Waiting for others to join...',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  //tools
  List<Widget> _buildTools() {
    return <Widget>[
      IconButton(
        icon: Icon(
          _cameraOff
              ? MaterialCommunityIcons.getIconData("video-off")
              : MaterialCommunityIcons.getIconData("video"),
          color: _cameraOff ? Colors.red : Colors.white,
        ),
        onPressed: _turnCamera,
      ),
      IconButton(
        icon: Icon(
          MaterialCommunityIcons.getIconData("video-switch"),
          color: Colors.white,
        ),
        onPressed: _switchCamera,
      ),
      IconButton(
        icon: Icon(
          _microphoneOff
              ? MaterialCommunityIcons.getIconData("microphone-off")
              : MaterialCommunityIcons.getIconData("microphone"),
          color: _microphoneOff ? Colors.red : Colors.white,
        ),
        onPressed: _turnMicrophone,
      ),
      IconButton(
        icon: Icon(
          MaterialIcons.getIconData("volume-up"),
          color: Colors.white,
        ),
        onPressed: () {},
      ),
      IconButton(
        icon: Icon(
          MaterialCommunityIcons.getIconData("phone-hangup"),
          color: Colors.red,
        ),
        onPressed: _hangUp,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _inCalling = Provider.of<ClientProvider>(context).inCalling;
    return OrientationBuilder(builder: (context, orientation) {
      return SafeArea(
        child: Scaffold(
          body: Consumer<ClientProvider>(builder: (BuildContext context,
              ClientProvider clientProvider, Widget child) {
            _videoRendererAdapters = clientProvider.videoRendererAdapters;
            _localVideoAdapter = clientProvider.localVideoAdapter;
            return orientation == Orientation.portrait
                ? Container(
                    color: Colors.black87,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black54,
                            child: Stack(
                              children: <Widget>[
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    child: _buildMainVideo(),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  top: 48,
                                  child: Container(
                                    child: _buildLocalVideo(orientation),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 48,
                                  height: 90,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: _buildVideoViews(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        (_videoRendererAdapters.length == 0)
                            ? _buildLoading()
                            : Container(),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 48,
                          child: Stack(
                            children: <Widget>[
                              Opacity(
                                opacity: 0.5,
                                child: Container(
                                  color: Colors.black,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _buildTools(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: 48,
                          child: Stack(
                            children: <Widget>[
                              Opacity(
                                opacity: 0.5,
                                child: Container(
                                  color: Colors.black,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(0.0),
                                child: Center(
                                  child: Text(
                                    'Ion Flutter Demo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: Colors.black54,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black87,
                            child: Stack(
                              children: <Widget>[
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    child: _buildMainVideo(),
                                  ),
                                ),
                                Positioned(
                                  right: 60,
                                  top: 10,
                                  child: Container(
                                    child: _buildLocalVideo(orientation),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 120,
                                  child: ListView(
                                    scrollDirection: Axis.vertical,
                                    children: _buildVideoViews(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        (_videoRendererAdapters.length == 0)
                            ? _buildLoading()
                            : Container(),
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: 48,
                          child: Stack(
                            children: <Widget>[
                              Opacity(
                                opacity: 0.5,
                                child: Container(
                                  color: Colors.black,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _buildTools(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
          }),
        ),
      );
    });
  }
}

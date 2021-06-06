import 'package:ai_audio_app/model/radio.dart';
import 'package:ai_audio_app/utils/ai_utils.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyRadio> radios;
  MyRadio _selectedRadio;
  Color _selectedColor;
  bool _isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    setupAlan();
    fetchRadios();

    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PLAYING) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }

      setState(() {});
    });
  }

  setupAlan(){
    AlanVoice.addButton(
        "c2bebd538df9f84ad09004e10905dbf42e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }

  _handleCommand(Map<String, dynamic> response){
       switch(response["command"]){
         case "play":
           _playMusic(_selectedRadio.url);
           break;
         case "stop":
           _audioPlayer.stop();
           break;
         case "next":
           final index = _selectedRadio.id;
           MyRadio newRadio ;
           if(index+1 > radios.length){
              newRadio = radios.firstWhere((element) => element.id == 1);
              radios.remove(newRadio);
              radios.insert(0, newRadio);
              setState(() {

              });
           }else{
             newRadio = radios.firstWhere((element) => element.id == index+1);
             radios.remove(newRadio);
             radios.insert(0, newRadio);
             setState(() {

             });
           }
           _playMusic(newRadio.url);
           break;
         case "prev":
           final index = _selectedRadio.id;
           MyRadio newRadio ;
           if(index - 1 < radios.length){
             newRadio = radios.firstWhere((element) => element.id == radios.length);
             radios.remove(newRadio);
             radios.insert(0, newRadio);
           }else{
             newRadio = radios.firstWhere((element) => element.id == index-1);
             radios.remove(newRadio);
             radios.insert(0, newRadio);
           }
           _playMusic(newRadio.url);
           break;
       }
  }

  fetchRadios() async {
    // loaded radio json
    final radioJson = await rootBundle.loadString('assets/radio.json');
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios[0];
    _selectedColor = Color(int.tryParse(_selectedRadio.color));
    // print(radios);
    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(url);
    _selectedRadio = radios.firstWhere((element) => element.url == url);
    print(_selectedRadio.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      body: Stack(
        children: <Widget>[
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(
                  colors: [AIUtil.primaryColor2, _selectedColor ?? AIUtil.primaryColor1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight))
              .make(),
          AppBar(
            title: "AI Player"
                .text
                .xl4
                .bold
                .white
                .make()
                .shimmer(primaryColor: Vx.purple300, secondaryColor: Vx.white),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ).h(100.0).p16(), //Addes height and padding using velocity X
          radios != null ? VxSwiper.builder(
              aspectRatio: 1.0,
              itemCount: radios.length,
              onPageChanged: (index) {
                // _selectedRadio = radios[index];
                final colorHex = radios[index].color;
                _selectedColor = Color(int.tryParse(colorHex));
                setState(() {});
              },
              enlargeCenterPage: true,
              itemBuilder: (context, index) {
                final rad = radios[index];

                return VxBox(
                        child: ZStack([
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VStack([rad.tagline.text.sm.white.semiBold.make()]),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: [
                      Icon(
                        CupertinoIcons.play_circle_fill,
                        color: Colors.white,
                      ),
                      10.heightBox,
                      "Tap to Play".text.gray300.make()
                    ].vStack(),
                  )
                ]))
                    .bgImage(
                      DecorationImage(
                          image: NetworkImage(rad.image),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3), BlendMode.darken)),
                    )
                    .border(color: Colors.black, width: 5.0)
                    .withRounded(value: 40.0)
                    .make()
                    .onTap(() {
                      _playMusic(rad.url);
                    })
                    .p16()
                    .centered();
              }).centered() : Center(child: CircularProgressIndicator(backgroundColor: Colors.blueAccent, value: 20.0,)),
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if (_isPlaying)
                "Playing Now - ${_selectedRadio.name}".text.makeCentered().pOnly(bottom: context.percentHeight * 2),
              Icon(
                _isPlaying
                    ? CupertinoIcons.stop_circle
                    : CupertinoIcons.play_circle,
                color: Colors.white,
                size: 50.0,
              ).onTap(() {
                if (_isPlaying)
                  _audioPlayer.stop();
                else
                  _playMusic(_selectedRadio.url);
              }),
            ].vStack(),
          ).pOnly(bottom: context.percentHeight * 7)
        ],
        fit: StackFit.expand,
      ),
    );
  }
}

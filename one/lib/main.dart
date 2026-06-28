import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main()
{
  runApp(Navi());
}

class Navi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(home: Scaffold(body: Center(child: form(),),));
  }
}

class Navi2 extends StatefulWidget {
  const Navi2({super.key});

  @override
  State<Navi2> createState() => Navi2State();
}
  class Navi2State extends State<Navi2> {

    final TextEditingController textController = TextEditingController();
    @override
    void dispose() {
      textController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      // TODO: implement build
      return Scaffold(body: Text(
        'Use TextEditing Controller for reading on-demand (eg, button clicks).',
        textAlign: TextAlign.center, overflow: TextOverflow.fade,),);

    }
  }

class form extends StatefulWidget{
  const form({super.key});

  @override
  State<form> createState() => formState();
}

class formState extends State<form>{

  final TextEditingController textController = TextEditingController();



  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              border:OutlineInputBorder(),
              labelText:'Enter text1 here',
            ),
          ),
          const SizedBox(height:20),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              border:OutlineInputBorder(),
              labelText:'Enter text2 here',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              border:OutlineInputBorder(),
              labelText:'Enter text3 here',
            ),
          ),
          const SizedBox(height:20),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              border:OutlineInputBorder(),
              labelText:'Enter text4 here',
            ),
          ),
          const SizedBox(height:20),
          ElevatedButton(
            onPressed:() {
              print("User Input: ${textController.text}");
            },
            child:const Text('Print Text'),
          ),
        ],
      ),
    );
  }
}




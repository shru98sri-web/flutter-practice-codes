import 'package:flutter/material.dart';

class Prac extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(home: Practice(), debugShowCheckedModeBanner: false);
  }
}

class Practice extends StatefulWidget {
  const Practice({super.key});
  @override
  State<Practice> createState() => PracticeState();
  // TODO: implement createState
}

class PracticeState extends State<Practice> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('practice'),
        backgroundColor: Colors.yellowAccent,
        leading: Icon(Icons.fax_rounded),
        actions: [
          Icon(Icons.eleven_mp_rounded),
          Icon(Icons.fourteen_mp_outlined),
        ],
      ),
      body:
          // Visibility(visible: isVisible, child: Text('visible test')),
          Column(
            children: [
              Text('text6'),
              SizedBox(width: 50),
              Text('text7'),
              SizedBox(width: 50),
              Text('text8'),
              SizedBox(width: 50),
              Text('text9'),
              SizedBox(width: 50),
              Container(
                color: Colors.purple,
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(16.0),
                child: Text('container3'),
              ),
              SizedBox(width: 50),

              Container(
                color: Colors.purple,
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(16.0),
                child: Text('container3'),
              ),
              SizedBox(width: 50),

              Text('text10'),
              SizedBox(width: 50),
              Image.asset('assets/images/LOGO.png', height: 150, width: 150),
              Image.network(
                'https://media.istockphoto.com/id/1973365581/vector/sample-ink-rubber-stamp.jpg?s=612x612&w=0&k=20&c=_m6hNbFtLdulg3LK5LRjJiH6boCb_gcxPvRLytIz0Ws=',
                width: 150,
                height: 150,
              ),
              Icon(Icons.fax_rounded),
              Icon(Icons.eighteen_up_rating_sharp),
              Container(
                color: Colors.purple,
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(16.0),
                child: Text('container3'),
              ),
              SizedBox(width: 50),
              Row(
                children: [
                  Text('text1'),
                  SizedBox(width: 50),
                  Text('text12'),
                  SizedBox(width: 50),
                  Container(
                    color: Colors.purple,
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(16.0),
                  ),
                  SizedBox(width: 50),

                  Container(
                    color: Colors.purple,
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(16.0),
                  ),
                  SizedBox(width: 50),

                  Text('text13'),
                  SizedBox(width: 50),
                  Text('text4'),
                  SizedBox(width: 50),
                  Text('text5'),
                  SizedBox(width: 50),
                  ElevatedButton(
                    onPressed: () {
                      print('button 1 pressed');
                    },
                    child: Text('click me'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('button 2 pressed');
                    },
                    child: Text('click me'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('button 3 pressed');
                    },
                    child: Text('click me'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('button 4 clicked');
                    },
                    child: Text('click me'),
                  ),
                ],
              ),
            ],
          ),
      backgroundColor: Colors.lightBlueAccent,
    );
  }
}

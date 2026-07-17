import 'package:flutter/material.dart';

class One extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(home: StreamBuilderExample());
  }
}

class ScrollbarExample extends StatefulWidget {
  const ScrollbarExample({super.key});

  @override
  State<ScrollbarExample> createState() => _ScrollbarExampleState();
}

class _ScrollbarExampleState extends State<ScrollbarExample> {
  // 1. Define the ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Always dispose your controllers to avoid memory leaks
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scrollbar Example')),
      body: Scrollbar(
        // 2. Pass the controller to the Scrollbar
        controller: _scrollController,
        child: ListView.builder(
          // 3. Pass the EXACT SAME controller to the scrollable widget
          controller: _scrollController,
          itemCount: 50,
          itemBuilder: (context, index) =>
              ListTile(title: Text('Item number $index')),
        ),
      ),
    );
  }
}

class Two extends StatefulWidget {
  const Two({super.key});

  @override
  State<Two> createState() => TwoState();
  // TODO: implement createState
}

class TwoState extends State<Two> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text('gridview')),
      body: Scrollbar(
        controller: _scrollController,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 8.0,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
          ),
          itemCount: 20,
          controller: _scrollController,
          itemBuilder: (BuildContext context, int index) {
            return Card(child: Center(child: Text('tile $index')));
          },
        ),
      ),
    );
  }
}

class Three extends StatefulWidget {
  const Three({super.key});

  @override
  State<Three> createState() => ThreeState();
  // TODO: implement createState
}

class ThreeState extends State<Three> {
  TextEditingController _TextEditingController = TextEditingController();

  @override
  void dispose() {
    _TextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text('textfield')),
      body: Column(
        children: [
          TextField(
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            controller: _TextEditingController,
            decoration: InputDecoration(
              hintText: 'doe',
              labelText: 'enter name',
            ),
          ),
        ],
      ),
    );
  }
}

class FutureBuilderExample extends StatefulWidget {
  const FutureBuilderExample({super.key});

  @override
  State<FutureBuilderExample> createState() => FutureBuilderExampleState();
  // TODO: implement createState
}

class FutureBuilderExampleState extends State<FutureBuilderExample> {
  late Future<String> _dataFuture;
  Future<String> _fetchData() async {
    await Future.delayed(Duration(seconds: 2));
    return 'Data loaded successfully';
  }

  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple FutureBuilder')),
      body: Center(
        child: FutureBuilder<String>(
          future: _dataFuture,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            }
            if (snapshot.hasData) {
              return Text('Result:${snapshot.data}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

class StreamBuilderExample extends StatelessWidget {
  const StreamBuilderExample({super.key});
  Stream<int> _numberStream() async* {
    int counter = 0;
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield ++counter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('StreamBuilder Example')),
        body: Center(
          child: StreamBuilder<int>(
            stream: _numberStream(),
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Text(
                  'counter value : ${snapshot.data}',
                  style: const TextStyle(fontSize: 30),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var value = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Before After'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BeforeAfter(
                      value: value,
                      before: Image.asset('assets/after.png'),
                      after: Image.asset('assets/before.png'),
                      onValueChanged: (value) {
                        setState(() => this.value = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BeforeAfter(
                      value: value,
                      before: Image.asset('assets/after.jpg'),
                      after: Image.asset('assets/before.jpg'),
                      direction: SliderDirection.vertical,
                      onValueChanged: (value) {
                        setState(() => this.value = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Auto-scroll with final state maintained:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AutoScrollBeforeAfter(
                      before: Image.asset('assets/after.png'),
                      after: Image.asset('assets/before.png'),
                      maintainFinalState: true,
                      waitDuration: const Duration(seconds: 1),
                      speedDuration: const Duration(seconds: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Auto-scroll with looping:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AutoScrollBeforeAfter(
                      before: Image.asset('assets/after.jpg'),
                      after: Image.asset('assets/before.jpg'),
                      direction: SliderDirection.vertical,
                      maintainFinalState: false,
                      waitDuration: const Duration(seconds: 1),
                      speedDuration: const Duration(seconds: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

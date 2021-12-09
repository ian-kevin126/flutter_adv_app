import 'package:flutter/material.dart';
import 'package:flutter_bili_talk/db/hi_cache.dart';
import 'package:flutter_bili_talk/http/core/hi_error.dart';
import 'package:flutter_bili_talk/http/core/hi_net.dart';
import 'package:flutter_bili_talk/http/dao/login_dao.dart';
import 'package:flutter_bili_talk/http/dao/notice_dao.dart';
import 'package:flutter_bili_talk/http/request/test_request.dart';
import 'package:flutter_bili_talk/model/owner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, @required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // 缓存预初始化
    HiCache.preInit();
  }

  void _incrementCounter() async {
    // testRequest();
    // test1();
    // test2();
    testLogin();

    setState(() {
      _counter++;
    });
  }

  void testRequest() async {
    TestRequest request = TestRequest();
    request.add('aa', 'ddd').add('bb', '22');
    try {
      var result = await HiNet.getInstance().fire(request);
      print('result11: $result');
    } on NeedLogin catch (e) {
      print(e);
    } on NeedAuth catch (e) {
      print(e);
    } on HiNetError catch (e) {
      print(e);
    }
  }

  void test1() {
    var ownerMap = {"name": "kevin", "face": "iakndsajasdasjdsada", "fans": 12};
    Owner owner = Owner.fromJson(ownerMap);
    print('name: ${owner.name}'); // name: kevin
    print('face: ${owner.face}'); // face: iakndsajasdasjdsada
    print('fans: ${owner.fans}'); // fans: 12
  }

  // 测试缓存HiCache
  void test2() {
    HiCache.getInstance().setString('aKey', '1233');
    var value = HiCache.getInstance().get('aKey');
    print('缓存值----value：${value}');
  }

  void testLogin() async {
    try {
      // 测试注册接口
      // var result = await LoginDao.registration('kevinliao', "880188", false);
      // print('登录结果：${result}');
      // 测试登录接口
      var result = await LoginDao.login('kevinliao', "880188");
      print('登录结果：${result}');

      // 测试通知列表接口
      var result1 = await NoticeDao.noticeList();
      print('通知列表：${result1}');
    } on NeedLogin catch (e) {
      print(e);
    } on NeedAuth catch (e) {
      print(e);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

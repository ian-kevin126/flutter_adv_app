import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bili_talk/db/hi_cache.dart';
import 'package:flutter_bili_talk/http/dao/login_dao.dart';
import 'package:flutter_bili_talk/page/favorite_list_page.dart';
import 'package:flutter_bili_talk/page/login_page.dart';
import 'package:flutter_bili_talk/page/notice_page.dart';
import 'package:flutter_bili_talk/page/registration_page.dart';
import 'package:flutter_bili_talk/page/theme_mode_setting.dart';
import 'package:flutter_bili_talk/page/video_detail_page.dart';
import 'package:flutter_bili_talk/provider/hi_provider.dart';
import 'package:flutter_bili_talk/provider/theme_provider.dart';
import 'package:flutter_bili_talk/util/toast.dart';
import 'package:provider/provider.dart';

import 'model/video_model.dart';
import 'navigator/bottom_navigator.dart';
import 'navigator/hi_navigator.dart';

void main() {
  runApp(BiliApp());

  ///应用程序的异常捕获
  /*runZonedGuarded((){
    runApp(BiliApp());
  }, (e, s) => print(e));*/

  /// 或者
  //HiDefend().run(BiliApp());
}

class BiliApp extends StatefulWidget {
  @override
  _BiliAppState createState() => _BiliAppState();
}

class _BiliAppState extends State<BiliApp> {
  BiliRouteDelegate _routeDelegate = BiliRouteDelegate();

  // BiliRouteInformationParser _routeInformationParser = BiliRouteInfomationParser();

  @override
  Widget build(BuildContext context) {
    // FutureBuilder的用法可以看：https://book.flutterchina.club/chapter7/futurebuilder_and_streambuilder.html
    // 很多时候我们会依赖一些异步数据来动态更新UI，比如在打开一个页面时我们需要先从互联网上获取数据，在获取数据的过程中我们显示一个加载框，
    // 等获取到数据时我们再渲染页面；又比如我们想展示Stream（比如文件流、互联网数据接收流）的进度。当然，通过 StatefulWidget 我们完全
    // 可以实现上述这些功能。但由于在实际开发中依赖异步数据更新UI的这种场景非常常见，因此Flutter专门提供了FutureBuilder和StreamBuilder
    // 两个组件来快速实现这种功能。

    //FutureBuilder({
    //   this.future, // future：FutureBuilder依赖的Future，通常是一个异步耗时任务。
    //   this.initialData, // initialData：初始数据，用户设置默认数据。
    //   required this.builder, // builder：Widget构建器；该构建器会在Future执行的不同阶段被多次调用，构建器签名如下：
    // })

    // Function (BuildContext context, AsyncSnapshot snapshot),snapshot会包含当前异步任务的状态信息及结果信息 ，比如我们可以通过
    // snapshot.connectionState获取异步任务的状态信息、通过snapshot.hasError判断异步任务是否有错误等等，完整的定义读者可以查看
    // AsyncSnapshot类定义。另外，FutureBuilder的builder函数签名和StreamBuilder的builder是相同的。

    return FutureBuilder<HiCache>(
      //打开页面之前  使用FutureBuilder进行异步预初始化，读取一些缓存信息，因为页面可能会用到这些缓存来显示一些用户的信息
      future: HiCache.preInit(),
      //返回的具体的widget
      builder: (BuildContext context, AsyncSnapshot<HiCache> snapshot) {
        //定义route   加载结束 返回router  否则返回全局的加载中widget
        var widget = snapshot.connectionState == ConnectionState.done
            ? Router(
                //传入路由代理
                routerDelegate: _routeDelegate,

                // 下面这两个属性是组合使用的，主要是来开发web应用的，如果开发IOS和Android就不需要设置了
                // routeInformationParser: _routeInformationParser,
                // routeInformationProvider:
                //     PlatformRouteInformationProvider(initialRouteInformation: RouteInformation(location: "/")),
              )
            : Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );

        // 主题相关provider
        return MultiProvider(
          providers: topProviders,
          child: Consumer<ThemeProvider>(
            builder: (BuildContext context, ThemeProvider themeProvider, Widget child) {
              return MaterialApp(
                home: widget,
                debugShowCheckedModeBanner: false,
                theme: themeProvider.getTheme(),
                darkTheme: themeProvider.getTheme(isDarkMode: true),
                themeMode: themeProvider.getThemeMode(),
                title: 'flutterBili视频',
              );
            },
          ),
        );
      },
    );
  }
}

///代理
class BiliRouteDelegate extends RouterDelegate<BiliRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BiliRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  // 为 Navigator 设置一个 key，必要时可以通过navigatorKey.currentState 来获取到 navigatorState 对象
  BiliRouteDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    // 实现路由跳转逻辑，其他页面跳转的时候都会走这里注册
    HiNavigator.getInstance().registerRouteJump(
      RouteJumpListener(
        onJumpTo: (RouteStatus routeStatus, {Map args}) {
          _routeStatus = routeStatus;
          if (routeStatus == RouteStatus.detail) {
            this.videoModel = args['videoModel'];
          }
          //不要忘记监听路有变化，更新页面
          notifyListeners();
        },
      ),
    );
  }

  // 默认设置路由为首页
  RouteStatus _routeStatus = RouteStatus.home;
  List<MaterialPage> pages = [];

  /// 详情视频信息
  VideoModel videoModel;

  RouteStatus get routeStatus {
    if (_routeStatus != RouteStatus.registration && !hasLogin) {
      return _routeStatus = RouteStatus.login;
    } else {
      return _routeStatus;
    }
  }

  bool get hasLogin => LoginDao.getBoardingPass() != null;

  @override
  Widget build(BuildContext context) {
    //管理路由堆栈，通过getPageIndex获取当前routeStatus在页面堆栈中的位置。
    var index = getPageIndex(pages, routeStatus);

    List<MaterialPage> tempPages = pages;

    if (index != -1) {
      // 要打开的页面在栈中已存在，则将该页面和它上面的所有页面进行出栈
      // tips 具体规则可以根据需要进行调整，这里要求栈中只允许有一个同样的页面的实例
      tempPages = tempPages.sublist(0, index);
    }

    //要打开的页面
    var page;
    if (routeStatus == RouteStatus.home) {
      // 跳转首页时将栈中其它页面进行出栈，因为首页不可回退
      pages.clear();
      //首页整体封装到了bottom_navigator.dart里面
      page = pageWrap(BottomNavigator());
    } else if (routeStatus == RouteStatus.themeSetting) {
      page = pageWrap(ThemeModeSetting());
    } else if (routeStatus == RouteStatus.detail) {
      page = pageWrap(VideoDetailPage(videoModel));
    } else if (routeStatus == RouteStatus.registration) {
      page = pageWrap(RegistrationPage());
    } else if (routeStatus == RouteStatus.notice) {
      page = pageWrap(NoticePage());
    } else if (routeStatus == RouteStatus.login) {
      page = pageWrap(LoginPage());
    } else if (routeStatus == RouteStatus.favoriteList) {
      page = pageWrap(FavoriteListPage());
    }
    // 重新创建一个数组，否则pages因引用没有改变路由不会生效
    tempPages = [...tempPages, page];
    // 通知路由发生变化
    HiNavigator.getInstance().notify(tempPages, pages);

    pages = tempPages;

    //当我们调用物理按键或其他方式返回上一页的时候都会触发onWillPop事件。使用WillPopScope是因为Android机
    // 的物理按键默认是返回首页，所以为了实现各个系统之间的体验一致，需要使用这个组件包裹。
    return WillPopScope(
      // fix Android物理返回键，无法返回上一页问题@https://github.com/flutter/flutter/issues/66349
      onWillPop: () async => !(await navigatorKey.currentState?.maybePop() ?? false),
      child: Navigator(
        key: navigatorKey,
        pages: pages,
        onPopPage: (route, result) {
          if (route.settings is MaterialPage) {
            // 登录页未登录返回拦截，app不登录是没法使用的
            if ((route.settings as MaterialPage).child is LoginPage) {
              if (!hasLogin) {
                showWarnToast("请先登录");
                return false;
              }
            }
          }

          // 执行返回操作
          if (!route.didPop(result)) {
            return false;
          }

          var tempPages = [...pages];

          // 不要忘记将栈顶的页面出栈
          pages.removeLast();

          // 还有，通知路由发生变化
          HiNavigator.getInstance().notify(pages, tempPages);

          return true;
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(BiliRoutePath path) async {}
}

///可缺省 主要应用与web，持有RouteInfomationProvider 提供的RouteInformation 可以将其解析成我们定义的数据类型
// class BiliRouteInformationParser extends RouteInformationParser<BiliRoutePath> {
//   @override
//   Future<BiliRoutePath> parseRouteInformation(
//       RouteInformation routeInformation) async {
//     final uri = Uri.parse(routeInformation.location);
//     print("uri:$uri");
//     if (uri.pathSegments.length == 0) {
//       return BiliRoutePath.home();
//     } else {
//       return BiliRoutePath.detail();
//     }
//   }
// }

///定义路由数据、path
class BiliRoutePath {
  final String location;

  BiliRoutePath.home() : location = "/";

  BiliRoutePath.detail() : location = "/detail";
}

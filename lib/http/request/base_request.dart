import 'package:flutter_bili_talk/http/dao/login_dao.dart';
import 'package:flutter_bili_talk/util/hi_contants.dart';

enum HttpMethod { GET, POST, DELETE }

/// 基础请求
abstract class BaseRequest {
  // curl -X GET "http://api.deviQ.org/uapi/test/test7reguestPrans=11" -H "accept: */*"
  // curl -X GET "https://api.devio.org/uapi/test/test/1
  // 请求一般会有两种：
  // 1，query参数类型："http://localhost:8080/api/user/list?page=0&size=10"
  // 2，path参数类型："https://localhost:8080/api/users/1291212"
  var pathParams;

  // 开发环境发起http请求，生产环境启用https请求
  var useHttps = true;

  // Map<String, dynamic> header = {
  //   HiConstants.authTokenK: HiConstants.authTokenV,
  //   HiConstants.courseFlagK: HiConstants.courseFlagV
  // };

  // map存放所有的参数，可以通过 add 链式调用，不断添加参数
  Map<String, String> params = Map();

  bool needLogin();

  // 接口的域名，https://www.fastmock.site/#/project/97fc8aa3df28a0e79a47e22cc4231347
  String authority() {
    return 'www.fastmock.site';
  }

  // 设置POST/GET
  HttpMethod httpMethod();

  String path();

  // 生成具体的 url
  String url() {
    Uri uri;
    var pathStr = path();
    // 拼接path参数
    if (pathParams != null) {
      // 兼容性处理：如果路径最后已经有了"/"，就不需要添加斜杠了
      if (path().endsWith("/")) {
        pathStr = "${path()}$pathParams";
      } else {
        pathStr = "${path()}/$pathParams";
      }
    }

    // http 和 https 切换
    // bool flag = isEmpty(params);
    // if (useHttps) {
    //   uri = !flag
    //       ? Uri.https(authority(), pathStr, params)
    //       : Uri.https(authority(), pathStr);
    // } else {
    //   uri = !flag
    //       ? Uri.http(authority(), pathStr, params)
    //       : Uri.http(authority(), pathStr);
    // }

    // http和https切换
    bool flag = isEmpty(params);
    if (useHttps) {
      uri = !flag ? Uri.https(authority(), pathStr, params) : Uri.https(authority(), pathStr);
    } else {
      uri = !flag ? Uri.http(authority(), pathStr, params) : Uri.http(authority(), pathStr);
    }

    // 给需要登录的接口携带登录令牌
    /// 获取登录令牌，统一在这里做一次传入，就不需要在每个接口封装时再去传
    var boardingPass = LoginDao.getBoardingPass();
    if (needLogin() && boardingPass != null) {
      // 给需要登录的接口携带登录令牌
      addHeader(LoginDao.BOARDING_PASS, boardingPass);
    }
    print('[Flut] 请求url:$uri');
    print('[Flut] 请求头:$header');
    print('[Flut] 请求参:$params');
    return uri.toString();
  }

  /// 添加参数
  BaseRequest add(String k, Object v) {
    params[k] = v.toString();
    return this;
  }

  // Map<String, dynamic> header = {
  //   'flag': "fa",
  //   // 访问令牌
  //   "auth-token": "Msjdasdj9dsjsak==dsad12"
  // };

  /// 请求头
  Map<String, dynamic> header = {
    //∥访问令牌，在课程公告获取
    HiConstants.authTokenK: HiConstants.authTokenV,
    HiConstants.courseFlagK: HiConstants.courseFlagV,
  };

  /// 添加Header
  BaseRequest addHeader(String k, Object v) {
    header[k] = v.toString();
    return this;
  }

  /// 检查对象或 List 或 Map 是否为空
  bool isEmpty(Object object) {
    if (object is String && object.isEmpty) {
      return true;
    } else if (object is List && object.isEmpty) {
      return true;
    } else if (object is Map && object.isEmpty) {
      return true;
    }
    return false;
  }
}

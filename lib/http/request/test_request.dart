import 'package:flutter_bili_talk/http/request/base_request.dart';

/// 测试接口
class TestRequest extends BaseRequest {
  @override
  HttpMethod httpMethod() {
    return HttpMethod.GET;
  }

  @override
  bool needLogin() {
    /// 测试接口不需要登录
    return false;
  }

  @override
  String path() {
    /// 请求的短路径
    return '/mock/97fc8aa3df28a0e79a47e22cc4231347/api/test';
  }
}

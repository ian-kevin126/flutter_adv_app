import 'package:flutter_bili_talk/http/request/base_request.dart';

/// 注册请求

class RegistrationRequest extends BaseRequest {
  @override
  HttpMethod httpMethod() {
    return HttpMethod.POST;
  }

  @override
  bool needLogin() {
    return false;
  }

  @override
  String path() {
    return '/mock/97fc8aa3df28a0e79a47e22cc4231347/api/user/registration';
  }
}

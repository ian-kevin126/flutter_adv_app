import 'package:flutter_bili_talk/http/request/base_request.dart';

class HomeRequest extends BaseRequest {
  @override
  HttpMethod httpMethod() {
    return HttpMethod.GET;
  }

  @override
  bool needLogin() {
    return true;
  }

  @override
  String path() {
    return '/mock/97fc8aa3df28a0e79a47e22cc4231347/api/fa/home';
  }
}

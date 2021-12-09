import 'package:flutter_bili_talk/db/hi_cache.dart';
import 'package:flutter_bili_talk/http/core/hi_net.dart';
import 'package:flutter_bili_talk/http/request/base_request.dart';
import 'package:flutter_bili_talk/http/request/login_request.dart';
import 'package:flutter_bili_talk/http/request/registration_request.dart';

// https://www.fastmock.site/#/project/97fc8aa3df28a0e79a47e22cc4231347
// kevinliao125

// https://www.fastmock.site/#/project/97fc8aa3df28a0e79a47e22cc4231347
// kevinliao125

/// 登录和注册的SDK
class LoginDao {
  /// 登录令牌
  static const BOARDING_PASS = 'boarding-pass';

  static login(String userName, String password) {
    return _send(userName, password);
  }

  static registration(String username, String password, bool isRegistration) {
    return _send(username, password, isRegistration: isRegistration);
  }

  // 封装通用的send方法，因为在很多地方都需要用到
  static _send(String username, String password, {isRegistration = false}) async {
    BaseRequest request;
    if (!isRegistration) {
      request = LoginRequest();
    } else {
      request = RegistrationRequest();
      request.add('isRegistration', true);
    }

    // 添加参数
    request.add('username', username).add('password', password);

    var result = await HiNet.getInstance().fire(request);
    print(result);

    if (result['code'] == 0 && result['data'] != null) {
      // 保存登录令牌到本地
      HiCache.getInstance().setString(BOARDING_PASS, result['data']);

      // 测试登录令牌是否缓存到本地
      // var value = HiCache.getInstance().get(BOARDING_PASS);
      // print('登录令牌----value：${value}'); // 登录令牌----value：BDSAJDJDSDJLJ121K32H3KK24K34HK324K324H32
    }

    return result;
  }

  /// 获取登录令牌
  static String getBoardingPass() {
    return HiCache.getInstance().get(BOARDING_PASS);
  }
}

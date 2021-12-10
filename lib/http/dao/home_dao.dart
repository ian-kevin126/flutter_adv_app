import 'package:flutter_bili_talk/http/core/hi_net.dart';
import 'package:flutter_bili_talk/http/request/home_request.dart';
import 'package:flutter_bili_talk/model/home_model.dart';

class HomeDao {
  static Future<HomeMo> get(String categoryName, {int pageIndex = 1, int pageSize = 10}) async {
    HomeRequest request = HomeRequest();
    //路径参数
    request.pathParams = categoryName;

    //查询参数
    request.add('pageIndex', pageIndex).add('pageSize', pageSize);

    // 发送请求
    var result = await HiNet.getInstance().fire(request);

    //返回格式化后的data
    return HomeMo.fromJson(result['data']);
  }
}

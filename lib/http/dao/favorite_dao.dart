import 'package:flutter_bili_talk/http/core/hi_net.dart';
import 'package:flutter_bili_talk/http/request/base_request.dart';
import 'package:flutter_bili_talk/http/request/favorite_list_request.dart';
import 'package:flutter_bili_talk/http/request/favorite_request.dart';
import 'package:flutter_bili_talk/model/ranking_model.dart';

class FavoriteDao {
  static favorite(String vid, bool isFavReq) async {
    BaseRequest request = FavoriteRequest(isFavReq);
    request.pathParams = vid;
    var result = await HiNet.getInstance().fire(request);
    print('favorite request result: $result');
    return result;
  }

  /// 收藏列表
  static favoriteList({int pageIndex = 1, int pageSize = 10}) async {
    FavoriteListRequest request = FavoriteListRequest();
    request.add('pageIndex', pageIndex).add('pageSize', pageSize);
    var result = await HiNet.getInstance().fire(request);
    return RankingModel.fromJson(result['data']);
  }
}

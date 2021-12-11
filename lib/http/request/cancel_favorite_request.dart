import 'package:flutter_bili_talk/http/request/favorite_request.dart';

import 'base_request.dart';

class CancelFavoriteRequest extends FavoriteRequest {
  CancelFavoriteRequest(bool isReqFav) : super(isReqFav);

  @override
  HttpMethod httpMethod() {
    return HttpMethod.DELETE;
  }
}

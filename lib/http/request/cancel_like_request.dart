import 'base_request.dart';
import 'like_request.dart';

class CancelLikeRequest extends LikeRequest {
  CancelLikeRequest(bool isReqLike) : super(isReqLike);

  @override
  HttpMethod httpMethod() {
    return HttpMethod.DELETE;
  }
}

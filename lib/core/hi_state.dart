import 'package:flutter/cupertino.dart';

/// 页面状态管理，我们开发经常会遇到一个控制台报错：
/// Unhandled Exception: setState() called after dispose():
/// 为了解决这个问题，只需要在dispose之后不再执行setState就可以了，所以封装这个组件
abstract class HiState<T extends StatefulWidget> extends State<T> {
  @override
  void setState(fn) {
    // 如果当前页面被加载
    if (mounted) {
      super.setState(fn);
    } else {
      print('HiState， page unDestroy ,setState不执行, ${toString()}');
    }
  }
}

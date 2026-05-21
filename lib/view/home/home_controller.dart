import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt tabIndex = 0.obs;

  void setTab(int index) => tabIndex.value = index;
}

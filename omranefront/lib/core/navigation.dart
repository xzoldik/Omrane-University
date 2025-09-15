import 'package:flutter/widgets.dart';

// Global route observer used for screens to detect when they become visible again
// (e.g., after a dialog or another route above them is popped) and refresh data.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

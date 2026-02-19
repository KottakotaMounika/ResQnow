import 'package:geolocator/geolocator.dart';

class LocationResult<L, R> {
final L? _left;
final R? _right;

LocationResult.left(this._left) : _right = null;
LocationResult.right(this._right) : _left = null;

void fold(void Function(L l) leftFunc, void Function(R r) rightFunc) {
if (_right != null) {
rightFunc(_right as R);
} else if (_left != null) {
leftFunc(_left as L);
}
}
}

class LocationService {
static Future<LocationResult<String, Position>> getCurrentLocation() async {
try {
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
return LocationResult.left('Location services are disabled.');
}

LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied) {
return LocationResult.left('Location permission has been denied.');
}
}

if (permission == LocationPermission.deniedForever) {
return LocationResult.left('Location permissions are permanently denied.');
}

return LocationResult.right(await Geolocator.getCurrentPosition(
desiredAccuracy: LocationAccuracy.high,
));
} catch (e) {
return LocationResult.left('Failed to get location: ${e.toString()}');
}
}
}
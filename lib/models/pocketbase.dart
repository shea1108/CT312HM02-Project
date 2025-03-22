import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

void main() async {
  final authData = await pb.collection('users').authWithPassword(
        'shea11082003@gmail.com',
        'thang123123',
      );
  print(authData.token);
}

import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/generated/endpoints.dart';

Future<void> main(List<String> args) async {
  // Create the Serverpod instance
  var pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  // Start the server
  await pod.start();
}

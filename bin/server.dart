import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

final MqttClient client = MqttClient('10.0.0.42', '');

Future main() async {
  client.logging(on: false);
  client.keepAlivePeriod = 320;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  final MqttConnectMessage connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueIdQ2')
      .keepAliveFor(320) // Must agree with the keep alive set above or not set
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.exactlyOnce);
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;

  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
//    client.disconnect();
  }

  HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    4041,
  );
  await for (var request in server) {
    handleRequest(request);
  }
}

void handleRequest(HttpRequest request) {
  try {
    if (request.uri.toString().contains("/inicio")) {
      print("inicio");
      for (int i = 0; i < 400; i++) {
        var pantalla = "HMI-${i}";
        print('pantalla ${pantalla}');
        publicar("hey", "Pantalla/${pantalla}", client);

        if (i == 190) {
          print('delay 1 min...');
          sleep(const Duration(seconds:20));        }
      }
      request.response
        ..statusCode = HttpStatus.accepted
        ..write("ok")
        ..close();
    } else {
      // ···
    }
  } catch (e) {
    print('Exception in handleRequest: $e');
  }
  print('Request handled.');
}

/// The subscribed callback
void onSubscribed(String topic) {
  print('EXAMPLE::Subscription confirmed for topic $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  exit(-1);
}

void publicar(String texto, String topic, MqttClient client) {
  final MqttClientPayloadBuilder builder1 = MqttClientPayloadBuilder();
  builder1.addString('Hello from mqtt_client topic 1');
  print('EXAMPLE:: <<<< PUBLISH a ${topic} >>>>');
  client.publishMessage(topic, MqttQos.atLeastOnce, builder1.payload);
}

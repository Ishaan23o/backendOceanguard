import 'dart:convert';
import 'dart:io';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_multipart/multipart.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:firedart/firedart.dart';
import './controllers/user.dart';
import './controllers/redis.dart';
import 'dart:typed_data';
import './controllers/firestoreHandler.dart';

shelf.Handler _corsHandler(shelf.Handler handler) {
  return (shelf.Request request) async {
    if (request.method == 'OPTIONS') {
      return shelf.Response.ok('', headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    }
    final response = await handler(request);
    return response.change(headers: {
      'Access-Control-Allow-Origin': '*',
    });
  };
}


void main() async {
  var app = Router();
  Firestore.initialize("oceanguardbackend");
  app.post('/addComplaint',addComplaint);
  app.post('/resolveComplaint', resolveComplaint);
  app.get('/viewComplaintsUser', viewComplaintsByUser);
  app.get('/viewComplaintsLocation',viewComplaintsByLocation);
  app.post('/resolveComplaint',resolveComplaint);
  app.post('/resolveComplaints',resolveComplaintAll);
  app.delete('/deleteComplaint',deleteComplaint);
  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(_corsHandler)
      .addHandler(app);

  var server = await io.serve(handler, 'localhost', 8080);
  print('Server running on localhost:${server.port}');
}


// app.post('/fileReceive', (shelf.Request request) async {
// final parameters = <String, dynamic>{
// await for (final formData in request.multipartFormData)
// formData.name: await formData.part
// };
// dynamic extension = parameters['Handle'].headers;
// var str=extension['content-disposition'];
// RegExp regex = RegExp('filename="(.+?)"');
// String filename = regex.firstMatch(str)?.group(1) ?? '';
// String fileExt = filename.split('.').last;
// print(fileExt);
// final file = File('image.$fileExt');
// await file.writeAsBytes(await parameters['Handle'].readBytes());
// return shelf.Response.ok('OK');
// });
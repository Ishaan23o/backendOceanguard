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
import './controllers/resolver.dart';

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
  Firestore.initialize("oceanguard-5aea0");
  app.post('/addComplaint',addComplaint);
  app.post('/resolveComplaint', resolveComplaint);
  app.get('/viewComplaintsUser', viewComplaintsByUser);
  app.get('/viewComplaintsLocation',viewComplaintsByLocation);
  app.get('/viewComplaintsResolved',viewComplaintsForResolverResolved);
  app.get('/viewComplaintsUnresolved',viewComplaintsForResolverUnResolved);
  app.post('/resolveComplaint',resolveComplaint);
  app.post('/resolveComplaints',resolveComplaintAll);
  app.get('/getUserDetails',getUserDetails);
  app.delete('/deleteComplaint',deleteComplaint);
  app.get('/getLocations',getLocation);
  app.post('/changeResolver',changeResolver);//[TODO] change resolver to another location (or deallocate)
  app.post('/requestResolver',requestResolver); //[TODO]  change resolver's requested location
  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(_corsHandler)
      .addHandler(app);

  var server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server running on localhost:${server.port}');
}
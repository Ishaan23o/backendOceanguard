import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:firedart/firedart.dart';
import './firestoreHandler.dart';
import './redis.dart';

//Add this complaint to the database
final addComplaint=(shelf.Request req) async {
  String requestBody = await req.readAsString();
  var data = jsonDecode(requestBody);
  var location=await fetchClosestLocation({'latitude':data['latitude'],'longitude':data['longitude']});
  print(location);
  if(location['found']==false){
    return shelf.Response.badRequest();
  }
  var documentID = await addDocument('complaints', {
    'user':data['userid'],
    'description':data['description'],
    'images':data['images'],
    'place':location['result'][0],
    'latitude': data['latitude'],
    'longitude': data['longitude'],
    'date':data['date'],
    'urgency':data['urgency'],
    'resolved':false
  });
  //Add complaint to redis geo spatial
  await addRedisGeoComplaint({'latitude':data['latitude'],'longitude':data['longitude'],'complaintID':documentID});
  var jsonResponse = {'Success': true,'complaintID':documentID};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};

//Resolve a individual complaint
final resolveComplaint=(shelf.Request req) async {
  String requestBody = await req.readAsString();
  var data = jsonDecode(requestBody);
  await removeRedisGeoComplaint({'complaintID':data['complaintID']});
  await updateDocument('complaints',data['complaintID'],{'resolved':true});
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};

//Resolve all complaints which are within the radius of a particular location
final resolveComplaintAll=(shelf.Request req) async {
  String requestBody = await req.readAsString();
  var data = jsonDecode(requestBody);
  final complaints=await findDocumentsTwo('complaints','place',data['location'],'resolved',false);
  final tasks=complaints.map((element)=>removeRedisGeoComplaint({'complaintID':element.id})
  ).toList();
  print(await Future.wait(tasks));
  final tasks2=complaints.map((element)=>updateDocument('complaints',element.id,{'resolved':true})).toList();
  print(await Future.wait(tasks2));
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};

//Retrieve all complaints from one user
final viewComplaintsByUser=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var complaints = await findDocuments('complaints', 'userid', queryParams['user']);
  return shelf.Response.ok(complaints);
};

//Find all complaints which have been resolved
final viewComplaintsByUserResolved=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var complaints = await findDocumentsTwo('complaints', 'userid', queryParams['user'],'resolved',true);
  return shelf.Response.ok(complaints);
};

//Find all complaints which have not been resolved
final viewComplaintsByUserUnResolved=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var complaints = await findDocumentsTwo('complaints', 'userid', queryParams['user'],'resolved',false);
  return shelf.Response.ok(complaints);
};

//Retrieve all complaints mapped to one location
final viewComplaintsByLocation=(shelf.Request request)async{
  var queryParams = request.url.queryParameters;
  var complaints = await findDocuments('complaints','location',queryParams['location']);
  return shelf.Response.ok(complaints);
};

//Retrieve all complaints mapped to one location, and resolved
final viewComplaintsByLocationUnresolved=(shelf.Request request)async{
  var queryParams = request.url.queryParameters;
  var complaints = await findDocumentsTwo('complaints','location',queryParams['location'],'resolved',true);
  return shelf.Response.ok(complaints);
};

//Delete complaint from database
final deleteComplaint=(shelf.Request request)async{
  String requestBody = await request.readAsString();
  var data = jsonDecode(requestBody);
  await removeRedisGeoComplaint({'complaintID':data['complaintID']});
  delDocument('complaints',data['complaintID']);
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};
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
  DateTime now = DateTime.now().toUtc();
  int unixTimestampSeconds = now.millisecondsSinceEpoch ~/ 1000;
  var documentID = await addDocument('complaints', {
    'user':data['user'],
    'description':data['description'],
    'images':data['images'],
    'place':location['result'][0],
    'latitude': data['latitude'],
    'longitude': data['longitude'],
    'date':unixTimestampSeconds,
    'urgency':data['urgency'],
    'imagesResolved':[],
    'resolved':false
  });
  //Add complaint to redis geo spatial
  var jsonResponse = {'Success': true,'complaintID':documentID};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};

//Resolve a individual complaint
final resolveComplaint=(shelf.Request req) async {
  String requestBody = await req.readAsString();
  var data = jsonDecode(requestBody);
  await updateDocument('complaints',data['complaintID'],{'resolved':true,'imagesResolved':data['imagesResolved']});
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};

final getLocation=(shelf.Request req) async {
  final locations=await findAllDocuments('locations');
  final location=locations.map((element)=>element.id).toList();
  var jsonResponse = {'Success': true,'locations':location};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};


//Resolve all complaints which are within the radius of a particular location
final resolveComplaintAll=(shelf.Request req) async {
  String requestBody = await req.readAsString();
  var data = jsonDecode(requestBody);
  final complaints=await findDocumentsTwo('complaints','place',data['location'],'resolved',false);
  final tasks2=complaints.map((element)=>updateDocument('complaints',element.id,{'resolved':true})).toList();
  print(await Future.wait(tasks2));
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};

//Retrieve all complaints from one user
final viewComplaintsByUser=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var complaints = await findDocuments('complaints', 'user', queryParams['user']);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

//Find all complaints which have been resolved
final viewComplaintsByUserResolved=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var complaints = await findDocumentsTwo('complaints', 'userid', queryParams['user'],'resolved',true);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

//Find all complaints which have not been resolved
final viewComplaintsByUserUnResolved=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var complaints = await findDocumentsTwo('complaints', 'userid', queryParams['user'],'resolved',false);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

//Find all complaints which have been resolved
final viewComplaintsForResolverResolved=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var resolver=await findDocument('users',queryParams['user']!);
  print(resolver);
  var location=resolver!.map['assignedLocation'];
  print(location);
  if(location==null){
    return shelf.Response.badRequest();
  }
  var complaints = await findDocumentsTwo('complaints', 'place',location,'resolved',true);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

//Find all complaints which have not been resolved
final viewComplaintsForResolverUnResolved=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var resolver=await findDocument('users',queryParams['user']!);
  var location=resolver!.map['assignedLocation'];
  if(location==null){
    return shelf.Response.badRequest();
  }
  var complaints = await findDocumentsTwo('complaints', 'place',location,'resolved',false);
  print(complaints);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

final getUserDetails=(shelf.Request req) async {
  var queryParams = req.url.queryParameters;
  var user=await findDocument('users',queryParams['user']!);
  if(user==null){
    return shelf.Response.badRequest();
  }
  return shelf.Response.ok(jsonEncode(user.map),
      headers: {'Content-Type': 'application/json'});
};


//Retrieve all complaints mapped to one location
final viewComplaintsByLocation=(shelf.Request request)async{
  var queryParams = request.url.queryParameters;
  var complaints = await findDocuments('complaints','location',queryParams['location']);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

//Retrieve all complaints mapped to one location, and resolved
final viewComplaintsByLocationUnresolved=(shelf.Request request)async{
  var queryParams = request.url.queryParameters;
  var complaints = await findDocumentsTwo('complaints','location',queryParams['location'],'resolved',true);
  return shelf.Response.ok(jsonEncode(complaints.map((element)=> {...element.map,'queryID':element.id}).toList()),
      headers: {'Content-Type': 'application/json'});
};

//Delete complaint from database
final deleteComplaint=(shelf.Request request)async{
  String requestBody = await request.readAsString();
  var data = jsonDecode(requestBody);
  delDocument('complaints',data['complaintID']);
  var jsonResponse = {'Success': true};
  return shelf.Response.ok(jsonEncode(jsonResponse),
      headers: {'Content-Type': 'application/json'});
};
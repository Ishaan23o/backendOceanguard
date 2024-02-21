import 'package:ioredis/ioredis.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:redis/redis.dart' as red;
import 'dart:convert';
import 'dart:io';
final Redis redis = new Redis(RedisOptions(host: 'redis-18738.c1.asia-northeast1-1.gce.cloud.redislabs.com', port: 18738,password:'CG79ISO3JW7peoi0Kf170AdZ2njP8NHV'));

final fetchClosestLocation=(Map<String,dynamic>data)async{
  //Set up redis connection
  final conn = red.RedisConnection();
  var response=await conn.connect('redis-18738.c1.asia-northeast1-1.gce.cloud.redislabs.com', 18738);
  await response
      .send_object(["AUTH", "default", 'CG79ISO3JW7peoi0Kf170AdZ2njP8NHV']);

  //Find closest 10 locations within 10 km.
  var results=await response.send_object([
    'GEOSEARCH',
    'locations',
    'FROMLONLAT',
    data['latitude'].toString(),
    data['longitude'].toString(),
    'BYRADIUS',
    '10',
    'km',
    'ASC',
    'COUNT',
    '10',
    'WITHCOORD',
    'WITHDIST'
  ]);
  if(results.isEmpty)return {'found':false};
  return {'found':true,'result':results[0]};
};

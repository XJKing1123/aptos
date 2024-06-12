import 'package:aptos/aptos_client.dart';
import 'package:aptos/http/http.dart';

extension RpcEvents on AptosClient{

  // Event types are globally identifiable by an account address and monotonically
  // increasing creation_number, one per event type emitted to the given account.
  // This API returns events corresponding to that that event type.
  Future<dynamic> getEventsByCreationNumber(String address, int creationNumber, {String? start, int? limit}) async {
    final params = <String, dynamic>{};
    if (start != null) params["start"] = start;
    if (limit != null) params["limit"] = limit;

    final path = "$endpoint/accounts/$address/events/$creationNumber";
    final resp = await http.get(path, queryParameters: params);
    return resp.data;
  }

  // This API uses the given account address, eventHandle, and fieldName to build a
  // key that can globally identify an event types. It then uses this key to return
  // events emitted to the given account matching that event type.
  Future<dynamic> getEventsByEventHandle(String address, String eventHandle, String fieldName, {String? start, int? limit}) async {
    final params = <String, dynamic>{};
    if (start != null) params["start"] = start;
    if (limit != null) params["limit"] = limit;

    final path = "$endpoint/accounts/$address/events/$eventHandle/$fieldName";
    final resp = await http.get(path, queryParameters: params);
    return resp.data;
  }

}
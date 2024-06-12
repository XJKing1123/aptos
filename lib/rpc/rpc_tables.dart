import 'package:aptos/aptos_client.dart';
import 'package:aptos/http/http.dart';
import 'package:aptos/models/table_item.dart';

extension RpcTables on AptosClient {
// Get a table item at a specific ledger version from the table identified by {table_handle}
// in the path and the "key" (TableItemRequest) provided in the request body.
//
// This is a POST endpoint because the "key" for requesting a specific table item (TableItemRequest)
// could be quite complex, as each of its fields could themselves be composed of other structs. This
// makes it impractical to express using query params, meaning GET isn't an option.
//
// The Aptos nodes prune account state history, via a configurable time window. If the requested ledger
// version has been pruned, the server responds with a 410.
  Future<dynamic> queryTableItem(
      String tableHandle, TableItem tableItem) async {
    final path = "$endpoint/tables/$tableHandle/item";
    final data = <String, dynamic>{};
    data["key_type"] = tableItem.keyType;
    data["value_type"] = tableItem.valueType;
    data["key"] = tableItem.key;
    final resp = await http.post(path, data: data);
    return resp.data;
  }

// Get a table item at a specific ledger version from the table identified by {table_handle} in
// the path and the "key" (RawTableItemRequest) provided in the request body.
//
// The get_raw_table_item requires only a serialized key comparing to the full move type information
// comparing to the get_table_item api, and can only return the query in the bcs format.
//
// The Aptos nodes prune account state history, via a configurable time window. If the requested ledger
// version has been pruned, the server responds with a 410.
  Future<dynamic> queryRawTableItem(String tableHandle, String key) async {
    final path = "$endpoint/tables/$tableHandle/raw_item";
    final data = <String, dynamic>{};
    data["key"] = key;
    final resp = await http.post(path, data: data);
    return resp.data;
  }
}

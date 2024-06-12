import 'package:aptos/aptos_client.dart';
import 'package:aptos/http/http.dart';

extension RpcGeneral on AptosClient{


  // Provides a UI that you can use to explore the API.
  // You can also retrieve the API directly at /spec.yaml
  // and /spec.json.
  Future<dynamic> showOpenAPIExplorer() async {
    final path = "$endpoint/spec";
    final resp = await http.get(path);
    return resp.data;
  }

  // By default this endpoint just checks that it can get the latest ledger
  // info and then returns 200.
  //
  // If the duration_secs param is provided, this endpoint will return a 200 if the
  // following condition is true:
  Future<String> checkBasicNodeHealth() async {
    final path = "$endpoint/-/healthy";
    final resp = await http.get(path);
    return resp.data["message"];
  }

  // Get the latest ledger information, including data such as chain ID, role type,
  // ledger versions, epoch, etc.
  Future<dynamic> getLedgerInfo() async {
    final path = "$endpoint";
    final resp = await http.get(path);
    return resp.data;
  }



}
import 'package:aptos/aptos_client.dart';
import 'package:aptos/http/http.dart';

extension RpcView on AptosClient {
  // Execute the Move function with the given parameters and return its execution result.
  //
  // The Aptos nodes prune account state history, via a configurable time window. If the
  // requested ledger version has been pruned, the server responds with a 410.
  Future<dynamic> view(
      String function, List<dynamic> typeArguments, List<dynamic> arguments,
      {int? ledgerVersion}) async {
    final data = <String, dynamic>{
      "function": function,
      "type_arguments": typeArguments,
      "arguments": arguments
    };
    final params =
    ledgerVersion != null ? {"ledger_version": ledgerVersion} : null;
    final path = "$endpoint/view";
    final resp = await http.post(path, data: data, queryParameters: params);
    return resp.data;
  }
}

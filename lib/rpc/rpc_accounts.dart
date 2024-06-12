import 'package:aptos/aptos_client.dart';
import 'package:aptos/http/http.dart';
import 'package:aptos/models/account_data.dart';

extension RpcAccounts on AptosClient {

  // Return the authentication key and the sequence number for an account address.
  // Optionally, a ledger version can be specified. If the ledger version is not specified
  // in the request, the latest ledger version is used.
  Future<AccountData> getAccount(String address) async {
    final path = "$endpoint/accounts/$address";
    final resp = await http.get(path);
    return AccountData.fromJson(resp.data);
  }

  // Retrieves all account resources for a given account and a specific ledger version.
  // If the ledger version is not specified in the request, the latest ledger version is used.
  //
  // The Aptos nodes prune account state history, via a configurable time window. If the requested
  // ledger version has been pruned, the server responds with a 410.
  Future<dynamic> getAccountResources(String address) async {
    final path = "$endpoint/accounts/$address/resources";
    final resp = await http.get(path);
    return resp.data;
  }

  // Retrieves all account modules' bytecode for a given account at a specific ledger version. '
  // 'If the ledger version is not specified in the request, the latest ledger version is used.
  //
  // The Aptos nodes prune account state history, via a configurable time window. If the requested
  // ledger version has been pruned, the server responds with a 410.
  Future<dynamic> getAccountModules(String address) async {
    final path = "$endpoint/accounts/$address/modules";
    final resp = await http.get(path);
    return resp.data;
  }

  // Retrieves an individual resource from a given account and at a specific ledger version.
  // If the ledger version is not specified in the request, the latest ledger version is used.
  //
  // The Aptos nodes prune account state history, via a configurable time window. If the requested
  // ledger version has been pruned, the server responds with a 410.

  Future<dynamic> getAccountResource(
      String address, String resourceType) async {
    final path = "$endpoint/accounts/$address/resource/$resourceType";
    final resp = await http.get(path);
    return resp.data;
  }

  // Retrieves an individual module from a given account and at a specific ledger version.
  // If the ledger version is not specified in the request, the latest ledger version is used.
  //
  // The Aptos nodes prune account state history, via a configurable time window. If the requested
  // ledger version has been pruned, the server responds with a 410.
  Future<dynamic> getAccountModule(String address, String moduleName) async {
    final path = "$endpoint/accounts/$address/module/$moduleName";
    try {
      final resp = await http.get(path);
      return resp.data;
    } catch (err) {
      return null;
    }
  }
}

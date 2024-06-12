import 'package:aptos/aptos_client.dart';
import 'package:aptos/http/http.dart';

extension RpcBlocks on AptosClient{

  Future<dynamic> getBlocksByHeight(int blockHeight, [bool withTransactioins = false]) async {
    final path = "$endpoint/blocks/by_height/$blockHeight?with_transactions=$withTransactioins";
    final resp = await http.get(path);
    return resp.data;
  }

  Future<dynamic> getBlocksByVersion(int version, [bool withTransactioins = false]) async {
    final path = "$endpoint/blocks/by_version/$version?with_transactions=$withTransactioins";
    final resp = await http.get(path);
    return resp.data;
  }

}
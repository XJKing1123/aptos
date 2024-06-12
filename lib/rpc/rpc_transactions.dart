import 'dart:typed_data';

import 'package:aptos/aptos_account.dart';
import 'package:aptos/aptos_client.dart';
import 'package:aptos/aptos_types/ed25519.dart';
import 'package:aptos/aptos_types/multi_ed25519.dart';
import 'package:aptos/aptos_types/transaction.dart';
import 'package:aptos/http/http.dart';
import 'package:aptos/models/transaction.dart';
import 'package:aptos/transaction_builder/builder.dart';
import 'package:dio/dio.dart';

extension RpcTrancsactions on AptosClient {
  Future<dynamic> getTransactions({String? start, int? limit}) async {
    final params = <String, dynamic>{};
    if (start != null) params["start"] = start;
    if (limit != null) params["limit"] = limit;

    final path = "$endpoint/transactions";
    final resp = await http.get(path, queryParameters: params);
    return resp.data;
  }

  Future<dynamic> submitTransaction(TransactionRequest transaction) async {
    final path = "$endpoint/transactions";
    final resp = await http.post(path, data: transaction);
    return resp.data;
  }

  Future<dynamic> getTransactionByHash(String txHash) async {
    final path = "$endpoint/transactions/by_hash/$txHash";
    final resp = await http.get(path);
    return resp.data;
  }

  Future<dynamic> getTransactionByVersion(String txVersion) async {
    final path = "$endpoint/transactions/by_version/$txVersion";
    final resp = await http.get(path);
    return resp.data;
  }

  Future<dynamic> getAccountTransactions(String address,
      {String? start, int? limit}) async {
    final params = <String, dynamic>{};
    if (start != null) params["start"] = start;
    if (limit != null) params["limit"] = limit;

    final path = "$endpoint/accounts/$address/transactions";
    final resp = await http.get(path, queryParameters: params);
    return resp.data;
  }

  Future<dynamic> submitBatchTransactions(
      List<TransactionRequest> transactions) async {
    final path = "$endpoint/transactions/batch";
    final resp = await http.post(path, data: transactions);
    return resp.data;
  }

  Future<dynamic> simulateTransaction(TransactionRequest transaction,
      {bool estimateGasUnitPrice = false,
      bool estimateMaxGasAmount = false,
      bool estimatePrioritizedGasUnitPrice = false}) async {
    final params = <String, bool>{
      "estimate_gas_unit_price": estimateGasUnitPrice,
      "estimate_max_gas_amount": estimateMaxGasAmount,
      "estimate_prioritized_gas_unit_price": estimatePrioritizedGasUnitPrice
    };
    final path = "$endpoint/transactions/simulate";
    final resp = await http.post(path,
        data: transaction.toJson(), queryParameters: params);
    return resp.data;
  }

  /// [accountOrPubkey] type is AptosAccount | Ed25519PublicKey | MultiEd25519PublicKey
  Future<dynamic> simulateRawTransaction(
      dynamic accountOrPubkey, RawTransaction rawTransaction,
      {bool estimateGasUnitPrice = false,
      bool estimateMaxGasAmount = false,
      bool estimatePrioritizedGasUnitPrice = false}) async {
    Uint8List signedTxn;
    if (accountOrPubkey is AptosAccount) {
      signedTxn = await AptosClient.generateBCSSimulation(
          accountOrPubkey, rawTransaction);
    } else if (accountOrPubkey is MultiEd25519PublicKey) {
      final txnBuilder = TransactionBuilderMultiEd25519(accountOrPubkey, (_) {
        final bits = <int>[];
        final signatures = <Ed25519Signature>[];
        for (int i = 0; i < accountOrPubkey.threshold; i += 1) {
          bits.add(i);
          signatures.add(Ed25519Signature(Uint8List(64)));
        }
        final bitmap = MultiEd25519Signature.createBitmap(bits);
        return MultiEd25519Signature(signatures, bitmap);
      });

      signedTxn = txnBuilder.sign(rawTransaction);
    } else if (accountOrPubkey is Ed25519PublicKey) {
      final txnBuilder = TransactionBuilderEd25519(accountOrPubkey.value, (_) {
        return Ed25519Signature(Uint8List(64));
      });

      signedTxn = txnBuilder.sign(rawTransaction);
    } else {
      throw ArgumentError("Invalid account value $accountOrPubkey");
    }

    return submitBCSSimulate(signedTxn,
        estimateGasUnitPrice: estimateGasUnitPrice,
        estimateMaxGasAmount: estimateMaxGasAmount,
        estimatePrioritizedGasUnitPrice: estimatePrioritizedGasUnitPrice);
  }

  Future<String> encodeSubmission(
      TransactionEncodeSubmissionRequest transaction) async {
    final path = "$endpoint/transactions/encode_submission";
    final resp = await http.post(path, data: transaction);
    return resp.data;
  }

  Future<dynamic> submitSignedBCSTransaction(Uint8List signedTxn) async {
    final path = "$endpoint/transactions";
    final file = MultipartFile.fromBytes(signedTxn).finalize();
    final options = Options(
      contentType: "application/x.aptos.signed_transaction+bcs",
      headers: {"content-length": signedTxn.length},
    );
    final resp = await http.post(path, data: file, options: options);
    return resp.data;
  }

  Future<dynamic> submitBCSSimulate(Uint8List signedTxn,
      {bool estimateGasUnitPrice = false,
      bool estimateMaxGasAmount = false,
      bool estimatePrioritizedGasUnitPrice = false}) async {
    final params = <String, bool>{
      "estimate_gas_unit_price": estimateGasUnitPrice,
      "estimate_max_gas_amount": estimateMaxGasAmount,
      "estimate_prioritized_gas_unit_price": estimatePrioritizedGasUnitPrice
    };
    final path = "$endpoint/transactions/simulate";
    final file = MultipartFile.fromBytes(signedTxn).finalize();
    final options = Options(
      contentType: "application/x.aptos.signed_transaction+bcs",
      headers: {"content-length": signedTxn.length},
    );
    final resp = await http.post(path,
        data: file, options: options, queryParameters: params);
    return resp.data;
  }

  Future<BigInt> estimateGasUnitPrice(TransactionRequest transaction) async {
    final txData =
        await simulateTransaction(transaction, estimateGasUnitPrice: true);
    final txInfo = txData[0];
    bool isSuccess = txInfo["success"];
    if (!isSuccess) throw Exception({txInfo["vm_status"]});
    final gasUnitPrice = txInfo["gas_unit_price"].toString();
    return BigInt.parse(gasUnitPrice);
  }

  Future<BigInt> estimateGasAmount(TransactionRequest transaction) async {
    final txData =
        await simulateTransaction(transaction, estimateMaxGasAmount: true);
    final txInfo = txData[0];
    bool isSuccess = txInfo["success"];
    if (!isSuccess) throw Exception({txInfo["vm_status"]});
    final gasUsed = txInfo["gas_used"].toString();
    return BigInt.parse(gasUsed);
  }

  Future<(BigInt, BigInt)> estimateGas(TransactionRequest transaction) async {
    final txData = await simulateTransaction(transaction,
        estimateGasUnitPrice: true, estimateMaxGasAmount: true);
    final txInfo = txData[0];
    final gasUnitPrice = txInfo["gas_unit_price"].toString();
    final gasUsed = txInfo["gas_used"].toString();
    return (BigInt.parse(gasUnitPrice), BigInt.parse(gasUsed));
  }

  Future<bool> transactionPending(String txnHash) async {
    final response = await getTransactionByHash(txnHash);
    return response["type"] == "pending_transaction";
  }

  Future<dynamic> waitForTransactionWithResult(String txnHash,
      {int? timeoutSecs, bool? checkSuccess}) async {
    timeoutSecs = timeoutSecs ?? 20;
    checkSuccess = checkSuccess ?? false;

    var isPending = true;
    var count = 0;
    dynamic lastTxn;
    while (isPending) {
      if (count >= timeoutSecs) {
        break;
      }
      try {
        lastTxn = await getTransactionByHash(txnHash);
        isPending = lastTxn["type"] == "pending_transaction";
        if (!isPending) {
          break;
        }
      } catch (e) {
        final isDioError = e is DioError;
        int statusCode = 0;
        if (isDioError) {
          statusCode = e.response?.statusCode ?? 0;
        }
        if (isDioError &&
            statusCode != 404 &&
            statusCode >= 400 &&
            statusCode < 500) {
          rethrow;
        }
      }
      await Future.delayed(const Duration(seconds: 1));
      count += 1;
    }

    if (lastTxn == null) {
      throw Exception("Waiting for transaction $txnHash failed");
    }

    if (isPending) {
      throw Exception(
          "Waiting for transaction $txnHash timed out after $timeoutSecs seconds");
    }
    if (!checkSuccess) {
      return lastTxn;
    }
    if (!(lastTxn["success"])) {
      throw Exception(
          "Transaction $txnHash committed to the blockchain but execution failed");
    }
    return lastTxn;
  }

  Future<void> waitForTransaction(
      String txnHash,
      { int? timeoutSecs, bool? checkSuccess }
      ) async {
    await waitForTransactionWithResult(
        txnHash,
        timeoutSecs: timeoutSecs,
        checkSuccess: checkSuccess);
  }
}

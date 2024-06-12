import 'dart:typed_data';

import 'package:aptos/aptos.dart';
import 'package:aptos/aptos_types/rotation_proof_challenge.dart';
import 'package:aptos/constants.dart';
import 'package:aptos/http/http.dart';
import 'package:aptos/models/entry_function_payload.dart';
import 'package:aptos/models/account_data.dart';
import 'package:aptos/models/table_item.dart';
import 'package:aptos/rpc/rpc_accounts.dart';
import 'package:aptos/rpc/rpc_general.dart';
import 'package:aptos/rpc/rpc_tables.dart';
import 'package:aptos/rpc/rpc_transactions.dart';

class AptosClient with AptosClientInterface {
  static const APTOS_COIN = "0x1::aptos_coin::AptosCoin";

  AptosClient(this.endpoint, {this.enableDebugLog = false}) {
    Constants.enableDebugLog = enableDebugLog;
  }

  final String endpoint;
  final bool enableDebugLog;

  /// AptosClientInterface ///

  @override
  Future<AccountData> getAccount(String address) async {
    final path = "$endpoint/accounts/$address";
    final resp = await http.get(path);
    return AccountData.fromJson(resp.data);
  }
  @override
  Future<dynamic> getAccountModules(String address) async {
    final path = "$endpoint/accounts/$address/modules";
    final resp = await http.get(path);
    return resp.data;
  }
  @override
  Future<int> getChainId() async {
    final ledgerInfo = await getLedgerInfo();
    final chainId = ledgerInfo["chain_id"];
    return chainId;
  }
  @override
  Future<int> estimateGasPrice() async {
    final path = "$endpoint/estimate_gas_price";
    final resp = await http.get(path);
    return resp.data["gas_estimate"];
  }

  Future<bool> accountExist(String address) async {
    try {
      await getAccount(address);
      return true;
    } catch (e) {
      dynamic err = e;
      if (err.response?.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }


  // Generates a signed transaction that can be submitted to the chain for execution.
  static Uint8List generateBCSTransaction(
      AptosAccount accountFrom, RawTransaction rawTxn) {
    final txnBuilder = TransactionBuilderEd25519(
        accountFrom.pubKey().toUint8Array(),
        (Uint8List signingMessage) => Ed25519Signature(
            accountFrom.signBuffer(signingMessage).toUint8Array()));

    return txnBuilder.sign(rawTxn);
  }

  static SignedTransaction generateBCSRawTransaction(
      AptosAccount accountFrom, RawTransaction rawTxn) {
    final txnBuilder = TransactionBuilderEd25519(
        accountFrom.pubKey().toUint8Array(),
        (Uint8List signingMessage) => Ed25519Signature(
            accountFrom.signBuffer(signingMessage).toUint8Array()));

    return txnBuilder.rawToSigned(rawTxn);
  }

  // Future<TransactionRequest> generateTransferTransaction(
  //   AptosAccount accountFrom,
  //   String receiverAddress,
  //   String amount,{
  //   String? coinType,
  //   BigInt? maxGasAmount,
  //   BigInt? gasUnitPrice,
  //   BigInt? expireTimestamp
  // }) async {
  //   const function = "0x1::coin::transfer";
  //   coinType ??= AptosClient.APTOS_COIN;

  //   final account = await getAccount(accountFrom.address);
  //   maxGasAmount ??= BigInt.from(20000);
  //   gasUnitPrice ??= BigInt.from(await estimateGasPrice());
  //   expireTimestamp ??= BigInt.from((DateTime.now().add(const Duration(seconds: 10)).microsecondsSinceEpoch));

  //   final token = TypeTagStruct(StructTag.fromString(coinType));
  //   final entryFunctionPayload = TransactionPayloadEntryFunction(
  //     EntryFunction.natural(
  //       function.split("::").take(2).join("::"),
  //       function.split("::").last,
  //       [token],
  //       [bcsToBytes(AccountAddress.fromHex(receiverAddress)), bcsSerializeUint64(BigInt.parse(amount))],
  //     ),
  //   );

  //   final rawTxn = await generateRawTransaction(
  //     accountFrom.accountAddress,
  //     entryFunctionPayload,
  //     maxGasAmount: maxGasAmount,
  //     gasUnitPrice: gasUnitPrice,
  //     expireTimestamp: expireTimestamp
  //   );

  //   final signedTxn = AptosClient.generateBCSRawTransaction(accountFrom, rawTxn);
  //   final txAuthEd25519 = signedTxn.authenticator as TransactionAuthenticatorEd25519;
  //   final signature = txAuthEd25519.signature.value;

  //   return TransactionRequest(
  //     sender: accountFrom.address,
  //     sequenceNumber: account.sequenceNumber,
  //     payload: Payload(
  //       "entry_function_payload",
  //       function,
  //       [coinType],
  //       [receiverAddress, amount]
  //     ),
  //     maxGasAmount: maxGasAmount.toString(),
  //     gasUnitPrice: gasUnitPrice.toString(),
  //     expirationTimestampSecs: expireTimestamp.toString(),
  //     signature: Signature(
  //       "ed25519_signature",
  //       accountFrom.pubKey().hex(),
  //       HexString.fromUint8Array(signature).hex()
  //     )
  //   );
  // }

// Note: Unless you have a specific reason for using this, it'll probably be simpler
// to use `simulateTransaction`.
// Generates a BCS transaction that can be submitted to the chain for simulation.
  static Future<Uint8List> generateBCSSimulation(
      AptosAccount accountFrom, RawTransaction rawTxn) async {
    final txnBuilder = TransactionBuilderEd25519(
        accountFrom.pubKey().toUint8Array(),
        (Uint8List _signingMessage) => Ed25519Signature(Uint8List(64)));

    return txnBuilder.sign(rawTxn);
  }

  Future<RawTransaction> generateRawTransaction(
      String accountFrom, TransactionPayload payload,
      {BigInt? maxGasAmount,
      BigInt? gasUnitPrice,
      BigInt? expireTimestamp}) async {
    final account = await getAccount(accountFrom);
    final chainId = await getChainId();

    maxGasAmount ??= BigInt.from(20000);
    gasUnitPrice ??= BigInt.from(await estimateGasPrice());
    expireTimestamp ??= BigInt.from(
        DateTime.now().add(const Duration(seconds: 20)).millisecondsSinceEpoch);

    return RawTransaction(
      AccountAddress.fromHex(accountFrom),
      BigInt.parse(account.sequenceNumber),
      payload,
      maxGasAmount,
      gasUnitPrice,
      expireTimestamp,
      ChainId(chainId),
    );
  }

  Future<String> generateSignSubmitTransaction(
      AptosAccount sender, TransactionPayload payload,
      {BigInt? maxGasAmount,
      BigInt? gasUnitPrice,
      BigInt? expireTimestamp}) async {
    final rawTransaction = await generateRawTransaction(sender.address, payload,
        maxGasAmount: maxGasAmount,
        gasUnitPrice: gasUnitPrice,
        expireTimestamp: expireTimestamp);
    final bcsTxn = AptosClient.generateBCSTransaction(sender, rawTransaction);
    final pendingTransaction = await submitSignedBCSTransaction(bcsTxn);
    return pendingTransaction["hash"];
  }

  Future<RawTransaction> generateTransaction(
      AptosAccount sender, EntryFunctionPayload payload,
      {String? sequenceNumber,
      String? gasUnitPrice,
      String? maxGasAmount,
      String? expirationTimestampSecs}) async {
    final builderConfig = ABIBuilderConfig(
        sender: sender.address,
        sequenceNumber:
            sequenceNumber != null ? BigInt.parse(sequenceNumber) : null,
        gasUnitPrice: gasUnitPrice != null ? BigInt.parse(gasUnitPrice) : null,
        maxGasAmount: maxGasAmount != null ? BigInt.parse(maxGasAmount) : null,
        expSecFromNow: expirationTimestampSecs != null
            ? BigInt.parse(expirationTimestampSecs)
            : null);
    final builder = TransactionBuilderRemoteABI(this, builderConfig);
    return await builder.build(
        payload.functionId, payload.typeArguments, payload.arguments);
  }

  /// Converts a transaction request produced by [generateTransaction] into a properly
  /// signed transaction, which can then be submitted to the blockchain.
  Uint8List signTransaction(
      AptosAccount accountFrom, RawTransaction rawTransaction) {
    return AptosClient.generateBCSTransaction(accountFrom, rawTransaction);
  }

  /// Rotate an account's auth key. After rotation, only the new private key can be used to sign txns for
  /// the account.
  /// WARNING: You must create a new instance of AptosAccount after using this function.
  Future<dynamic> rotateAuthKeyEd25519(
    AptosAccount forAccount,
    Uint8List toPrivateKeyBytes,
  ) async {
    final accountInfo = await getAccount(forAccount.address);
    final sequenceNumber = accountInfo.sequenceNumber;
    final authKey = accountInfo.authenticationKey;

    final helperAccount = AptosAccount(toPrivateKeyBytes);

    final challenge = RotationProofChallenge(
      AccountAddress.coreCodeAddress(),
      "account",
      "RotationProofChallenge",
      BigInt.parse(sequenceNumber),
      AccountAddress.fromHex(forAccount.address),
      AccountAddress(HexString(authKey).toUint8Array()),
      helperAccount.pubKey().toUint8Array(),
    );

    final challengeBytes = bcsToBytes(challenge);

    final proofSignedByCurrentPrivateKey =
        forAccount.signBuffer(challengeBytes);

    final proofSignedByNewPrivateKey = helperAccount.signBuffer(challengeBytes);

    final payload = TransactionPayloadEntryFunction(
      EntryFunction.natural(
        "0x1::account",
        "rotate_authentication_key",
        [],
        [
          bcsSerializeU8(0), // ed25519 scheme
          bcsSerializeBytes(forAccount.pubKey().toUint8Array()),
          bcsSerializeU8(0), // ed25519 scheme
          bcsSerializeBytes(helperAccount.pubKey().toUint8Array()),
          bcsSerializeBytes(proofSignedByCurrentPrivateKey.toUint8Array()),
          bcsSerializeBytes(proofSignedByNewPrivateKey.toUint8Array()),
        ],
      ),
    );

    final rawTransaction =
        await generateRawTransaction(forAccount.address, payload);
    final bcsTxn =
        AptosClient.generateBCSTransaction(forAccount, rawTransaction);
    return submitSignedBCSTransaction(bcsTxn);
  }

  Future<String> lookupOriginalAddress(String addressOrAuthKey) async {
    final resource =
        await getAccountResource("0x1", "0x1::account::OriginatingAddress");
    final handle = resource["data"]["address_map"]["handle"];
    final tableItem = TableItem(
        "address", "address", HexString.ensure(addressOrAuthKey).hex());
    final origAddress = await queryTableItem(handle, tableItem);
    return origAddress.toString();
  }

  /// View ///


}

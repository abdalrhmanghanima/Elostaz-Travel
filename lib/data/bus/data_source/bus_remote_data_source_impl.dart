import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/data/bus/data_source/bus_remote_data_source.dart';
import 'package:elostaz_travel/data/bus/model/bus_model.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusRemoteDataSourceImpl implements BusRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  BusRemoteDataSourceImpl({required this.firestore,required this.firebaseAuth});
  CollectionReference<Map<String, dynamic>> get _busesCollection {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    return firestore.collection('users').doc(user.uid).collection('buses');
  }

  @override
  Future<List<BusEntity>> getBuses() async {
    final snapshot = await _busesCollection.get();
    return snapshot.docs
        .map((document) => BusModel.fromFirestore(document))
        .toList();
  }

  @override
  Future<BusEntity> getBus({required String busId}) async {
    final document = await _busesCollection.doc(busId).get();
    if (!document.exists) {
      throw Exception('Bus not found');
    }

    return BusModel.fromFirestore(document);
  }

  @override
  Future<void> addBus({required BusEntity bus}) async {
    if (bus.id == null || bus.id!.isEmpty) {
      throw Exception('Bus ID is required');
    }

    await _busesCollection
        .doc(bus.id)
        .set(BusModel.fromEntity(bus).toFirestore());
  }

  @override
  Future<void> updateBus({
    required BusEntity bus,
  }) async {
    final docRef = _busesCollection.doc(bus.id);

    final isProhibited = bus.specialConditions == 'محظورة بيع' ||
        bus.specialConditions == 'محظورة البيع';
    final hasBankName = bus.prohibitedBankName != null &&
        bus.prohibitedBankName!.trim().isNotEmpty;

    final updateData = <String, dynamic>{
      'busName': bus.busName,
      'model': bus.model,
      if (bus.manufacturingYear != null)
        'manufacturingYear': bus.manufacturingYear,
      'modelYear': bus.manufacturingYear ?? bus.modelYear,
      'licenseExpiryDate': Timestamp.fromDate(bus.licenseExpiryDate),
      'licenseImageUrl': bus.licenseImageUrl,
      'busImageUrl': bus.busImageUrl,
      'specialConditions': bus.specialConditions,
      'prohibitedBankName': (isProhibited && hasBankName)
          ? bus.prohibitedBankName!.trim()
          : FieldValue.delete(),
    };

    await docRef.update(updateData);
  }

  @override
  Future<void> deleteBus({required String busId}) async {
    await _busesCollection.doc(busId).delete();
  }
}

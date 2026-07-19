import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class ShippingService {

  Future<List<ShippingMethod>> getAvailableMethods(Session session, {required String country, required double orderTotal}) async {
    final zones = await ShippingZone.db.find(session, where: (t) => t.isActive.equals(true));
    ShippingZone? matchedZone;
    for (final zone in zones) {
      if (zone.countries.split(',').map((c) => c.trim()).contains(country.toUpperCase())) {
        matchedZone = zone; break;
      }
    }
    if (matchedZone == null) return [];

    final methods = await ShippingMethod.db.find(session, where: (t) => t.zoneId.equals(matchedZone!.id!) & t.isActive.equals(true), orderBy: (t) => t.sortOrder);
    return methods;
  }

  double calculateFee(ShippingMethod method, double orderTotal) {
    if (method.freeAbove != null && orderTotal >= method.freeAbove!) return 0;
    return method.baseFee;
  }

  Future<Shipment> createShipment(Session session, {required int orderId, required int methodId, required double fee, DateTime? estimatedDelivery}) async {
    final now = DateTime.now().toUtc();
    return Shipment.db.insertRow(session, Shipment(
      orderId: orderId, methodId: methodId, status: ShippingStatus.pending,
      shippingFee: fee, estimatedDelivery: estimatedDelivery, createdAt: now, updatedAt: now,
    ));
  }

  Future<Shipment> updateStatus(Session session, {required int shipmentId, required ShippingStatus status, String? trackingNumber, String? courierName, String? courierUrl}) async {
    final s = await Shipment.db.findById(session, shipmentId);
    if (s == null) throw Exception('Shipment not found.');
    final now = DateTime.now().toUtc();
    return Shipment.db.updateRow(session, s.copyWith(
      status: status,
      trackingNumber: trackingNumber ?? s.trackingNumber,
      courierName: courierName ?? s.courierName,
      courierUrl: courierUrl ?? s.courierUrl,
      actualDelivery: status == ShippingStatus.delivered ? now : s.actualDelivery,
      updatedAt: now,
    ));
  }

  Future<Shipment?> getShipmentForOrder(Session session, int orderId) =>
      Shipment.db.findFirstRow(session, where: (t) => t.orderId.equals(orderId));
}

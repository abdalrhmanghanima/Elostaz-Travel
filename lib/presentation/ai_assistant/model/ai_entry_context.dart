import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';

enum AiEntryContextType {
  global,
  bus,
  factory,
}

class AiEntryContext {
  final AiEntryContextType type;
  final BusEntity? bus;
  final FactoryEntity? factory;

  const AiEntryContext({
    this.type = AiEntryContextType.global,
    this.bus,
    this.factory,
  });

  bool get isGlobal => type == AiEntryContextType.global;
  bool get isBusContext => type == AiEntryContextType.bus && bus != null;
  bool get isFactoryContext =>
      type == AiEntryContextType.factory && factory != null;

  const AiEntryContext.global()
      : type = AiEntryContextType.global,
        bus = null,
        factory = null;

  const AiEntryContext.bus(this.bus)
      : type = AiEntryContextType.bus,
        factory = null;

  const AiEntryContext.factory(this.factory)
      : type = AiEntryContextType.factory,
        bus = null;

  String get contextLabel {
    switch (type) {
      case AiEntryContextType.global:
        return '';
      case AiEntryContextType.bus:
        return 'الأتوبيس: ${bus?.busName ?? ''}';
      case AiEntryContextType.factory:
        return 'المصنع: ${factory?.name ?? ''}';
    }
  }
}

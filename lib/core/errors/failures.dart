import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class BleFailure extends Failure {
  const BleFailure(super.message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

class DeviceFailure extends Failure {
  const DeviceFailure(super.message);
}

class TestFailure extends Failure {
  const TestFailure(super.message);
}
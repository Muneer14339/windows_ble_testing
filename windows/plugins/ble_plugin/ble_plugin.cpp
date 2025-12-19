#include "ble_plugin.h"
#include <sstream>
#include <iomanip>
#include <thread>
#include <winrt/Windows.Foundation.Collections.h>

using namespace winrt::Windows::Devices::Bluetooth;
using namespace winrt::Windows::Devices::Bluetooth::Advertisement;
using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;
using namespace winrt::Windows::Storage::Streams;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Foundation::Collections;
std::string AddressToString(uint64_t addr) {
    std::ostringstream oss;
    oss << std::hex << std::setfill('0') << std::uppercase
        << std::setw(2) << ((addr >> 40) & 0xFF) << ":"
        << std::setw(2) << ((addr >> 32) & 0xFF) << ":"
        << std::setw(2) << ((addr >> 24) & 0xFF) << ":"
        << std::setw(2) << ((addr >> 16) & 0xFF) << ":"
        << std::setw(2) << ((addr >> 8) & 0xFF) << ":"
        << std::setw(2) << (addr & 0xFF);
    return oss.str();
}

uint64_t StringToAddress(const std::string& addr) {
    uint64_t result = 0;
    std::istringstream iss(addr);
    std::string byte;
    int shift = 40;
    while (std::getline(iss, byte, ':')) {
        result |= (static_cast<uint64_t>(std::stoul(byte, nullptr, 16)) << shift);
        shift -= 8;
    }
    return result;
}

int16_t ParseBE16(const uint8_t* p) {
    return static_cast<int16_t>((p[0] << 8) | p[1]);
}

void BlePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    auto plugin = std::make_unique<BlePlugin>(registrar);
    registrar->AddPlugin(std::move(plugin));
}

BlePlugin::BlePlugin(flutter::PluginRegistrarWindows* registrar) {
    channel_ = std::make_unique<flutter::MethodChannel<>>(
            registrar->messenger(), "native_ble_plugin",
            &flutter::StandardMethodCodec::GetInstance());

    channel_->SetMethodCallHandler([this](const auto& call, auto result) {
        HandleMethodCall(call, result);
    });
}

BlePlugin::~BlePlugin() {
    StopScanning();
    std::lock_guard<std::mutex> lock(devices_mutex_);
    for (auto& [addr, conn] : devices_) {
        try {
            if (conn.device) {
                conn.device.Close();
            }
        } catch (...) {}
    }
}
void BlePlugin::HandleMethodCall(const flutter::MethodCall<>& method_call,
                                 std::unique_ptr<flutter::MethodResult<>>& result) {
    const auto& method = method_call.method_name();

    if (method == "startScanning") {
        StartScanning();
        result->Success();
    } else if (method == "stopScanning") {
        StopScanning();
        result->Success();
    } else if (method == "connectDevice") {
        auto args = std::get<flutter::EncodableMap>(*method_call.arguments());
        auto address = std::get<std::string>(args[flutter::EncodableValue("address")]);
        ConnectDevice(address, result);
    } else if (method == "startSensors") {
        auto args = std::get<flutter::EncodableMap>(*method_call.arguments());
        auto address = std::get<std::string>(args[flutter::EncodableValue("address")]);
        StartSensors(address, result);
    } else if (method == "stopSensors") {
        auto args = std::get<flutter::EncodableMap>(*method_call.arguments());
        auto address = std::get<std::string>(args[flutter::EncodableValue("address")]);
        StopSensors(address);
        result->Success();
    } else if (method == "disconnectDevice") {
        auto args = std::get<flutter::EncodableMap>(*method_call.arguments());
        auto address = std::get<std::string>(args[flutter::EncodableValue("address")]);
        DisconnectDevice(address);
        result->Success();
    } else if (method == "pollDevices") {
        result->Success(PollDevices());
    } else if (method == "pollSamples") {
        auto args = std::get<flutter::EncodableMap>(*method_call.arguments());
        auto address = std::get<std::string>(args[flutter::EncodableValue("address")]);
        result->Success(PollSamples(address));
    } else {
        result->NotImplemented();
    }
}

void BlePlugin::StartScanning() {
    watcher_ = BluetoothLEAdvertisementWatcher();
    watcher_.ScanningMode(BluetoothLEScanningMode::Active);

    watcher_.Received([this](BluetoothLEAdvertisementWatcher const&,
                             BluetoothLEAdvertisementReceivedEventArgs args) {
        try {
            uint64_t addr = args.BluetoothAddress();
            auto async_device = BluetoothLEDevice::FromBluetoothAddressAsync(addr);
            auto device = async_device.get();

            if (device) {
                std::string name = winrt::to_string(device.Name());
                if (!name.empty() && name.find("GMSync") != std::string::npos) {
                    SendDeviceFound(name, AddressToString(addr), -100);
                }
                device.Close();
            }
        } catch (const winrt::hresult_error&) {
            // Ignore device access errors during scan
        } catch (...) {
            // Ignore all other errors
        }
    });

    watcher_.Start();
}

void BlePlugin::StopScanning() {
    if (watcher_) {
        watcher_.Stop();
        watcher_ = nullptr;
    }
}

void BlePlugin::ConnectDevice(const std::string& address, std::unique_ptr<flutter::MethodResult<>>& result) {
    auto result_ptr = result.release();

    std::thread([this, address, result_ptr]() {
        try {
            uint64_t addr = StringToAddress(address);
            auto device = BluetoothLEDevice::FromBluetoothAddressAsync(addr).get();

            if (!device) {
                result_ptr->Error("CONNECT_FAILED", "Failed to get device");
                delete result_ptr;
                return;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(500));

            winrt::guid service_uuid(0x0000b3a0, 0x0000, 0x1000, {0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb});
            auto services_result = device.GetGattServicesForUuidAsync(service_uuid).get();

            Collections::IVectorView<GattDeviceService> services = services_result.Services();
            if (services_result.Status() != GattCommunicationStatus::Success || services.Size() == 0) {
                result_ptr->Error("SERVICE_NOT_FOUND", "Service not found");
                delete result_ptr;
                return;
            }

            GattDeviceService service = services.GetAt(0);
            std::this_thread::sleep_for(std::chrono::milliseconds(500));

            winrt::guid notify_uuid(0x0000b3a1, 0x0000, 0x1000, {0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb});
            auto notify_result = service.GetCharacteristicsForUuidAsync(notify_uuid).get();

            winrt::guid write_uuid(0x0000b3a2, 0x0000, 0x1000, {0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb});
            auto write_result = service.GetCharacteristicsForUuidAsync(write_uuid).get();

            if (notify_result.Status() != GattCommunicationStatus::Success ||
                write_result.Status() != GattCommunicationStatus::Success) {
                result_ptr->Error("CHAR_NOT_FOUND", "Characteristics not found");
                delete result_ptr;
                return;
            }

            DeviceConnection conn;
            conn.device = device;
            conn.notify_char = notify_result.Characteristics().GetAt(0);
            conn.write_char = write_result.Characteristics().GetAt(0);

            {
                std::lock_guard<std::mutex> lock(devices_mutex_);
                devices_[address] = std::move(conn);
            }

            result_ptr->Success();
            delete result_ptr;
        } catch (const winrt::hresult_error& e) {
            result_ptr->Error("EXCEPTION", winrt::to_string(e.message()));
            delete result_ptr;
        }
    }).detach();
}

void BlePlugin::StartSensors(const std::string& address, std::unique_ptr<flutter::MethodResult<>>& result) {
    auto result_ptr = result.release();

    std::thread([this, address, result_ptr]() {
        try {
            GattCharacteristic notify_char{nullptr};
            GattCharacteristic write_char{nullptr};
            {
                std::lock_guard<std::mutex> lock(devices_mutex_);
                auto it = devices_.find(address);
                if (it == devices_.end()) {
                    result_ptr->Error("NOT_CONNECTED", "Device not connected");
                    delete result_ptr;
                    return;
                }
                notify_char = it->second.notify_char;
                write_char = it->second.write_char;
            }

            auto token = notify_char.ValueChanged([this, address](
                    GattCharacteristic const&, GattValueChangedEventArgs args) {
                try {
                    auto reader = DataReader::FromBuffer(args.CharacteristicValue());
                    uint32_t length = reader.UnconsumedBufferLength();
                    if (length == 0) return;

                    std::vector<uint8_t> data(length);
                    reader.ReadBytes(data);

                    if (data.size() < 10 || data[0] != 0x55 || data[1] != 0xAA || data[3] != 0x06) return;

                    uint8_t cmd = data[2];
                    int16_t rx = ParseBE16(&data[4]);
                    int16_t ry = ParseBE16(&data[6]);
                    int16_t rz = ParseBE16(&data[8]);

                    double timestamp = std::chrono::duration<double>(
                            std::chrono::steady_clock::now().time_since_epoch()).count();

                    std::map<std::string, double> sample;
                    sample["timestampS"] = timestamp;
                    sample["temp"] = 0.0;

                    if (cmd == 0x08) {
                        sample["ax"] = 16.0 * rx / 32768.0;
                        sample["ay"] = 16.0 * ry / 32768.0;
                        sample["az"] = 16.0 * rz / 32768.0;
                        sample["gx"] = 0.0;
                        sample["gy"] = 0.0;
                        sample["gz"] = 0.0;
                    } else if (cmd == 0x0A) {
                        sample["ax"] = 0.0;
                        sample["ay"] = 0.0;
                        sample["az"] = 0.0;
                        sample["gx"] = 500.0 * rx / 28571.0;
                        sample["gy"] = 500.0 * ry / 28571.0;
                        sample["gz"] = 500.0 * rz / 28571.0;
                    }
// Debug: Check if data is being collected
                    static std::map<std::string, int> counters;
                    counters[address]++;
                    this->SendDataSample(address, sample);
                } catch (...) {}
            });

            notify_char.WriteClientCharacteristicConfigurationDescriptorAsync(
                    GattClientCharacteristicConfigurationDescriptorValue::Notify).get();

            std::this_thread::sleep_for(std::chrono::milliseconds(300));

            auto write_cmd = [&](uint8_t cmd, uint8_t len, std::vector<uint8_t> payload) {
                std::vector<uint8_t> buf = {0x55, 0xAA, cmd, len};
                buf.insert(buf.end(), payload.begin(), payload.end());
                auto writer = DataWriter();
                writer.WriteBytes(buf);
                auto buffer = writer.DetachBuffer();
                write_char.WriteValueAsync(buffer).get();
            };

            write_cmd(0xF0, 0x00, {});
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
            write_cmd(0x11, 0x02, {0x00, 0x02});
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
            write_cmd(0x0A, 0x00, {});
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
            write_cmd(0x08, 0x00, {});
            std::this_thread::sleep_for(std::chrono::milliseconds(200));
            write_cmd(0x06, 0x00, {});

            {
                std::lock_guard<std::mutex> lock(devices_mutex_);
                auto it = devices_.find(address);
                if (it != devices_.end()) {
                    it->second.value_changed_token = token;
                }
            }

            result_ptr->Success();
            delete result_ptr;
        } catch (const winrt::hresult_error& e) {
            result_ptr->Error("START_FAILED", winrt::to_string(e.message()));
            delete result_ptr;
        }
    }).detach();
}

void BlePlugin::StopSensors(const std::string& address) {
    std::thread([this, address]() {
        std::lock_guard<std::mutex> lock(devices_mutex_);
        auto it = devices_.find(address);
        if (it != devices_.end()) {
            auto& conn = it->second;
            try {
                if (conn.notify_char) {
                    conn.notify_char.ValueChanged(conn.value_changed_token);
                }
                if (conn.write_char) {
                    std::vector<uint8_t> buf = {0x55, 0xAA, 0xF0, 0x00};
                    auto writer = DataWriter();
                    writer.WriteBytes(buf);
                    auto buffer = writer.DetachBuffer();
                    conn.write_char.WriteValueAsync(buffer).get();
                }
            } catch (...) {}
        }
    }).detach();
}

void BlePlugin::DisconnectDevice(const std::string& address) {
    std::thread([this, address]() {
        std::lock_guard<std::mutex> lock(devices_mutex_);
        auto it = devices_.find(address);
        if (it != devices_.end()) {
            try {
                if (it->second.device) {
                    it->second.device.Close();
                }
            } catch (...) {}
            devices_.erase(it);
        }
    }).detach();
}

void BlePlugin::SendDeviceFound(const std::string& name, const std::string& address, int rssi) {
    flutter::EncodableMap device;
    device[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
    device[flutter::EncodableValue("address")] = flutter::EncodableValue(address);
    device[flutter::EncodableValue("rssi")] = flutter::EncodableValue(rssi);

    std::lock_guard<std::mutex> lock(scan_mutex_);
    pending_devices_.push_back(device);
}

void BlePlugin::SendDataSample(const std::string& address, const std::map<std::string, double>& sample) {
    flutter::EncodableMap sample_map;
    for (const auto& [key, value] : sample) {
        sample_map[flutter::EncodableValue(key)] = flutter::EncodableValue(value);
    }

    std::lock_guard<std::mutex> lock(samples_mutex_);
    pending_samples_[address].push_back(sample_map);
}

flutter::EncodableValue BlePlugin::PollDevices() {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    flutter::EncodableList result;
    for (const auto& device : pending_devices_) {
        result.push_back(flutter::EncodableValue(device));
    }
    pending_devices_.clear();
    return flutter::EncodableValue(result);
}

flutter::EncodableValue BlePlugin::PollSamples(const std::string& address) {
    std::lock_guard<std::mutex> lock(samples_mutex_);
    auto it = pending_samples_.find(address);
    if (it == pending_samples_.end()) {
        return flutter::EncodableValue(flutter::EncodableList());
    }
    flutter::EncodableList result;
    for (const auto& sample : it->second) {
        result.push_back(flutter::EncodableValue(sample));
    }
    it->second.clear();
    return flutter::EncodableValue(result);
}
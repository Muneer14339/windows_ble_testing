#pragma once
#include <winrt/Windows.Foundation.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include <winrt/Windows.Storage.Streams.h>
#include <memory>
#include <map>
#include <mutex>

class BlePlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
    BlePlugin(flutter::PluginRegistrarWindows* registrar);
    ~BlePlugin();
    flutter::EncodableValue PollDevices();
    flutter::EncodableValue PollSamples(const std::string& address);
private:
    void HandleMethodCall(const flutter::MethodCall<>& method_call,
                          std::unique_ptr<flutter::MethodResult<>>& result);

    void StartScanning();
    void StopScanning();
    void ConnectDevice(const std::string& address, std::unique_ptr<flutter::MethodResult<>>& result);
    void StartSensors(const std::string& address, std::unique_ptr<flutter::MethodResult<>>& result);
    void StopSensors(const std::string& address);
    void DisconnectDevice(const std::string& address);

    void SendDeviceFound(const std::string& name, const std::string& address, int rssi);
    void SendDataSample(const std::string& address, const std::map<std::string, double>& sample);

    std::unique_ptr<flutter::MethodChannel<>> channel_;

    struct DeviceConnection {
        winrt::Windows::Devices::Bluetooth::BluetoothLEDevice device{nullptr};
        winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::GattCharacteristic notify_char{nullptr};
        winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::GattCharacteristic write_char{nullptr};
        winrt::event_token value_changed_token;
    };

    std::map<std::string, DeviceConnection> devices_;
    std::mutex devices_mutex_;
    std::mutex scan_mutex_;
    std::vector<flutter::EncodableMap> pending_devices_;

    std::mutex samples_mutex_;
    std::map<std::string, std::vector<flutter::EncodableMap>> pending_samples_;
    winrt::Windows::Devices::Bluetooth::Advertisement::BluetoothLEAdvertisementWatcher watcher_{nullptr};
};
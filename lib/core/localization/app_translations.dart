class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'zh': {
      // App Title
      'appTitle': 'RA QA 测试仪',
      'headerSubtitle': '准备开始测试',
      'headerSubtitleScanning': '扫描设备中',
      'headerSubtitleConnecting': '建立连接',
      'headerSubtitleCalibrating': '传感器校准',
      'headerSubtitleCollecting': '运行测试序列',
      'headerSubtitleComplete': '测试完成',
      
      // Buttons
      'langSwitch': 'English',
      'stopBtn': '停止',
      'startBtn': '开始测试',
      'testNextBtn': '测试下一个设备',
      'retryBtn': '重试',
      'discardBtn': '丢弃设备',
      'confirmBtn': '确认',
      'cancelBtn': '取消',
      'testAgainBtn': '再次测试',
      
      // Initial Screen
      'rulesTitle': '测试规则',
      'rule1': '第一次测试通过 → 设备良好，继续下一个测试',
      'rule2': '第一次测试失败 → 重新测试（第二次尝试）',
      'rule2Sub1': '第二次通过 → 设备良好，测试下一个',
      'rule2Sub2': '第二次失败 → 重新测试（第三次尝试）',
      'rule3': '第三次测试：',
      'rule3Sub1': '通过 → 设备良好，测试下一个',
      'rule3Sub2': '失败 → 标记为坏传感器并丢弃',
      'rulesNote': '每个设备最多可尝试 3 次',
      
      // Scanning Screen
      'scanningTitle': '扫描设备',
      'scanningSubtitle': '正在搜索 RA 设备...',
      'foundDevices': '已找到设备',
      
      // Connecting Screen
      'connectingTitle': '连接设备',
      'connectingSubtitle': '正在建立 BLE 连接...',
      'verifying': '验证数据流...',
      
      // Calibration Screen
      'calibrationTitle': '传感器校准',
      'calibrationSubtitle': '稳定传感器中...',
      'calibratingMsg': '请保持设备静止',
      
      // Data Collection Screen
      'dataCollectionTitle': '数据采集',
      'dataCollectionSubtitle': '收集传感器数据中...',
      'progress': '进度',
      'samples': '样本',
      
      // Results - Pass
      'testPassTitle': '测试通过',
      'testedDevicesPass': '已测试 1 个设备',
      'attemptInfo': '第 1 次尝试通过',
      'passStatus': '通过',

      'passedDevicesTitle': '✓ 已通过设备',
      'failedDevicesTitle': '✗ 已失败设备',
      
      // Results - Fail
      'testFailTitle': '测试失败',
      'testedDevicesFail': '已测试 1 个设备 - 尝试',
      'attemptInfoFail': '第 1 次尝试失败',
      'failStatus': '失败',
      
      // Results - Bad Sensor
      'badSensorTitle': '坏传感器',
      'failedAttempts': '3 次尝试均失败',
      'attemptInfoBad': '3 次尝试均失败 - 坏传感器',
      'badStatus': '坏',
      'badListTitle': '⚠️ 坏传感器列表',
      
      // Stop Modal
      'modalTitle': '确认停止？',
      'modalText': '您确定要停止吗？当前进度将丢失。',
      
      // Status Messages
      'initializing': '初始化 BLE...',
      'readyToStart': '准备开始',
      'scanningForDevices': '扫描 RA 设备中...',
      'connecting': '连接设备中...',
      'settling': '稳定 {} 秒...',
      'collecting': '收集样本中...',
      'evaluating': '评估结果中...',
      'completed': '测试完成',
      'error': '发生错误',
      
      // Device Info
      'deviceConnected': '设备已连接',
      'devicesConnected': '{} 个设备已连接',
      
      // Common
      'of': '/',
      'attempt': '尝试',
      'device': '设备',
      'mac': 'MAC 地址',

      'dataStreamError': '无数据流 - 正在断开连接',
      'deviceDisconnected': '设备已断开连接',
    },
    'en': {
      // App Title
      'appTitle': 'RA QA Tester',
      'headerSubtitle': 'Ready to start testing',
      'headerSubtitleScanning': 'Scanning for devices',
      'headerSubtitleConnecting': 'Establishing connections',
      'headerSubtitleCalibrating': 'Calibrating sensors',
      'headerSubtitleCollecting': 'Running test sequence',
      'headerSubtitleComplete': 'Test complete',
      
      // Buttons
      'langSwitch': '中文',
      'stopBtn': 'STOP',
      'startBtn': 'START TEST',
      'testNextBtn': 'Test Next Device',
      'retryBtn': 'Retry',
      'discardBtn': 'Discard Device',
      'confirmBtn': 'Confirm',
      'cancelBtn': 'Cancel',
      'testAgainBtn': 'Test Again',
      
      // Initial Screen
      'rulesTitle': 'Test rules',
      'rule1': 'First test passed → Equipment is good, proceed to the next test.',
      'rule2': 'First test failed → Retest (second attempt)',
      'rule2Sub1': 'Passed the second time → Equipment is good, test the next one.',
      'rule2Sub2': 'Second failure → Retest (third attempt)',
      'rule3': 'Third test:',
      'rule3Sub1': 'Pass → Equipment is good, test the next one.',
      'rule3Sub2': 'Failure → Mark as bad sensor and set aside',
      'rulesNote': 'Each device can attempt a maximum of 3 times.',
      
      // Scanning Screen
      'scanningTitle': 'Scanning for Devices',
      'scanningSubtitle': 'Searching for RA devices...',
      'foundDevices': 'Found Devices',
      
      // Connecting Screen
      'connectingTitle': 'Connecting to Device',
      'connectingSubtitle': 'Establishing BLE connection...',
      'verifying': 'Verifying data stream...',
      
      // Calibration Screen
      'calibrationTitle': 'Sensor Calibration',
      'calibrationSubtitle': 'Stabilizing sensors...',
      'calibratingMsg': 'Please keep device still',
      
      // Data Collection Screen
      'dataCollectionTitle': 'Data Collection',
      'dataCollectionSubtitle': 'Collecting sensor data...',
      'progress': 'Progress',
      'samples': 'Samples',
      
      // Results - Pass
      'testPassTitle': 'Test Passed',
      'testedDevicesPass': 'Tested 1 device',
      'attemptInfo': 'Passed on attempt 1',
      'passStatus': 'PASS',

      'passedDevicesTitle': '✓ Passed Devices',
      'failedDevicesTitle': '✗ Failed Devices',
      
      // Results - Fail
      'testFailTitle': 'Test Failed',
      'testedDevicesFail': 'Tested 1 device - Attempt',
      'attemptInfoFail': 'Failed on attempt 1',
      'failStatus': 'FAIL',
      
      // Results - Bad Sensor
      'badSensorTitle': 'Bad Sensor',
      'failedAttempts': 'Failed all 3 attempts',
      'attemptInfoBad': 'Failed 3 attempts - Bad sensor',
      'badStatus': 'BAD',
      'badListTitle': '⚠️ Bad Sensors List',
      
      // Stop Modal
      'modalTitle': 'Confirm Stop?',
      'modalText': 'Are you sure you want to stop? Current progress will be lost.',
      
      // Status Messages
      'initializing': 'Initializing BLE...',
      'readyToStart': 'Ready to start',
      'scanningForDevices': 'Scanning for RA devices...',
      'connecting': 'Connecting to devices...',
      'settling': 'Settling for {} seconds...',
      'collecting': 'Collecting samples...',
      'evaluating': 'Evaluating results...',
      'completed': 'Test completed',
      'error': 'Error occurred',
      
      // Device Info
      'deviceConnected': 'Device Connected',
      'devicesConnected': '{} Devices Connected',
      
      // Common
      'of': '/',
      'attempt': 'Attempt',
      'device': 'Device',
      'mac': 'MAC Address',

      'dataStreamError': 'No data stream - disconnecting',
      'deviceDisconnected': 'Device disconnected',
    },
  };

  static String translate(String key, String locale, {List<String>? args}) {
    String text = translations[locale]?[key] ?? translations['en']?[key] ?? key;
    
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceFirst('{}', args[i]);
      }
    }
    
    return text;
  }
}

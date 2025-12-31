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
      'rule1': '将传感器放在平面上',
      'rule2': '确保传感器在测试期间保持静止',
      'rule3': '每个设备有 3 次测试机会',
      'rule4': '测试将自动运行 60 秒',
      
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
      'rulesTitle': 'Testing Rules',
      'rule1': 'Place sensor on flat surface',
      'rule2': 'Keep sensor stationary during test',
      'rule3': 'Each device has 3 test attempts',
      'rule4': 'Test will run automatically for 60 seconds',
      
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

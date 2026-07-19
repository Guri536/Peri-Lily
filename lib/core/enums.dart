enum ProtocolActions {
  shareLoc('Share Location'),
  shareMes("Share Message"),
  startVid("Start Video Recording"),
  startVoice("Start Voice Recording"),
  startAlert("Start an Alert"),
  openScreen("Open a Decoy Screen"),
  ;

  final String identifier;

  const ProtocolActions(this.identifier);
}

enum Gestures {
  upperDouble('upper_double', 'Upper Region — Double Tap'),
  upperLong('upper_long', 'Upper Region — Long Press'),
  middleDouble('middle_double', 'Middle Region — Double Tap'),
  lowerDouble('lower_double', 'Lower Region — Double Tap'),
  lowerLong('lower_long', 'Lower Region — Long Press');

  final String dbValue;
  final String displayName;
  const Gestures(this.dbValue, this.displayName);
}

enum DecoyType {
  fakeCall('fake_call', 'Fake Incoming Call'),
  socialFeed('social_feed', 'Social Media Feed'),
  notesDash('dashboard', 'Notes App');

  final String dbValue;
  final String displayName;
  const DecoyType(this.dbValue, this.displayName);
}

enum SettingKeys {
  activeDecoyType('active_decoy_type', ""),
  volumeTriggerProtocolId('volume_trigger_protocol_id', "")

  ;
  final String dbValue;
  final String displayName;
  const SettingKeys(this.dbValue, this.displayName);
}
